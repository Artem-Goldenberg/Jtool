import SwiftUI
import FirebaseFirestore

// TODO: fetch by relaoding

fileprivate func title(for task: Task) -> String {
    return task.title
}

struct TaskListView: View {
    @State private var search: String = ""

    @EnvironmentObject var store: Store

    private var filtered: [Task] {
        guard !search.isEmpty else { return store.currentTasks }
        return store.currentTasks.filter { title(for: $0).contains(search) }
    }

    var body: some View {
        NavigationStack {
                List {
                    ForEach(filtered, id: \.id) { task in
                        NavigationLink {
                            TaskView(task: task)
                        } label: {
                            Text(title(for: task))
                        }
                    }
                    .listStyle(.inset)
                }
                .navigationTitle("Tasks")
                .refreshable {
                    await store.load(for: store.profile.email)
                }
        }
        .searchable(text: $search)
    }
}

struct TaskView: View {
    let task: Task

    init(task: Task) {
        self.task = task
        self.status = task.status.rawValue
        self.comments = []
    }

    @EnvironmentObject var store: Store

    private var authorId: Int? {
        store.users.firstIndex { $0.id == task.author?.documentID }
    }
    private var assigneeId: Int? {
        store.users.firstIndex { $0.id == task.assignee?.documentID }
    }

    struct Comment {
        var id: String
        let authorId: Int
        let content: String
        let timestamp: Date
    }
//
//    private var comments: [Comment] {
//        task.comments.compactMap { comment in
//            guard let id = store.users.firstIndex(where: { $0.id == comment.author.documentID })
//            else { return nil }
//            return Comment(
//                id: comment.id, authorId: id,
//                content: comment.content,
//                timestamp: comment.timestamp
//            )
//        }.sorted(using: KeyPathComparator(\.timestamp, order: .reverse))
//    }

    @State private var status: String
    @State private var comments: [Comment]
    @State private var commenting: Bool = false
    @State private var commentText: String = ""

    var body: some View {
        Form {
            Section(header: Text("Description")) {
                Text(task.description ?? "No description")
            }

            if let authorId = authorId {
                Section(header: Text("Author")) {
                    let author = store.users[authorId]
                    NavigationLink(author.name) {
                        ProfileView(info: $store.users[authorId], readOnly: true)
                    }
                }
            }

            if let assigneeId = assigneeId {
                Section(header: Text("Assignee")) {
                    let author = store.users[assigneeId]
                    NavigationLink(author.name) {
                        ProfileView(info: $store.users[assigneeId], readOnly: true)
                    }
                }
            }

            Section {
                Picker("Status", selection: $status) {
                    ForEach(Task.Status.allCases.map(\.rawValue), id: \.self) {
                        Text($0)
                    }
                }
                .onChange(of: status, updateStatus)
            }

            Spacer(minLength: 50).listRowBackground(Color(UIColor.systemGroupedBackground))


            Section(header: Text("Comments").font(.title)) { EmptyView() }

            Section {
                Button("Add comment") {
                    commenting = true
                }.buttonStyle(.borderless)
            }

            ForEach(comments, id: \.id) { comment in
                Section {
                    Text(comment.content)
                    NavigationLink {
                        ProfileView(info: $store.users[comment.authorId], readOnly: true)
                    } label: {
                        Text(caption(for: comment))
                        .foregroundStyle(.link)
                    }
                }
            }.buttonStyle(.borderless)
        }
        .navigationTitle(task.title)
        .sheet(isPresented: $commenting) {
            CommentField(commenting: $commenting, comments: $comments, text: $commentText, taskId: task.id)
        }
        .onAppear(perform: filterComments)
    }

    private func caption(for comment: Comment) -> String {
        let dateString = comment.timestamp.formatted(date: .abbreviated, time: .shortened)
        return "\(store.users[comment.authorId].name), \(dateString)"
    }

    private func updateStatus() {
        Worker {
            await store.change(status: status, for: task.id)
            if store.hasError {
                self.status = task.status.rawValue
            }
        }
    }

    private func filterComments() {
        comments = task.comments.compactMap { comment in
            guard let id = store.users.firstIndex(where: { $0.id == comment.author.documentID })
            else { return nil }
            return Comment(
                id: comment.id, authorId: id,
                content: comment.content,
                timestamp: comment.timestamp
            )
        }.sorted(using: KeyPathComparator(\.timestamp, order: .reverse))
    }
}

struct CommentField: View {
    @Binding var commenting: Bool
    @Binding var comments: [TaskView.Comment]
    @Binding var text:String


    let taskId: String

    @EnvironmentObject var store: Store

    var body: some View {
        NavigationStack {
            Form {
                TextField("Write here", text: $text, axis: .vertical)
                    .lineLimit(12)
//                TextEditor(text: $text)
            }
            .toolbar {
                Group {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done", action: uploadComment)
                            .font(.headline)
                    }
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            commenting = false
                            text = ""
                        }
                    }
                }
            }
            .navigationTitle("Comment this task")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDisabled(true)
        }
    }

    private func uploadComment() {
        commenting = false
        guard text != "" else { return }
        Worker {
            guard let id = await store.add(comment: text, for: taskId) else {
                return
            }
            // TODO: kinda bad, but ok...
            let newComment = TaskView.Comment(
                id: id,
                authorId: store.userId!,
                content: text,
                timestamp: Date()
            )
            if let index = comments.firstIndex(where: { $0.timestamp < newComment.timestamp }) {
                comments.insert(newComment, at: index)
            } else {
                comments.append(newComment)
            }
            text = ""
        }
    }
}

struct TaskView1: View {
    var task: Task

//    var author: Profile {
//        profile(by: task.author)
//    }

    var heading: some View {
        Text(title(for: task))
            .font(.largeTitle)
            .bold()
            .padding(.vertical)
    }

    var body: some View {
//        Form {
//            Section(header: heading) {
        VStack {
            heading

            VStack(alignment: .leading) {
                Text("Description")
                    .font(.headline)
                    .padding(.bottom, 3)
                Text(task.description ?? "No description")
            }

            Divider()

            HStack(spacing: 15) {
                Text("Author:").bold()
                NavigationLink {
                    EmptyView()
//                    ProfileView(info: author, readOnly: true)
                } label: {
//                    DisplayImage(image: author.image)
//                        .frame(width: 30, height: 30)
//                    Text(author.name)
//                        .font(.headline)
//                        .foregroundStyle(Color.blue)
                    Text("Under Construction")
                }
                Spacer()
            }

           Spacer()
        }
        .padding(.horizontal, 15)
//            }
//            Section(header: Text("Author")) {
//            }
//        }
    }
}

#Preview {
//    TaskListView()
    TaskView(task: .init(title: "Some Task", author: nil, status: .active))
}
