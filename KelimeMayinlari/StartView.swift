import SwiftUI

struct StartView: View {
    @State private var animateTiles: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [.blue, .purple]),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                VStack(spacing: 40) {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            ForEach(["K", "E", "L", "İ", "M", "E"], id: \.self) { letter in
                                tileView(letter: letter, color: Color.yellow.opacity(0.9))
                            }
                        }
                        HStack(spacing: 8) {
                            ForEach(["M", "A", "Y", "I", "N", "L", "A", "R", "I"], id: \.self) { letter in
                                tileView(letter: letter, color: Color.orange.opacity(0.9))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)

                    NavigationLink(destination: RegisterView()
                        .navigationTitle("Kayıt Ol")
                        .navigationBarTitleDisplayMode(.inline)) {
                        Text("Kayıt Ol")
                            .frame(maxWidth: 250)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.blue)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    .scaleEffect(animateTiles ? 1.05 : 1.0)
                    .animation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: animateTiles)

                    NavigationLink(destination: LoginView()
                        .navigationTitle("Giriş Yap")
                        .navigationBarTitleDisplayMode(.inline)) {
                        Text("Giriş Yap")
                            .frame(maxWidth: 250)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.purple)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    .scaleEffect(animateTiles ? 1.05 : 1.0)
                    .animation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: animateTiles)
                }
                .padding(.horizontal)
                .onAppear {
                    animateTiles = true
                }
            }
        }
    }

    @ViewBuilder
    func tileView(letter: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.5))
                .frame(width: 40, height: 50)
                .shadow(color: .black.opacity(0.3), radius: 3, x: 2, y: 2)
            
            VStack(spacing: 2) {
                Text(letter)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
                
                Text(randomPoint(for: letter))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.top, 2)
            }
        }
        .scaleEffect(animateTiles ? 1.05 : 1.0)
        .animation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: animateTiles)
    }
    
    func randomPoint(for letter: String) -> String {
        let points = ["1", "2", "3", "4", "5"]
        return points.randomElement() ?? "1"
    }
}
