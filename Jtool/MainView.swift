import SwiftUI

struct MainView: View {
    init() {
        UITabBar.appearance().backgroundColor = UIColor.systemBackground
    }

    @State private var selection = 3
    @EnvironmentObject var store: EventStore

    var body: some View {
        TabView(selection: $selection) {
            EventsView()
            .tabItem {
                Image(systemName: "calendar")
                    .padding(40)
            }
            .tag(1)
            StageView()
                .tabItem {
                    Image(systemName: "figure.run")
                    .padding(40)
                }
                .tag(2)
                .environmentObject(store as Store)
            Group {
                if let stage = store.stage {
                    TaskListView(stage: stage)
                } else {
                    ContentUnavailableView(
                        "This stage's tasks haven't loaded yet, wait a bit",
                        systemImage: "figure.jumprope"
                    )
                }
            }
            .tabItem {
                Image(systemName: "list.bullet.rectangle")
                    .padding(40)
            }
            .tag(3)
            .environmentObject(store as Store)
            Group {
                if let profile = store.profile {
                    ProfileEditView(profile: profile)
                } else {
                    ContentUnavailableView("Profile hasn't not loaded yet", systemImage: "figure.walk.motion.trianglebadge.exclamationmark")
                }
            }
            .tabItem {
                Image(systemName: "person.fill")
                    .padding(40)
            }
            .tag(4)
            .environmentObject(store as Store)
        }
        .onAppear {
            // TODO: remove
//            store.setup(for: "1125@gmail.com")
            Worker {
                await store.loadAll()
            }
        }
        .alert("Firebase Error", isPresented: $store.hasError) {
            Button("Retry") {
                store.hasError = false
                store.errorMessage = nil
                Worker { await store.loadStages() }
            }
            Button("OK", role: .cancel) {
                store.hasError = false
                store.errorMessage = nil
            }
        } message: {
            Text(store.errorMessage ?? "Unknown error")
        }
    }
}

#Preview {
    MainView()
}
