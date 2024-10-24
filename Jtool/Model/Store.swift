import Foundation
import SwiftUI
import Combine
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage

@MainActor
class Store: ObservableObject {
    @Published var profile: Profile?
    @Published var stage: Stage?
    @Published var stages: [Stage] = []
    @Published var users: [Profile] = []

    @Published var hasError: Bool = false
    @Published var errorMessage: String?

    @Published var allJobs: [String] = []
    @Published var availableJobs: [String] = []

    private static let unselected = String(localized: "Unselected")

    func setup(for userEmail: String) {
        $users.map { users in
            users.first { $0.email == userEmail }
        }.assign(to: &$profile)

        $stages.map { stages in
            stages.first { !$0.isFinished }
        }.assign(to: &$stage)

        $errorMessage.map { $0 != nil }.assign(to: &$hasError)
    }

    let db = Firestore.firestore()
    let storage = Storage.storage()

    func loadAll() async {
        await loadUsers()
        await loadJobs()
        await loadStages()
    }

    func loadJobs() async {
        self.availableJobs.removeAll(keepingCapacity: true)
        do {
            let jobDocs = try await db.jobs.getDocuments().documents
            self.availableJobs = try jobDocs.map { try $0.data(as: Job.self) }.map(\.title)
            self.allJobs = try await db.allJobs.getDocuments().documents.map {try $0.data(as: Job.self)}.map(\.title)
        } catch let error {
            errorMessage = error.localizedDescription
            return
        }
        guard let profile else { return }
        if profile.job != Self.unselected {
            self.availableJobs.append(profile.job)
        }
        self.availableJobs.append(Self.unselected)
    }

    func loadUsers() async {
        let dbUsers: [DBProfile]
        do {
            let userDocs = try await db.users.getDocuments().documents
            dbUsers = try userDocs.compactMap { try $0.data(as: DBProfile.self) }
        } catch (let error) {
            errorMessage = error.localizedDescription
            return
        }
        self.users = await dbUsers.concurrentMap { user in
            Profile(
                id: user.id,
                image: await self.loadImage(for: user),
                email: user.email,
                name: user.name,
                surname: user.surname,
                team: user.team,
                job: user.job
            )
        }
    }

    func loadStages() async {
        let dbStages: [DBStage]
        do {
            let stageDocs = try await db.stages.getDocuments().documents
            dbStages = try stageDocs.map { try $0.data(as: DBStage.self) }
        } catch (let error) {
            errorMessage = error.localizedDescription
            return
        }
        self.stages = await dbStages.asyncMap { stage in
            Stage(
                id: stage.id,
                number: stage.number,
                begin: stage.begin,
                end: stage.end,
                isFinished: stage.finished,
                tasks: await loadTasks(for: stage.id)
            )
        }.sorted(using: KeyPathComparator(\.number))
    }

    func loadTasks(for stage: Stage) async {
        guard let index = stages.firstIndex(where: { $0.id == stage.id }) else {
            errorMessage = "Unknown stage encountered"
            return
        }
        stages[index].tasks = await loadTasks(for: stage.id)
    }

    private func loadTasks(for stageId: String) async -> [Task] {
        func loadComments(for task: DBTask) async throws -> [Comment] {
            let commentsRef = db.comments(for: task.id, in: stageId)
            let snap = try await commentsRef.getDocuments()

            guard !snap.isEmpty else { return [] }

            return try snap.documents
                .map { try $0.data(as: DBComment.self) }
                .compactMap { comment in
                    users.first(with: comment.author.documentID).map { author in
                        Comment(id: comment.id, authorId: author.id,
                                content: comment.content,
                                timestamp: comment.timestamp)
                    }
                }
        }
        do {
            let taskDocs = try await db.tasks(for: stageId).getDocuments().documents
            return try await taskDocs
                .map { try $0.data(as: DBTask.self) }
                .concurrentCompactMap { [self] task in
                    guard let author = users.first(with: task.author.documentID),
                          let assignee = users.first(with: task.assignee.documentID)
                    else { return nil }
                    return Task(
                        id: task.id,
                        title: task.title,
                        description: task.description,
                        authorId: author.id,
                        assigneeId: assignee.id,
                        status: .init(from: task.status),
                        comments: try await loadComments(for: task),
                        stageId: stageId
                    )
                }
        } catch let error {
            errorMessage = error.localizedDescription
            return []
        }
    }

