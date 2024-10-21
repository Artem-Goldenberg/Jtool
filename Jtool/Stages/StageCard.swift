import SwiftUI


struct StageCard: View {
    let stage: Stage
    @EnvironmentObject var store: Store

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .firstTextBaseline) {
                Text("Stage #\(stage.number):")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                Text(stage.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(stage.titleColor)
                    .padding(.leading)
            }
            if !stage.tasks.isEmpty {
                HStack(alignment: .firstTextBaseline) {
                    Text("completed: ")
                        .font(.title2)
                        .foregroundStyle(.gray)
                    Text("\(stage.completedCount) / \(stage.tasks.count)")
                        .font(.headline)
                }
            }
            Spacer()
            HStack {
                if store.canFinish(stage: stage) {
                    Button("Finish") {
                        Worker {
                            await store.finish(stage: stage)
                        }
                    }
                    .niceButton()
                }
                Spacer()
                NavigationLink("Tasks") {
                    TaskListView(stage: stage)
                }
                .niceButton()
            }
        } // vstack
        .padding()
    } // body
}

struct StageStatisticView: View {
    let stage: Stage
    @EnvironmentObject var store: Store

    var body: some View {
        VStack(spacing: 15) {
            ForEach(store.users) { user in
                let stats = stage.statistic(for: user)
                Divider()
                HStack {
                    Group {
                        if let image = user.image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                        } else {
                            Image(systemName: "person.fill")
                                .resizable()
                                .foregroundStyle(Color.blue)
                        }
                    }
                    .frame(width: 40, height: 40)
                    .padding()
                    .clipShape(.circle)
                    .padding(.leading)

                    NavigationLink {
                        ProfileView(profile: user)
                    } label: {
                        Text(user.name)
                    }
                    Spacer()

                    VStack {
                        Text(stats.0)
                        Text(stats.1)
                    }

                    Spacer()
                } /// hstack
            } /// foreac
        } /// vstack
    } /// body
}

fileprivate extension Stage {
    func statistic(for user: Profile) -> (LocalizedStringKey, LocalizedStringKey) {
        let tasks = tasks.filter { $0.assigneeId == user.id }
        let completed = tasks.filter { $0.status == .completed }.count
        let overdue = tasks.filter { $0.status == .overdue }.count
        return ("\(completed) completed, \(overdue) overdue", "\(tasks.count) total")
    }
}
