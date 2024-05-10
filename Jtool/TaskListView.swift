import SwiftUI

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
        }
        .searchable(text: $search)
        .navigationTitle("Tasks")
    }
}

struct TaskView: View {
    let task: Task

    init(task: Task) {
        self.task = task
        self.status = task.status.rawValue
    }

    @EnvironmentObject var store: Store

    private var authorId: Int? {
        store.users.firstIndex { $0.id == task.author?.documentID }
    }
    private var assigneeId: Int? {
        store.users.firstIndex { $0.id == task.assignee?.documentID }
    }

    @State private var status: String

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
                .onChange(of: status) {
                    Worker {
                        await store.change(status: status, for: task.id)
                        if store.hasError {
                            self.status = task.status.rawValue
                        }
                    }
                }
            }
        }
        .navigationTitle(task.title)
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
