import SwiftUI
import PhotosUI

struct ProfileEditView: View {
    let profile: Profile
    @State private var image: UIImage?
    @State private var state: EditableProfile

    @EnvironmentObject var store: Store

    init(profile: Profile) {
        self.profile = profile
        self._image = State(initialValue: profile.image)
        self._state = State(initialValue: .init(from: profile))
    }

    var body: some View {
        Form {
            ProfileImageEditView(profileId: profile.id, image: $image)
                .listRowBackground(Color(UIColor.systemGroupedBackground))
            Section {
                Text("\(profile.email)").bold()
            }
            Section {
                TextField("Name", text: $state.name)
                TextField("Surname", text: $state.surname)
            }
            Section {
                Picker("Team", selection: $state.team) {
                    ForEach(Profile.availableTeams, id: \.self) {
                        Text($0)
                    }
                }
            }
            Section {
                Picker("Job", selection: $state.job) {
                    ForEach(Profile.availableJobs, id: \.self) {
                        Text($0)
                    }
                }
            }
            Section {
                Button("Confirm") {
                    Worker {
                        await store.upload(profile: state)
                    }
                }.disabled(state == profile)
            }
        } // form
    } // body
}

struct ProfileImageView: View {
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

struct ProfileImageEditView: View {
    let profileId: String
    @Binding var image: UIImage?
    @State private var item: PhotosPickerItem?
    @State private var showPicker = false

    @EnvironmentObject var store: Store

    var body: some View {
        HStack {
            Spacer()
            Button { showPicker = true } label: {
                ProfileImageView(image: image)
                    .frame(width: 100, height: 100)
            }
            Spacer()
        }
        .photosPicker(isPresented: $showPicker, selection: $item)
        .onChange(of: item, load)
    }

    private func load() {
        Worker {
            guard let data = try? await item?.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) 
            else {
                print("Image loading failed")
                return
            }
            self.image = image
            await store.upload(image: image, for: profileId)
        }
    }
}
