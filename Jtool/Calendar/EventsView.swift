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

//struct UserPicker: View {
//    @Binding var user: Profile
//
//    var body: some View {
//        Form {
//            ForEach(users, id: \.id) { user in
//                Button { toggle(user) } label: {
//                    HStack {
//                        Text(user.name)
//                            .foregroundStyle(.primary)
//                        Spacer()
//                        Image(systemName: iconName(for: user))
//                            .font(.headline)
//                    }
//                }
//            } // foreach
//        } // form
//    }
//
//    private func iconName(for user: Profile) -> String {
//        if participants.contains(user) {
//            return "checkmark.circle.fill"
//        }
//        return "circle"
//    }
//
//    private func toggle(_ user: Profile) {
//        if let found = participants.firstIndex(of: user) {
//            participants.remove(at: found)
//        } else {
//            participants.append(user)
//        }
//    }
//}

struct EventEditView: View {
    @Binding var event: EditableEvent
    let users: [Profile]
    let creation: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Title").font(.headline)) {
                    TextField("Someone's birthday?", text: $event.title)
                }
                Section(header: Text("Agenda").font(.headline)) {
                    TextField("What this all about?", text: $event.agenda, axis: .vertical)
                        .lineLimit(12)
                }
                Section(header: Text("Time").font(.headline)) {
                    DatePicker("Date", selection: dayBinding(), displayedComponents: .date)
                    DatePicker("From", selection: $event.start, displayedComponents: .hourAndMinute)
                    DatePicker("To", selection: $event.end, displayedComponents: .hourAndMinute)
                }
                Section {
                    NavigationLink("Choose Participants", destination: usersPicker)
                }
            }
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create", action: creation)
                        .font(.headline)
                        .disabled(!event.isValid)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                        event = .init()
                    }
                }
            }
        }
    }

    private func dayBinding() -> Binding<Date> {
        Binding<Date> {
            self.event.start
        } set: { newValue in
            event.start = newValue
            event.end = newValue
        }
    }

    var usersPicker: some View {
        Form {
            ForEach(users, id: \.id) { user in
                Button { toggle(user) } label: {
                    HStack {
                        Text(user.name)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: iconName(for: user))
                            .font(.headline)
                    }
                }
            } // foreach
        } // form
    }

    private func iconName(for user: Profile) -> String {
        if event.participants.contains(user) {
            return "checkmark.circle.fill"
        }
        return "circle"
    }

    private func toggle(_ user: Profile) {
        if let found = event.participants.firstIndex(of: user) {
            event.participants.remove(at: found)
        } else {
            event.participants.insert(user)
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