    private func loadImage(for user: DBProfile) async -> UIImage? {
        let userRef = storage.profileImage(for: user.id)
        do {
            let imageData = try await withCheckedThrowingContinuation { cont in
                userRef.getData(maxSize: 10 << 20, completion: cont.resume(with:))
            }
            return UIImage(data: imageData)
        } catch StorageError.objectNotFound(let path) {
            print("Image for user \(user.name) was not found in \(path)")
        } catch let error {
            errorMessage = error.localizedDescription
        }
        return nil
    }

    func changeJob(in profile: Profile) async {
        await loadJobs()
        guard availableJobs.contains(profile.job) else {
            errorMessage = "Invalid job to pick"
            return
        }
        guard let i = users.firstIndex(with: profile.id) else {
            errorMessage = "Unknown user"
            return
        }
        do {
            if profile.job != Self.unselected {
                let query = db.jobs.whereField("title", isEqualTo: profile.job)
                try await query.getDocuments().documents[0].reference.delete()
            }
            if users[i].job != Self.unselected {
                try db.jobs.addDocument(from: Job(title: users[i].job))
            }
        } catch let error {
            errorMessage = error.localizedDescription
            return
        }
//        availableJobs.append(profile.job)
//        availableJobs.remove(at: availableJobs.firstIndex(of: users[i].job)!)
        self.users[i].job = profile.job
        self.profile?.job = profile.job
    }

