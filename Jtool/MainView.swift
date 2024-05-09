import SwiftUI

struct MainView: View {
    init() {
//        UITabBar.appearance().isTranslucent = false
        UITabBar.appearance().backgroundColor = #colorLiteral(red: 0.9621028032, green: 0.9621028032, blue: 0.9621028032, alpha: 1)
    }
    @State private var selection = 3
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
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    .padding(40)
                }
                .tag(4)
        }
    }
}

import PhotosUI
import SwiftUI

@available(iOS 16.0, *)
struct PhotosPickerDemo: View {
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil

    var body: some View {
        PhotosPicker(
            selection: $selectedItem,
            matching: .images,
            photoLibrary: .shared()) {
                Text("Select a photo")
            }
            .onChange(of: selectedItem) {
                Worker {
                    // Retrieve selected asset in the form of Data
                    if let data = try? await selectedItem?.loadTransferable(type: Data.self) {
                        selectedImageData = data
                    }
                }
            }

        if let selectedImageData,
           let uiImage = UIImage(data: selectedImageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(width: 250, height: 250)
        }
    }
}

#Preview {
    PhotosPickerDemo()
//    ContentView()
}
