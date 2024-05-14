import Foundation
import FirebaseFirestore

struct EditableTask {
    var title = ""
    var description = ""
    var assignee: Profile?
    var status = Task.Status.active
    var comments: [Comment] = []

    var isValid: Bool {
        true
        && !title.isEmpty
        && assignee != nil
    }

    init() {}

    init(from task: Task) {
        self.title = task.title
        self.description = task.description
        self.assignee = task.assignee
        self.status = task.status
        self.comments = task.comments
    }
}

struct Task: Identifiable {
    let id: String
    let title: String
    let description: String
    let author: Profile
    let assignee: Profile
    var status: Status
    var comments: [Comment]
    let stageId: String

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

struct Comment: Identifiable {
    let id: String
    let author: Profile
    let content: String
    let timestamp: Date
}

struct DBComment: Codable {
    @DocumentID var id: String!
    let author: DocumentReference
    let content: String
    let timestamp: Date
}

struct EditableStage {
    var begin = Date()
    var end = Date()

    var isValid: Bool { begin <= end }
}

struct Stage: Identifiable, Comparable {
    let id: String
    let number: Int
    let begin: Date
    let end: Date
    var isFinished: Bool
    var tasks: [Task]

    var isStarted: Bool { begin <= .now }
    var isCurrent: Bool { isStarted && !isFinished }
    var completedCount: Int {
        tasks.filter { $0.status == .completed }.count
    }

    static func < (lhs: Stage, rhs: Stage) -> Bool {
        lhs.number < rhs.number
    }

    static func == (lhs: Stage, rhs: Stage) -> Bool {
        lhs.id == rhs.id
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
        && Profile.availableTeams.contains(team)
        && Profile.availableJobs.contains(job)
    }
}

extension Profile {
    static let unselected = "Unspecified"
    static let leader = "Leader"

    static let availableTeams = [
        unselected,
        "Mobile",
        "Backend"
    ]
    static let availableJobs = [
        unselected,
        "Leader",
        "Tester",
        "Primary Developer",
        "Secondary Developer"
    ]
}

struct Profile: Identifiable, Hashable {
    let id: String
    var image: UIImage?
    let email: String
    let name: String
    let surname: String
    let team: String
    let job: String
}

struct DBProfile: Codable {
    @DocumentID var id: String!
    let email: String
    let name: String
    let surname: String
    let team: String
    let job: String
}
