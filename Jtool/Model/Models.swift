import Foundation
import FirebaseFirestore

struct EditableTask {
    var title = ""
    var description = ""
    var assigneeId: String?
    var status = Task.Status.active
    var comments: [Comment] = []

    var isValid: Bool {
        true
        && !title.isEmpty
        && assigneeId != nil
    }

    init() {}

    init(from task: Task) {
        self.title = task.title
        self.description = task.description
        self.assigneeId = task.assigneeId
        self.status = task.status
        self.comments = task.comments
    }
}

struct Task: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let authorId: String
    let assigneeId: String
    var status: Status
    var comments: [Comment]
    let stageId: String

    static func == (a: Task, b: Task) -> Bool {
        a.id == b.id &&
        a.title == b.title &&
        a.description == b.description &&
        a.assigneeId == b.assigneeId &&
        a.status == b.status &&
        a.comments == b.comments &&
        a.stageId == b.stageId
    }

    enum Status: String, CaseIterable {
        case active
        case archived
        case overdue
        case completed
        case review = "in review"

        init(from status: DBTask.Status) {
            switch status {
            case .active: self = .active
            case .archived: self = .archived
            case .overdue: self = .overdue
            case .completed: self = .completed
            case .review: self = .review
            }
        }

        var inProgress: Bool {
            self == .active || self == .review
        }

        var dbStatus: DBTask.Status {
            switch self {
            case .active: .active
            case .archived: .archived
            case .overdue: .overdue
            case .completed: .completed
            case .review: .review
            }
        }
    }
}

struct DBTask: Codable {
    @DocumentID var id: String!
    let title: String
    let description: String
    let author: DocumentReference
    let assignee: DocumentReference
    let status: Status

    enum Status: String, Codable {
        case active
        case archived
        case overdue
        case completed
        case review = "in review"
    }
}

struct EditableComment {
    var content = ""

    var isValid: Bool {
        !content.isEmpty
    }
}

struct Comment: Identifiable, Equatable {
    let id: String
    let authorId: String
    let content: String
    let timestamp: Date

    static func == (a: Comment, b: Comment) -> Bool {
        a.id == b.id &&
        a.authorId == b.authorId &&
        a.content == b.content &&
        a.timestamp == b.timestamp
    }
}

struct DBComment: Codable {
    @DocumentID var id: String!
    let author: DocumentReference
    let content: String
    let timestamp: Date
}

struct EditableStage: Identifiable {
    let id = UUID()

    var begin = Date()
    var end = Date()

    init() {}
    init(stage: Stage) {
        self.begin = stage.begin
        self.end = stage.end
    }

    var isValid: Bool {
        begin <= end && self.end > Date.now
    }
}

struct Stage: Identifiable, Equatable {
    let id: String
    let number: Int
    var begin: Date
    var end: Date
    var isFinished: Bool
    var tasks: [Task]

    var isStarted: Bool { begin <= .now }
    var isFuture: Bool { !isStarted }
    var isCurrent: Bool { isStarted && !isFinished }
    var completedCount: Int {
        tasks.filter { $0.status == .completed }.count
    }

    static func == (a: Stage, b: Stage) -> Bool {
        a.id == b.id &&
        a.number == b.number &&
        a.begin == b.begin &&
        a.end == b.end &&
        a.isFinished == b.isFinished &&
        a.tasks == b.tasks
    }
}

struct DBStage: Codable {
    @DocumentID var id: String!
    let number: Int
    let begin: Date
    let end: Date
    let finished: Bool
}

struct EditableProfile {
    var name = ""
    var surname = ""
    var team = Profile.unselected
    var job = Profile.unselected

    init() {}

    init(from profile: Profile) {
        self.name = profile.name
        self.surname = profile.surname
        self.team = profile.team
        self.job = profile.job
    }

    static func == (self: EditableProfile, profile: Profile) -> Bool {
        true
        && self.name == profile.name
        && self.surname == profile.surname
        && self.team == profile.team
        && self.job == profile.job
    }
    static func != (self: EditableProfile, profile: Profile) -> Bool {
        !(self == profile)
    }

    var isValid: Bool {
        true
        && !name.isEmpty
        && !surname.isEmpty
        && team != Profile.unselected
        && job != Profile.unselected
    }
}

extension Profile {
    static let unselected = "Unspecified"
    static let leader = "Leader"

//    static let availableTeams = [
//        unselected,
//        "Mobile",
//        "Backend"
//    ]
//    static let availableJobs = [
//        unselected,
//        "Leader",
//        "Tester",
//        "Developer",
//    ]
}

struct Profile: Identifiable, Hashable {
    let id: String
    var image: UIImage?
    let email: String
    let name: String
    let surname: String
    let team: String
    var job: String
}

struct DBProfile: Codable {
    @DocumentID var id: String!
    let email: String
    let name: String
    let surname: String
    let team: String
    let job: String
}

struct Job: Codable {
    let title: String
}
