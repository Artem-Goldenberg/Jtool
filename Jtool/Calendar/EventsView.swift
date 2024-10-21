import SwiftUI

struct EventsView: View {
    @EnvironmentObject var store: EventStore
    @State private var selectedDate: Date?
    @State private var isEditing = false
    @State private var editableEvent = EditableEvent()

    var body: some View {
        NavigationStack {
            CalendarView(date: $selectedDate)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("New Meeting") {
                            isEditing = true
                        }
                    }
                }
                .sheet(item: $selectedDate) { date in
                    EventListView(date: date)
                }
                .sheet(isPresented: $isEditing) {
                    EventEditView(event: $editableEvent, users: store.users) {
                        isEditing = false
                        let copy = editableEvent
                        editableEvent = EditableEvent()
                        Worker {
                            await store.add(event: copy)
                            await store.loadEvents()
                        }
                    }
                }
                .navigationTitle("Meetings")
        }
    }
}

struct EventListView: View {
    let date: Date

    @EnvironmentObject var store: EventStore

    var events: [Event] { store.events(on: date) }

    var body: some View {
        NavigationStack {
            Group {
                if events.isEmpty {
                    ContentUnavailableView(
                        "Relax, no meetings for this day",
                        systemImage: "figure.yoga"
                    )
                } else {
                    List(events) { event in
                        NavigationLink(event.title, destination: EventView(event: event))
                    }
                }
            }
            .navigationTitle(date.formatted(date: .abbreviated, time: .omitted))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct EventView: View {
    let event: Event

    var body: some View {
        Form {
            Section(header: Text("Agenda").font(.headline)) {
                Text(event.agenda)
            }
            Section {
                LabeledContent(
                    "From",
                    value: event.timing.start.formatted(date: .omitted, time: .shortened)
                )
                LabeledContent(
                    "To",
                    value: event.timing.end.formatted(date: .omitted, time: .shortened)
                )
            }
            Section(header: Text("Participants")) {
                ForEach(event.participants, id: \.id) { user in
                    NavigationLink(user.name, destination: ProfileView(profile: user))
                }
            }
        }
        .navigationTitle(event.title)
    }
}

#Preview {
    EventsView()
}
