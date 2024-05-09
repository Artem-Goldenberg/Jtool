import SwiftUI
import PhotosUI

struct ProfileView: View {
    @State private var info = ProfileInfo()

    var body: some View {
        Form {
            ProfileImage(image: $info.image)
            .listRowBackground(Color(UIColor.systemGroupedBackground))

            Section {
                TextField("Name", text: $info.name)
                TextField("Surname", text: $info.surname)
            }

            Section {
                Picker("Your Team", selection: $info.team) {
                    ForEach(ProfileInfo.teams, id: \.self) {
                        Text($0)
                    }
                }
            }

            Section {
                Picker("Your Job", selection: $info.job) {
                    ForEach(ProfileInfo.jobs, id: \.self) {
                        Text($0)
                    }
                }
            }

            Section {
                Button("Confirm") { }
            }

        }
    }
}

struct DisplayImage: View {
    var image: UIImage?
    var body: some View {
        if let image = image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
        } else {
            ZStack {
                Circle().fill(
                    LinearGradient(
                        colors: [Color(#colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)), .blue],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                Image(systemName: "person.fill")
                    .font(.system(size: 37))
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }
        }
    }
}

struct ProfileImage: View {
    @Binding var image: UIImage?
    @State private var item: PhotosPickerItem?
    @State private var showPicker = false

    var body: some View {
        HStack {
            Spacer()
            Button { showPicker = true } label: {
                DisplayImage(image: image)
                    .frame(width: 100, height: 100)
            }
            Spacer()
        }
        .photosPicker(isPresented: $showPicker, selection: $item)
        .onChange(of: item, load)
    }

    private func load() {
        Worker {
            if let data = try? await item?.loadTransferable(type: Data.self) {
                image = UIImage(data: data)
            } else {
                print("Image loading failed")
            }
        }
    }
}

#Preview {
    ProfileView()
}
