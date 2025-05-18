import SwiftUI
import FirebaseAuth
import FirebaseFirestore


struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var message = ""
    @State private var showError = false
    @State private var showSuccess = false
    @State private var isLoggedIn = false

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [.blue.opacity(0.8), .purple]),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                VStack(spacing: 30) {
                    Text("Giriş Yap")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    VStack(spacing: 20) {
                        TextField("E-posta", text: $email)
                            .keyboardType(.emailAddress)
                            .textFieldStyle(.roundedBorder)

                        SecureField("Şifre", text: $password)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding()
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    Button(action: login) {
                        Text("Giriş Yap")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.blue)
                            .cornerRadius(12)
                            .shadow(radius: 3)
                    }
                    .padding(.horizontal)

                    if showError {
                        Text(message)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                            .padding(.horizontal)
                            .transition(.move(edge: .top))
                    }

                    if showSuccess {
                        Text("✅ Giriş başarılı!")
                            .foregroundColor(.green)
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                            .padding(.horizontal)
                            .transition(.scale)
                    }

                    // Programatik yönlendirme
                    NavigationLink(destination: DashboardView(), isActive: $isLoggedIn) {
                        EmptyView()
                    }

                    Spacer()
                }
                .padding(.top, 100)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: showError)
        .animation(.easeInOut(duration: 0.4), value: showSuccess)
    }

    func login() {
        showError = false
        showSuccess = false

        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                self.message = "Hata: \(error.localizedDescription)"
                self.showError = true
            } else {
                self.showSuccess = true

                // 🎯 1 saniye sonra DashboardView'e yönlendir
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.isLoggedIn = true
                }
            }
        }
    }
}
