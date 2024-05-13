import SwiftUI
import UIKit
import FirebaseAuth

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct ContentView: View {
    @State private var isLogged: Bool = false
    var body: some View {
        if isLogged {
            MainView()
        } else {
            LoginView(isLogged: $isLogged)
        }
    }
}

struct LoginView: View {
    enum Field {
        case login
        case password
    }

    @EnvironmentObject var store: EventStore

    @Binding var isLogged: Bool

    @State private var loginFailed = false
    @State private var errorMessage: String?

    @State private var login = "1125@gmail.com"
    @State private var password = "1125password"
    @FocusState private var current: Field?

    var welcome: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Image(systemName: "car.front.waves.up.fill")
                Spacer()
            }.padding(.bottom)
            Text("Welcome to the Jtool")
        }
        .font(.headline)
        .padding(.init(top: 53, leading: 0, bottom: 67, trailing: 0))
    }

    var body: some View {
        Form {
            Section(header: welcome) {
                TextField("Email", text: $login)
                    .focused($current, equals: .login)
                    .textContentType(.emailAddress)
                    .submitLabel(.next)
                    .keyboardType(.emailAddress)
                SecureField("Password", text: $password)
                    .focused($current, equals: .password)
                    .textContentType(.password)
                    .submitLabel(.done)
            }
            Section {
                Button(action: loginUser) {
                    Text("Login")
                        .listRowBackground(Color.blue)
                        .frame(alignment: .center)
                        .font(.headline)
                }
            }
            .disabled(login.isEmpty || password.isEmpty)
            .alert("Login Failed", isPresented: $loginFailed) {
                Button("OK", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "Unkown error")
            }
        }.onSubmit(getNext)
    }

    private func getNext() {
        switch current {
        case .login:
            current = .password
        default:
            guard !login.isEmpty && !password.isEmpty else { return }
            loginUser()
        }
    }

    private func loginUser() {
        Auth.auth().signIn(withEmail: login, password: password) { userData, error in
            if let error = error {
                errorMessage = error.localizedDescription
                loginFailed = true
                return
            }
            guard let email = userData?.user.email else {
                errorMessage = "Unknown User"
                loginFailed = true
                return
            }
            store.setup(for: email)
            withAnimation {
                isLogged = true
            }
        }
    }
}

#Preview {
    LoginView(isLogged: .constant(false))
}
