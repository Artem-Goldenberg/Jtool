import SwiftUI

struct MainView: View {
    init() {
        UITabBar.appearance().backgroundColor = UIColor.systemBackground
    }

    @State private var selection = 3

    @EnvironmentObject var store: Store

    var body: some View {
        TabView(selection: $selection) {
            CalendarView()
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
            TaskListView()
                .tabItem {
                    Image(systemName: "list.bullet.rectangle")
                    .padding(40)
                }
                .tag(3)
            ProfileView(info: $store.profile)
                .tabItem {
                    Image(systemName: "person.fill")
                    .padding(40)
                }
                .tag(4)
        }
        .onAppear {
            Worker { await store.load(for: "1125@gmail.com") }
        }
        .alert("Firebase Errors", isPresented: $store.hasError) {
            Button("OK", role: .cancel) {
                store.hasError = false
                store.errorMessage = nil
            }
            Button("Retry") {
                store.hasError = false
                store.errorMessage = nil
                Worker { await store.load(for: "1125@gmail.com") }
            }
        } message: {
            Text(store.errorMessage ?? "Unknown error")
        }
    }
}

#Preview {
    MainView()
}
