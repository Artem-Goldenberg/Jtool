import SwiftUI
import FirebaseFirestore

struct TaskListView: View {
    enum Filter: String, Identifiable, CaseIterable {
        case forMe = "Assignee"
        case byMe = "Author"
        case all = "All"
        var id: Self { self }
        var noneMessage: String {
            switch self {
            case .forMe: "No Tasks For You Today"
            case .byMe: "You've not created any"
            case .all: "There are no tasks at all!"
            }
        }
    }
//    enum SortType: String, CaseIterable {
//        case date
//        case dateReverse
//        case overdue
//    }
    let stage: Stage

    @State private var search: String = ""
    @State private var filter: Filter = .forMe
    @State private var showingEdit = false
//    @State private var sortBy: SortType = .date
    @State private var showFilters = false

    @EnvironmentObject var store: Store

    private var filtered: [Task] {
        let tasks = stage.tasks
            .filter {
                switch filter {
                case .forMe: $0.assignee.id == store.profile?.id
                case .byMe: $0.author.id == store.profile?.id
                case .all: true
                }
            }
        guard !search.isEmpty else { return tasks }
        return tasks.filter { $0.title.contains(search) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if filtered.isEmpty {
                    ContentUnavailableView(filter.noneMessage, systemImage: "figure.dance")
                } else {
                    List {
                        ForEach(filtered) { task in
                            NavigationLink {
                                TaskView(task: task)
                            } label: {
                                Text(task.title)
                            }
                        }
                    }
                    .frame(minHeight: CGFloat(filtered.count) * 40)
                } // if-else
            } // scrollView
            .listStyle(.plain)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    filtersView
                }
                if store.canAddTask(to: stage) {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("New Task") {
                            showingEdit = true
                        }
                    }
                }
            }
            .searchable(text: $search)
            .navigationTitle("Tasks")
            .refreshable {
                Worker {
                    await store.loadTasks(for: stage)
                }
            }
            .onAppear() {
                Worker {
                    await store.loadTasks(for: stage)
                }
            }
            .sheet(isPresented: $showingEdit) {
                TaskEditView(stage: stage)
            }
        } // navigation
    } // body

    var filtersView: some View {
        Menu {
            Picker("Filter by", selection: $filter) {
                ForEach(Filter.allCases) {
                    Text($0.rawValue)
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .font(.headline)
        }
    }
}

struct TaskEditView: View {
    let stage: Stage
    @State private var task = EditableTask()
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $task.title)
                }
                Section {
                    TextField("Description", text: $task.description, axis: .vertical)
                        .lineLimit(12)
                }
                Section {
                    Picker("Assignee", selection: $task.assignee) {
                        ForEach(store.users) { user in
                            Text(user.name).tag(user as Profile?)
                        }
                        Text("Unselected").tag(nil as Profile?)
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
                    Button("Create") {
                        dismiss()
                        Worker {
                            await store.add(task: task, to: stage)
                        }
                    }
                    .font(.headline)
                    .disabled(!task.isValid)
                }
            }
        } // navigation
    }
}

struct TaskView: View {
    let task: Task
    @State private var state: EditableTask
    @State private var commenting = false

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
                NavigationLink(task.author.name) {
                    ProfileView(profile: task.author)
                }
            }
            Section(header: Text("Assignee")) {
                NavigationLink(task.assignee.name) {
                    ProfileView(profile: task.assignee)
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
                        ProfileView(profile: comment.author)
                    } label: {
                        Text(caption(for: comment))
                        .foregroundStyle(.link)
                    }
                }
            }.buttonStyle(.borderless)
        }
        .navigationTitle(task.title)
        .sheet(isPresented: $commenting) {
            CommentEditView(task: task)
        }
    }

    var comments: [Comment] {
        task.comments.sorted(using: KeyPathComparator(\.timestamp, order: .reverse))
    }

    private func caption(for comment: Comment) -> String {
        let dateString = comment.timestamp.formatted(date: .abbreviated, time: .shortened)
        return "\(comment.author.name), \(dateString)"
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
