import UIKit

struct ProfileInfo {
    var image: UIImage?
    var name = ""
    var surname = ""
    var team = unselected
    var job = unselected

    static private let unselected = "Not Selected"

    static let teams = [
        unselected,
        "Team mobile",
        "Team backend"
    ]

    static let jobs = [
        unselected,
        "Leader",
        "Tester",
        "Primary Developer",
        "Secondary Developer"
    ]

    static let test: [ProfileInfo] = [
        .init(name: "Morris", surname: "The Important One", team: "Team mobile", job: "Tester"),
        .init(name: "Smith", surname: "Smith", team: "Team backend", job: "Leader"),
        .init(name: "Michle", surname: "Michele", team: "Team backend", job: "Primary Developer"),
        .init(name: "Gendalf", surname: "The Mage", team: "Team mobile", job: "Leader")
    ]
}
