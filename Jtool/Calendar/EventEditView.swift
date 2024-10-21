import SwiftUI

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
            } // form
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
            } // toolbar
        } // navigation
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
