import Foundation
import FirebaseFirestore

@MainActor
class EventStore: Store {
    @Published var events: [Event] = []

    func events(on date: Date) -> [Event] {
        events.filter { $0.timing.start.startOfDay == date.startOfDay }
    }

    override func loadAll() async {
        await super.loadAll()
        await loadEvents()
    }

    func loadEvents() async {
        let dbEvents: [DBEvent]
        do {
            let eventDocs = try await db.events.getDocuments().documents
            dbEvents = try eventDocs.map { try $0.data(as: DBEvent.self) }
        } catch let error {
            self.errorMessage = error.localizedDescription
            return
        }

        self.events = dbEvents.map { event in
            let participants = event.participants.compactMap { ref in
                users.first { $0.id == ref.documentID }
            }
            return Event(
                id: event.id!,
                title: event.title,
                agenda: event.agenda,
                timing: .init(start: event.begin, end: event.end),
                participants: participants
            )
        }
    }

    func add(event: EditableEvent) async {
        let participantRefs = event.participants.map { user in
            db.users.document(user.id)
        }
        let dbEvent = DBEvent(
            title: event.title,
            agenda: event.agenda,
            begin: event.start,
            end: event.end,
            participants: participantRefs
        )
        let eventRef: DocumentReference
        do {
            eventRef = try db.events.addDocument(from: dbEvent)
        } catch let error {
            self.errorMessage = error.localizedDescription
            return
        }
        // imitation of load
        events.append(.init(from: event, id: eventRef.documentID))
    }
}

struct EditableEvent: Identifiable {
    let id = UUID()
    var title = ""
    var agenda = ""
    var start = Date()
    var end = Date()
    var participants = Set<Profile>()

    var isValid: Bool {
        let basic = !title.isEmpty && !participants.isEmpty
        let advanced = start <= end
        return basic && advanced
    }
}

struct Event: Identifiable {
    let id: String
    let title: String
    let agenda: String
    let timing: DateInterval
    let participants: [Profile]

    init(id: String, title: String, agenda: String,
        timing: DateInterval, participants: [Profile]) {
        self.id = id
        self.title = title
        self.agenda = agenda
        self.timing = timing
        self.participants = participants
    }

    init(from event: EditableEvent, id: String) {
        self.id = id
        self.title = event.title
        self.agenda = event.agenda
        self.timing = .init(start: event.start, end: event.end)
        self.participants = Array(event.participants)
    }
}

struct DBEvent: Codable {
    @DocumentID var id: String?
    var title: String
    var agenda: String
    var begin: Date
    var end: Date
    var participants: [DocumentReference]
}
