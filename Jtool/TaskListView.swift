import SwiftUI

fileprivate func title(for task: Task) -> String {
    return "#\(task.number): \(task.title)"
}

struct TaskListView: View {
    @State private var tasks: [Task] = Task.test
    @State private var search: String = ""

    private var filtered: [Task] {
        guard !search.isEmpty else { return tasks }
        return tasks.filter { title(for: $0).contains(search) }
    }

    var body: some View {
        NavigationStack {
//            Form {
                List {
                    ForEach(filtered) { task in
                        NavigationLink {
                            TaskView(task: task)
                        } label: {
                            Text(title(for: task))
                        }
                    }
                }
//            }
        }.searchable(text: $search)
    }
}

fileprivate func profile(by id: PersonId) -> ProfileInfo {
    ProfileInfo.test[id]
}

struct TaskView: View {
    var task: Task

    var author: ProfileInfo {
        profile(by: task.author)
    }

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
                    ProfileView(info: author, readOnly: true)
                } label: {
//                    DisplayImage(image: author.image)
//                        .frame(width: 30, height: 30)
                    Text(author.name)
                        .font(.headline)
                        .foregroundStyle(Color.blue)
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
    TaskView(task: Task.test[0])
}
