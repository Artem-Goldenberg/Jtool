import SwiftUI

struct ProfileView: View {
    let profile: Profile
    @EnvironmentObject var store: EventStore

    var body: some View {
        Form {
            HStack {
                Spacer()
                ProfileImageView(image: profile.image)
                    .frame(width: 180, height: 180)
                Spacer()
            }.listRowBackground(Color(UIColor.systemGroupedBackground))
            Section {
                Text("\(profile.email)").bold()
            }
            Section {
                TextField("Name", text: .constant(profile.name))
                TextField("Surname", text: .constant(profile.surname))
            }
//            Section {
//                Picker("Team", selection: .constant(profile.team)) {
//                    ForEach(Profile.availableTeams, id: \.self) {
//                        Text($0)
//                    }
//                }
//            }
            Section {
                Picker("Job", selection: .constant(profile.job)) {
                    ForEach(store.allJobs, id: \.self) {
                        Text($0)
                    }
                }
            }
        }.disabled(true)
    } // body
} // RealProfileView
