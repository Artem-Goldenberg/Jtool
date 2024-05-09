import SwiftUI

struct MainView: View {
    init() {
        UITabBar.appearance().backgroundColor = #colorLiteral(red: 0.9621028032, green: 0.9621028032, blue: 0.9621028032, alpha: 1)
    }
    @State private var selection = 3
    @State private var profile = ProfileInfo()
    var body: some View {
        TabView(selection: $selection) {
            CalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    .padding(40)
                }
                .tag(1)
            RunView()
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
            ProfileView(info: profile)
                .tabItem {
                    Image(systemName: "person.fill")
                    .padding(40)
                }
                .tag(4)
        }
    }
}

#Preview {
    MainView()
}
