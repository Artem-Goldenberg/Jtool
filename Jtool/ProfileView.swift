import SwiftUI
import PhotosUI

struct ProfileView: View {
    @Binding var original: Profile
    var readOnly: Bool
    @State private var info: Profile

    init(info: Binding<Profile>, readOnly: Bool = false) {
        self._original = info
        self._info = State(initialValue: info.wrappedValue)
        self.readOnly = readOnly
    }

    @EnvironmentObject var store: Store

    private var hasChanged: Bool {
        info != original
    }

    var body: some View {
        Form {
            ProfileImage(image: $info.image)
            .listRowBackground(Color(UIColor.systemGroupedBackground))

            Section {
                Text("\(info.email)").bold()
            }

            Section {
                TextField("Name", text: $info.name)
                TextField("Surname", text: $info.surname)
            }

            Section {
                Picker("Team", selection: $info.team) {
                    ForEach(Profile.teams, id: \.self) {
                        Text($0)
                    }
                }
            }

            Section {
                Picker("Job", selection: $info.job) {
                    ForEach(Profile.jobs, id: \.self) {
                        Text($0)
                    }
                }
            }

            if !readOnly {
                Section {
                    Button("Confirm") {
                        Worker { await store.saveProfile() }
                    }.disabled(!hasChanged)
                }
            }
        }.disabled(readOnly)
        
    } // body
} // ProfileView

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
            if let data = try? await item?.loadTransferable(type: Foundation.Data.self) {
                image = UIImage(data: data)
            } else {
                print("Image loading failed")
            }
        }
    }
}

#Preview {
//    ProfileView(info: .constant(.init()))
    ProfileView(info: .constant(.init(name: "Morris", surname: "The Important One", team: "Mobile", job: "Tester")), readOnly: false)
}
