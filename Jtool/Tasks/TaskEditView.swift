import SwiftUI

struct TaskEditView: View {
    let stage: Stage
    @Binding var task: EditableTask
    var existingId: String?
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("title")) {
                    TextField("Title", text: $task.title)
                }
                Section(header: Text("description")) {
                    TextField("Description", text: $task.description, axis: .vertical)
                        .lineLimit(12)
                }
                Section {
                    Picker("Assignee", selection: $task.assigneeId) {
                        ForEach(store.users) { user in
                            Text(user.name).tag(user.id as String?)
                        }
                        Text("Unselected").tag(nil as String?)
                    }
                }
                Section {
                    Picker("Status", selection: $task.status) {
                        ForEach(Task.Status.allCases, id: \.self) {
                            Text($0.rawValue)
                        }
                    }
                }
            } // form
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                        Worker {
                            if let existingId {
                                await store.edit(task: task, with: existingId, in: stage)
                            } else {
                                await store.add(task: task, to: stage)
                            }
                        }
                    }
                    .font(.headline)
                    .disabled(!task.isValid)
                }
            }
        } // navigation
    }
}
