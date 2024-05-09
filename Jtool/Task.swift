import Foundation

typealias PersonId = Int

struct Task: Identifiable {
    let id: String
    let number: Int

    let title: String
    let description: String?

    let author: PersonId
    let assignee: PersonId

    let status: Status
    let comments: [Comment]

    enum Status {
        case active
        case archived
        case suggested
    }

    static var unique = 0

    init(title: String, description: String? = nil, author: PersonId = 0, assignee: PersonId = 0, status: Status = .active, comments: [Comment] = []) {
        self.title = title
        self.description = description
        self.author = author
        self.assignee = assignee
        self.status = status
        self.comments = comments

        self.id = UUID().uuidString
        self.number = Self.unique
        Self.unique += 1
    }

    static let test: [Task] = [
        .init(title: "Design", description: "We need to make and design. Upload a ready well prepared copy of your work!. Don't be late!"),
        .init(title: "Get Firebase"),
        .init(title: "Starter App"),
        .init(title: "Some more")
    ]

}

struct Comment {
    let person: PersonId
    let content: String
}
