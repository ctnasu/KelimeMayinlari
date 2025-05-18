import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RegisterView: View {
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var message = ""
    @State private var showError = false
    @State private var showSuccess = false

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [.purple.opacity(0.9), .blue]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Text("Kayıt Ol")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                VStack(spacing: 20) {
                    TextField("Kullanıcı Adı", text: $username)
                        .textFieldStyle(.roundedBorder)

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

                Button("Kayıt Ol") {
                    register()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .foregroundColor(.blue)
                .cornerRadius(12)
                .shadow(radius: 3)
                .padding(.horizontal)

                if showError {
                    Text(message)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                        .padding(.horizontal)
                }

                if showSuccess {
                    Text("✅ Kayıt başarılı!")
                        .foregroundColor(.green)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.top, 100)
        }
        .animation(.easeInOut(duration: 0.4), value: showError)
        .animation(.easeInOut(duration: 0.4), value: showSuccess)
    }

    func register() {
        showError = false
        showSuccess = false

        let passwordValid = password.count >= 8 &&
                            password.range(of: "[A-Z]", options: .regularExpression) != nil &&
                            password.range(of: "[a-z]", options: .regularExpression) != nil &&
                            password.range(of: "[0-9]", options: .regularExpression) != nil

        guard passwordValid,
              email.contains("@"),
              !username.isEmpty else {
            message = "Şifre büyük/küçük harf ve rakam içermeli, diğer alanlar boş olmamalı."
            showError = true
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                message = "Hata: \(error.localizedDescription)"
                showError = true
            } else if let user = result?.user {
                let db = Firestore.firestore()
                let userData: [String: Any] = [
                    "username": username,
                    "email": email,
                    "totalGames": 0,
                    "wonGames": 0,
                    "successRate": 0.0
                ]

                db.collection("users").document(user.uid).setData(userData) { error in
                    if let error = error {
                        message = "Firestore hatası: \(error.localizedDescription)"
                        showError = true
                    } else {
                        showSuccess = true
                    }
                }
            }
        }
    }
}
