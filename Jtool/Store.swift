import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage

@MainActor
class Store: ObservableObject {
    @Published var users: [Profile] = []
    @Published var profile: Profile = .init()
    @Published var stages: [Stage] = []

    @Published var errorMessage: String? {
        didSet {
            hasError = true
        }
    }
    @Published var hasError: Bool = false

    // TODO: think about that two
//    @Published var availableTeams: [String] = []
//    @Published var availableJobs: [String] = []

    var userId: Int? {
        users.firstIndex {
            $0.id == profile.id
        }
    }

    var currentTasks: [Task] {
        guard let currentStage = currentStage else {
            return []
        }
        return stages[currentStage].tasks
    }

    private var currentStage: Int?

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    func load(for userEmail: String) async {
        do {
            let userDocs = try await db.collection("users").getDocuments().documents
            let users = try userDocs.map { try $0.data(as: Profile.self) }

            let stageDocs = try await db.collection("stages").getDocuments().documents
            let stages = try stageDocs.map { try $0.data(as: Stage.self) }

            self.users = users
            self.stages = stages
        } catch (let error) {
            errorMessage = error.localizedDescription
            return
        }

        guard let profile = users.first(where: { $0.email == userEmail }) else {
            errorMessage = "User not found"
            return
        }
        self.profile = profile

        await loadTasks()
    }

    private func loadTasks() async {
        guard let currentStage = stages.firstIndex(where: {!$0.isFinished })
        else { return }
        self.currentStage = currentStage
        let stageDoc = db.collection("stages").document(stages[currentStage].id!)
        do {
            let taskDocs = try await stageDoc.collection("tasks").getDocuments().documents
            stages[currentStage].tasks.removeAll(keepingCapacity: true)
            for task in taskDocs {
                stages[currentStage].tasks.append(
                    try await decodeTask(from: task, stage: stageDoc)
                )
            }
        } catch (let error) {
            errorMessage = error.localizedDescription
            return
        }
    }

    private func decodeTask(
        from query: QueryDocumentSnapshot,
        stage: DocumentReference
    ) async throws -> Task {
        var task = try query.data(as: Task.self)
        let commentsCollection = stage.collection("tasks/\(task.id!)/comments")
        let commentSnapshot = try await commentsCollection.getDocuments()
        if !commentSnapshot.isEmpty {
            task.comments = try commentSnapshot.documents.map { try $0.data(as: Comment.self) }
        }
        return task
    }

    func saveProfile() async {
//        guard let profile = profile else {
//            errorMessage = "Profile id not loaded, try again later..."
//            return
//        }
        do {
            try db.collection("users").document(profile.id).setData(from: profile)
        } catch (let error) {
            errorMessage = error.localizedDescription
            return
        }
    }

    func change(status: String, for taskId: String) async {
        guard let currentStage = currentStage else {
            errorMessage = "No current stage is given" // TODO: ??
            return
        }
        
        let taskCollection = db.collection("stages/\(stages[currentStage].id!)/tasks")
        do {
            try await taskCollection.document(taskId).updateData(["status": status])
        } catch (let error) {
            errorMessage = error.localizedDescription
            return
        }
    }

    func add(comment: String, for taskId: String) async -> String? {
        guard let currentStage = currentStage else {
            errorMessage = "No current stage is given" // TODO: ??
            return nil
        }

        let taskCollection = db.collection("stages/\(stages[currentStage].id!)/tasks")
        let commentsCollection = taskCollection.document(taskId).collection("comments")
        let currentUser = db.collection("users").document(profile.id)

        let commentRef: DocumentReference
        do {
            commentRef = try commentsCollection.addDocument(
                from: Comment(author: currentUser, content: comment, timestamp: Date())
            )
        } catch (let error) {
            errorMessage = error.localizedDescription
            return nil
        }

        await loadTasks()

        return commentRef.documentID
    }
}

//extension Profile {
//    static let sample: [Profile] = [
//        .init(name: "Morris", surname: "The Important One", team: "Team mobile", job: "Tester"),
//        .init(name: "Smith", surname: "Smith", team: "Team backend", job: "Leader"),
//        .init(name: "Michle", surname: "Michele", team: "Team backend", job: "Primary Developer"),
//        .init(name: "Gendalf", surname: "The Mage", team: "Team mobile", job: "Leader")
//    ]
//}
