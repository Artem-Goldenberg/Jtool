import SwiftUI

struct ProfileView: View {
    let profile: Profile

    var body: some View {
        Form {
            HStack {
                Spacer()
                ProfileImageView(image: profile.image)
                    .frame(width: 120, height: 120)
                Spacer()
            }.listRowBackground(Color(UIColor.systemGroupedBackground))
            Section {
                Text("\(profile.email)").bold()
            }
            Section {
                TextField("Name", text: .constant(profile.name))
                TextField("Surname", text: .constant(profile.surname))
            }
            Section {
                Picker("Team", selection: .constant(profile.team)) {
                    ForEach(Profile.availableTeams, id: \.self) {
                        Text($0)
                    }
                }
            }
            Section {
                Picker("Job", selection: .constant(profile.job)) {
                    ForEach(Profile.availableJobs, id: \.self) {
                        Text($0)
                    }
                }
            }
        }.disabled(true)
    } // body
} // RealProfileView
