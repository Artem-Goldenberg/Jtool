import Foundation
import FirebaseFirestore

struct Task: Codable {
    @DocumentID var id: String!

    var title: String
    var description: String?

    let author: DocumentReference?
    var assignee: DocumentReference?

    var status: Status
    var comments: [Comment] = []

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case author
        case assignee
        case status
    }

    enum Status: String, Codable, CaseIterable {
        case active
        case archived
        case overdue
        case completed
        case review = "in review"
    }

    static var unique = 0
}

struct Comment: Codable {
    @DocumentID var id: String!

    let author: DocumentReference
    let content: String
}

struct Stage: Codable {
    @DocumentID var id: String!
    let number: Int

    var begin: Date
    var end: Date
    var isFinished: Bool
    var tasks: [Task] = []

    enum CodingKeys: String, CodingKey {
        case id
        case begin
        case end
        case number
        case isFinished = "finished"
    }
}

struct Profile: Codable, Equatable {
    @DocumentID var id: String!

    var email: String = ""
    var image: UIImage?
    var name = ""
    var surname = ""
    var team = unselected
    var job = unselected

    enum CodingKeys: CodingKey {
        case id
        case email
        case name
        case surname
        case team
        case job
    }

    static private let unselected = "Unspecified"

    static let teams = [
        unselected,
        "Mobile",
        "Backend"
    ]

    static let jobs = [
        unselected,
        "Leader",
        "Tester",
        "Primary Developer",
        "Secondary Developer"
    ]
}
