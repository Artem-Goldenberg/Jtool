import SwiftUI

struct TaskListView: View {
    enum Filter: LocalizedStringKey, Identifiable, CaseIterable {
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
    var stage: Stage

    @State private var search: String = ""
    @State private var filter: Filter = .all
    @State private var showingEdit = false
    @State private var editableTask = EditableTask()
    @State private var showFilters = false

    @EnvironmentObject var store: Store

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
                            .deleteDisabled(!store.canDelete(task: task))
                        }
                        .onDelete(perform: self.delete)
                    }
                    .listStyle(.inset)
                    .frame(minHeight: CGFloat(filtered.count) * 100)
                } // if-else
            } // scrollView
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    filtersView
                }
                if store.canAddTask(to: stage) {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("New Task") {
                            editableTask = .init()
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
                TaskEditView(stage: stage, task: $editableTask)
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

    private var filtered: [Task] {
        let tasks = store.stages.first(with: stage.id)!.tasks
            .filter {
                switch filter {
                case .forMe: $0.assigneeId == store.profile?.id
                case .byMe: $0.authorId == store.profile?.id
                case .all: true
                }
            }
        guard !search.isEmpty else { return tasks }
        return tasks.filter { $0.title.contains(search) }
    }

    private func delete(at offset: IndexSet) {
        Worker {
            await store.delete(in: filtered, at: offset, for: stage)
        }
    }
}