    func upload(image: UIImage, for userId: String) async {
        let imageRef = storage.profileImage(for: userId)
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            errorMessage = "Failed to convert your image to jpeg"
            return
        }
        do {
            let _ = try await imageRef.putDataAsync(imageData)
        } catch let error {
            errorMessage = error.localizedDescription
            return
        }
        await loadUsers()
    }

    func upload(profile submitted: EditableProfile) async {
        guard let profile else {
            errorMessage = "Database fetch is not complete, try again later"
            return
        }
        guard submitted.isValid else {
            errorMessage = "Invalid profile submitted"
            return
        }
        var newProfile = profile
        newProfile.job = submitted.job
        if newProfile.job != profile.job {
            await changeJob(in: newProfile)
        }

        let dbProfile = DBProfile(
            email: profile.email,
            name: submitted.name, surname: submitted.surname,
            team: submitted.team, job: submitted.job
        )
        do {
            try db.users.document(profile.id).setData(from: dbProfile)
        } catch let error {
            errorMessage = error.localizedDescription
            return
        }
        await loadUsers()
    }

    func canFinish(stage: Stage) -> Bool {
        guard let profile, !stage.isFinished, stage.isStarted else { return false }
        return profile.job == Profile.leader
    }

    func canAddTask(to stage: Stage) -> Bool {
        guard let profile, !stage.isFinished else { return false }
        // current stage
        if stage.isStarted {
            return profile.job == Profile.leader
        }
        // future stage
        return true
    }

    var canCreateNewStage: Bool {
        guard let profile else { return false }
        return profile.job == Profile.leader
    }

    func canAddComment(to task: Task) -> Bool {
        guard let stage = stages.first(with: task.stageId) else { return false }
        return !stage.isFinished
    }

    func canEditStatus(of task: Task) -> Bool {
        guard let profile else { return false }
        guard let stage = stages.first(with: task.stageId) else { return false }
        // cannod edit finished stages
        if stage.isFinished { return false }

        if profile.job == Profile.leader {
            // main guy
            return true
        }
        // commmon
        let isAuthor = task.authorId == profile.id
        let isAssignee = task.assigneeId == profile.id
        if stage.isStarted {
            return isAuthor || isAssignee
        }
        return isAssignee
    }

    func canEdit(stage: Stage) -> Bool {
        guard let profile else { return false }
        return stage.isFuture && profile.job == Profile.leader
    }

    func canEdit(task: Task) -> Bool {
        guard let profile,
              let stage = stages.first(with: task.stageId),
              stage.isFuture
        else { return false }
        return profile.id == task.authorId || profile.job == Profile.leader
    }

    func canDelete(task: Task) -> Bool {
        guard let profile,
              let stage = stages.first(with: task.stageId),
              stage.isFuture
        else { return false }
        return profile.id == task.authorId || profile.job == Profile.leader
    }

    func update(status: Task.Status, for task: Task) async {
        guard canEditStatus(of: task) else {
            errorMessage = "You do not have permission for it"
            return
        }
        guard let stage = stages.first(with: task.stageId) else {
            errorMessage = "Invalid task with unknown stage"
            return
        }
        do {
            try await db.tasks(for: stage.id).document(task.id).updateData(
                ["status": status.rawValue]
            )
        } catch let error {
            errorMessage = error.localizedDescription
            return
        }
        if let i = stages.firstIndex(with: stage.id),
           let j = stages[i].tasks.firstIndex(with: task.id) {
            stages[i].tasks[j].status = status
        }
    }

    func finish(stage: Stage) async {
        guard canFinish(stage: stage) else { 
            errorMessage = "You do not have permission for it"
            return
        }
        do {
            try await db.stages.document(stage.id).updateData(
                ["finished": true]
            )
        } catch let error {
            errorMessage = error.localizedDescription
            return
        }
        guard let i = stages.firstIndex(with: stage.id) else { return }
        for task in stages[i].tasks where task.status.inProgress {
            // task need to be made overdue
            await self.update(status: .overdue, for: task)
        }
        stages[i].isFinished = true
    }

    func add(comment: EditableComment, to task: Task) async {
        guard canAddComment(to: task) else {
            errorMessage = "You do not have permission for it"
            return
        }
        guard comment.isValid else {
            errorMessage = "Invalid comment submitted"
            return
        }
        guard let profile else {
            errorMessage = "Profile is not yet loaded, try again later"
            return
        }
        let now = Date.now
        let dbComment = DBComment(
            author: db.users.document(profile.id),
            content: comment.content,
            timestamp: now
        )
        let commentRef: DocumentReference
        do {
            commentRef = try db.comments(for: task).addDocument(from: dbComment)
        } catch (let error) {
            errorMessage = error.localizedDescription
            return
        }
        if let i = stages.firstIndex(with: task.stageId),
           let j = stages[i].tasks.firstIndex(with: task.id) {
            stages[i].tasks[j].comments.append(
                Comment(
                    id: commentRef.documentID, authorId: profile.id,
                    content: comment.content, timestamp: now
                )
            )
            self.objectWillChange.send()
        }
    }
    
    func add(stage: EditableStage) async {
        let dbStage = DBStage(
            number: stages.count, begin: stage.begin,
            end: stage.end, finished: false
        )
        let stageRef: DocumentReference
        do {
            stageRef = try db.stages.addDocument(from: dbStage)
        } catch let error {
            errorMessage = error.localizedDescription
            return
        }
        stages.append(
            Stage(
                id: stageRef.documentID,
                number: dbStage.number,
                begin: stage.begin,
                end: stage.end,
                isFinished: false,
                tasks: []
            )
        )
    }

    func add(task: EditableTask, to stage: Stage) async {
        guard let profile else {
            errorMessage = "Data not loaded yet"
            return
        }
        guard canAddTask(to: stage) else {
            errorMessage = "You have no rights!"
            return
        }
        guard task.isValid,
              let assigneeId = task.assigneeId
        else {
            errorMessage = "Invalid task submitted"
            return
        }
        let dbTask = DBTask(
            title: task.title,
            description: task.description,
            author: db.users.document(profile.id),
            assignee: db.users.document(assigneeId),
            status: task.status.dbStatus
        )
        let taskRef: DocumentReference
        do {
            taskRef = try db.tasks(for: stage.id).addDocument(from: dbTask)
        } catch let error {
            errorMessage = error.localizedDescription
            return
        }
        stages.firstIndex(with: stage.id).map {
            stages[$0].tasks.append(
                Task(
                    id: taskRef.documentID,
                    title: task.title, 
                    description: task.description,
                    authorId: profile.id, assigneeId: assigneeId,
                    status: task.status,
                    comments: task.comments,
                    stageId: stage.id
                )
            )
        } // map
    }

    func edit(stage: EditableStage, with id: String) async {
        guard let i = stages.firstIndex(with: id) else {
            errorMessage = "Unknown stage, cannot edit"
            return
        }
        do {
            try await db.stages.document(id).updateData([
                "begin": stage.begin,
                "end": stage.end
            ])
        } catch let error {
            errorMessage = error.localizedDescription
            return
        }
        stages[i].begin = stage.begin
        stages[i].end = stage.end
    }

    func edit(task: EditableTask, with id: String, in stage: Stage) async {
        guard let i = stages.firstIndex(with: stage.id) else {
            errorMessage = "Unknown stage, cannot edit"
            return
        }
        guard let j = stages[i].tasks.firstIndex(with: id) else {
            errorMessage = "Unknown task, cannot edit"
            return
        }
        guard let assigneeId = task.assigneeId else {
            errorMessage = "Task must have an assignee"
            return
        }
        let authorId = stages[i].tasks[j].authorId
        do {
            try await db.tasks(for: stage.id).document(id).updateData([
                "title": task.title,
                "description": task.description,
                "assignee": db.users.document(assigneeId),
                "status": task.status.rawValue,
            ])
        } catch let error {
            errorMessage = error.localizedDescription
            return
        }
        stages[i].tasks[j] = Task(
            id: id,
            title: task.title,
            description: task.description,
            authorId: authorId, assigneeId: assigneeId,
            status: task.status,
            comments: task.comments,
            stageId: stage.id
        )
    }

    func delete(in tasks: [Task], at offset: IndexSet, for stage: Stage) async {
        guard let i = stages.firstIndex(with: stage.id) else {
            errorMessage = "Unknown stage, cannot delete"
            return
        }
        do {
            try await offset.map { tasks[$0] }.concurrentForEach { [self] task in
                guard let j = stages[i].tasks.firstIndex(with: task.id) else { return }
                try await db.tasks(for: stages[i].id).document(task.id).delete()
                stages[i].tasks.remove(at: j)
            }
        } catch let error {
            errorMessage = error.localizedDescription
            return
        }
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

extension Firestore {
    var allJobs: CollectionReference {
        collection("allJobs")
    }

    var jobs: CollectionReference {
        collection("jobs")
    }

    var stages: CollectionReference {
        collection("stages")
    }

    var users: CollectionReference {
        collection("users")
    }

    var events: CollectionReference {
        collection("events")
    }

    func tasks(for stageId: String) -> CollectionReference {
        stages.document(stageId).collection("tasks")
    }

    func comments(for task: Task) -> CollectionReference {
        tasks(for: task.stageId).document(task.id).collection("comments")
    }

    func comments(for taskId: String, in stageId: String) -> CollectionReference {
        tasks(for: stageId).document(taskId).collection("comments")
    }
}

extension Storage {
    func profileImage(for userId: String) -> StorageReference {
        reference(withPath: userId).child("profile-image.jpg")
    }
}
