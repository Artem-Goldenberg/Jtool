import SwiftUI

struct TaskView: View {
    @State var task: Task
    @State private var state: EditableTask
    @State private var commenting = false
    @State private var editing = false

    @EnvironmentObject var store: Store

    init(task: Task) {
        self.task = task
        self._state = State(initialValue: .init(from: task))
    }

    var body: some View {
        Form {
            Section(header: Text("Description")) {
                Text(task.description)
            }
            Section(header: Text("Author")) {
                NavigationLink(store.getAuthor(for: task).name) {
                    ProfileView(profile: store.getAuthor(for: task))
                }
            }
            Section(header: Text("Assignee")) {
                NavigationLink(store.getAssignee(for: task).name) {
                    ProfileView(profile: store.getAssignee(for: task))
                }
            }
            Section {
                Picker("Status", selection: $state.status) {
                    ForEach(Task.Status.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }
                .disabled(!store.canEditStatus(of: task))
                .onChange(of: state.status, updateStatus)
            }
            Spacer(minLength: 50).listRowBackground(Color(UIColor.systemGroupedBackground))

            Section(header: Text("Comments").font(.title)) { EmptyView() }
            Section {
                Button("Add comment") {
                    commenting = true
                }
                .buttonStyle(.borderless)
                .disabled(!store.canAddComment(to: task))
            }
            ForEach(comments) { comment in
                Section {
                    Text(comment.content)
                    NavigationLink {
                        ProfileView(profile: store.users.first(with: comment.authorId)!)
                    } label: {
                        Text(caption(for: comment))
                        .foregroundStyle(.link)
                    }
                }
            }.buttonStyle(.borderless)
        }
        .navigationTitle(task.title)
        .toolbar {
            if store.canEdit(task: task) {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") {
                        editing = true
                    }
                }
            }
        }
        .sheet(isPresented: $editing) {
            if let stage {
                TaskEditView(stage: stage, task: $state, existingId: task.id)
            }
        }
        .sheet(isPresented: $commenting) {
            CommentEditView(task: task)
        }
        .onChange(of: store.stages) {
            task = store.stages.first(with: task.stageId)!
                .tasks.first(with: task.id)!
        }
    }

    var stage: Stage? {
        store.stages.first(with: task.stageId)
    }

    var comments: [Comment] {
        task.comments.sorted(using: KeyPathComparator(\.timestamp, order: .reverse))
    }

    private func caption(for comment: Comment) -> String {
        let dateString = comment.timestamp.formatted(date: .abbreviated, time: .shortened)
        let user = store.users.first(with: comment.authorId)!
        return "\(user.name), \(dateString)"
    }

    private func updateStatus() {
        Worker {
            await store.update(status: state.status, for: task)
            if store.hasError {
                state.status = task.status
            }
        }
    }
}

struct CommentEditView: View {
    let task: Task
    @State private var state = EditableComment()

    @EnvironmentObject var store: Store
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                TextField("Write here", text: $state.content, axis: .vertical)
                    .lineLimit(12)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", action: uploadComment)
                        .font(.headline)
                        .disabled(!state.isValid)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                        state.content = ""
                    }
                }
            }
            .navigationTitle("Comment this task")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDisabled(true)
        }
    }

    private func uploadComment() {
        Worker {
            await store.add(comment: state, to: task)
            dismiss()
            if !store.hasError {
                state = .init()
            }
        }
    }
}

extension Store {
    func getAuthor(for task: Task) -> Profile {
        users.first(with: task.authorId)!
    }
    func getAssignee(for task: Task) -> Profile {
        users.first(with: task.assigneeId)!
    }
}
