import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct DashboardView: View {
    @State private var username = ""
    @State private var successRate: Double = 0.0
    @State private var showGameOptions = false
    @State private var selectedDuration = ""
    @State private var matchedGameId: String = ""
    @State private var navigateToGame = false
    @State private var showActiveGames = false
    @State private var player1Username: String = ""
    @State private var player2Username: String = ""
    @State private var showFinishedGames = false
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                VStack(spacing: 20) {
                    Text("Hoş geldin, \(username)")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .bold()

                    Text("Başarı Yüzdesi: %\(String(format: "%.1f", successRate))")
                        .font(.title2)
                        .foregroundColor(.white)

                    Spacer()

                    Button("Yeni Oyun") {
                        showGameOptions = true
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(12)
                    .foregroundColor(.blue)
                    .font(.headline)
                    .padding(.horizontal)

                    Button("Aktif Oyunlar") {
                        showActiveGames = true
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(12)
                    .foregroundColor(.blue)
                    .font(.headline)
                    .padding(.horizontal)

                    Button("Biten Oyunlar") {
                        showFinishedGames = true
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(12)
                    .foregroundColor(.blue)
                    .font(.headline)
                    .padding(.horizontal)

                    Spacer()

                    NavigationLink(destination: GameBoardView(gameID: matchedGameId), isActive: $navigateToGame) {
                        EmptyView()
                    }
                    NavigationLink(destination: ActiveGamesView(), isActive: $showActiveGames) {
                        EmptyView()
                    }
                    NavigationLink(destination: FinishedGamesView(), isActive: $showFinishedGames) {
                        EmptyView()
                    }
                }
                .padding()
            }
            .onAppear(perform: fetchUserStats)
            .sheet(isPresented: $showGameOptions) {
                NewGamesView { selected in
                    showGameOptions = false
                    selectedDuration = selected
                    findOrCreateMatch(duration: selected) { gameId in
                        DispatchQueue.main.async {
                            if let id = gameId {
                                matchedGameId = id
                                navigateToGame = true
                            }
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    
    func fetchUserStats() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { document, error in
            if let data = document?.data() {
                self.username = data["username"] as? String ?? ""
                let total = (data["totalGames"] as? Double) ?? Double(data["totalGames"] as? Int ?? 0)
                let won = (data["wonGames"] as? Double) ?? Double(data["wonGames"] as? Int ?? 0)
                let rate = total > 0 ? (won / total) * 100 : 0
                self.successRate = rate
                db.collection("users").document(uid).updateData(["successRate": rate])
            }
        }
    }

    func findOrCreateMatch(duration: String, completion: @escaping (String?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("Kullanıcı oturum açmamış!")
            return
        }
        let db = Firestore.firestore()

        let durationInSeconds: Int
        switch duration {
        case "2dk": durationInSeconds = 120
        case "5dk": durationInSeconds = 300
        case "12s": durationInSeconds = 43200
        case "24s": durationInSeconds = 86400
        default: durationInSeconds = 120
        }

        let initialLetterPool: [String: Int] = [
            "A": 12, "B": 2, "C": 2, "Ç": 2, "D": 2, "E": 8, "F": 1, "G": 1, "Ğ": 1,
            "H": 1, "I": 4, "İ": 7, "J": 1, "K": 7, "L": 7, "M": 4, "N": 5, "O": 3,
            "Ö": 1, "P": 1, "R": 6, "S": 3, "Ş": 2, "T": 5, "U": 3, "Ü": 2, "V": 1,
            "Y": 2, "Z": 2, "*": 2
        ]

        print("Eşleşme aranıyor - Kullanıcı: \(uid), Süre: \(duration)")

        db.collection("matchQueue")
            .whereField("duration", isEqualTo: duration)
            .order(by: "timestamp")
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    print(" Firestore getDocuments hatası: \(error.localizedDescription)")
                    completion(nil)
                    return
                }

                if let document = snapshot?.documents.first {
                    let opponentId = document["userId"] as? String ?? ""
                    print("Kuyruktaki rakip: \(opponentId)")

                    if opponentId != uid {
                        db.collection("matchQueue").document(document.documentID).delete()

                        let gameId = UUID().uuidString
                        db.collection("games").document(gameId).setData([
                            "player1": uid,
                            "player2": opponentId,
                            "duration": durationInSeconds,
                            "createdAt": FieldValue.serverTimestamp(),
                            "currentTurn": Bool.random() ? uid : opponentId,
                            "status": "active",
                            "startTime": FieldValue.serverTimestamp(),
                            "letterPool": initialLetterPool,
                            "player1PassCount": 0,
                            "player2PassCount": 0
                        ]) { err in
                            if let err = err {
                                print("Oyun oluşturulamadı: \(err.localizedDescription)")
                                completion(nil)
                            } else {
                                print("Oyun oluşturuldu: \(gameId)")
                                completion(gameId)
                            }
                        }
                        return
                    } else {
                        print("Aynı kullanıcı kuyruğun başında, eşleşme yapılmadı.")
                    }
                }

                db.collection("matchQueue").addDocument(data: [
                    "userId": uid,
                    "duration": duration,
                    "timestamp": FieldValue.serverTimestamp()
                ]) { error in
                    if let error = error {
                        print(" Kuyruğa eklenemedi: \(error.localizedDescription)")
                    } else {
                        print("Kuyruğa eklendi ve bekliyor: \(uid)")
                    }
                    completion(nil)
                }
            }
    }
    
    
    
    
}

struct GameDurationSelection: View {
    var onSelect: (String) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Oyun Süresi Seç")
                .font(.title2)
                .bold()

            Button("2 Dakika (Hızlı)") { onSelect("2dk") }
            Button("5 Dakika (Hızlı)") { onSelect("5dk") }
            Button("12 Saat (Genişletilmiş)") { onSelect("12s") }
            Button("24 Saat (Genişletilmiş)") { onSelect("24s") }
        }
        .padding()
    }
}

struct ActiveGamesView: View {
    @Environment(\.dismiss) var dismiss
    @State private var games: [QueryDocumentSnapshot] = []
    @State private var uid = Auth.auth().currentUser?.uid ?? ""
    @State private var selectedGameId: String? = nil

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack {
                Text("Aktif Oyunlar")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white)
                    .padding()
                
                List(games, id: \.documentID) { game in
                    Button(action: {
                        selectedGameId = game.documentID
                    }) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Rakip: \(opponentName(from: game))")
                                .font(.headline)
                                .foregroundColor(.blue)
                            Text("Sıra: \(currentTurnText(for: game))")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text("Puanlar - Sen: \(myScore(from: game)) / Rakip: \(opponentScore(from: game))")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                    }
                    .listRowBackground(Color.clear)
                }
                .listStyle(PlainListStyle())
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Label("Geri", systemImage: "chevron.left")
                }
            }
        }
        .onAppear(perform: fetchGames)
        NavigationLink(
            destination: GameBoardView(gameID: selectedGameId ?? ""),
            isActive: Binding<Bool>(
                get: { selectedGameId != nil },
                set: { if !$0 { selectedGameId = nil } }
            )
        ) {
            EmptyView()
        }
    }

    func fetchGames() {
        let db = Firestore.firestore()
        db.collection("games")
            .whereField("status", isEqualTo: "active")
            .whereFilter(Filter.orFilter([
                Filter.whereField("player1", isEqualTo: uid),
                Filter.whereField("player2", isEqualTo: uid)
            ]))
            .getDocuments { snapshot, error in
                if let documents = snapshot?.documents {
                    self.games = documents
                }
            }
    }

    func opponentName(from game: QueryDocumentSnapshot) -> String {
        let player1 = game["player1"] as? String ?? ""
        let player2 = game["player2"] as? String ?? ""
        return uid == player1 ? player2 : player1
    }

    func currentTurnText(for game: QueryDocumentSnapshot) -> String {
        let currentTurn = game["currentTurn"] as? String ?? ""
        return currentTurn == uid ? "Sende" : "Rakipte"
    }

    func myScore(from game: QueryDocumentSnapshot) -> Int {
        let player1 = game["player1"] as? String ?? ""
        return uid == player1 ? (game["player1Score"] as? Int ?? 0) : (game["player2Score"] as? Int ?? 0)
    }

    func opponentScore(from game: QueryDocumentSnapshot) -> Int {
        let player1 = game["player1"] as? String ?? ""
        return uid == player1 ? (game["player2Score"] as? Int ?? 0) : (game["player1Score"] as? Int ?? 0)
    }
}

struct NewGamesView: View {
    var onSelect: (String) -> Void

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Oyun Süresi Seç")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white)
                    .padding()

                Button("2 Dakika (Hızlı)") { onSelect("2dk") }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(12)
                    .foregroundColor(.blue)
                    .font(.headline)
                    .padding(.horizontal)

                Button("5 Dakika (Hızlı)") { onSelect("5dk") }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(12)
                    .foregroundColor(.blue)
                    .font(.headline)
                    .padding(.horizontal)

                Button("12 Saat (Genişletilmiş)") { onSelect("12s") }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(12)
                    .foregroundColor(.blue)
                    .font(.headline)
                    .padding(.horizontal)

                Button("24 Saat (Genişletilmiş)") { onSelect("24s") }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(12)
                    .foregroundColor(.blue)
                    .font(.headline)
                    .padding(.horizontal)
            }
            .padding()
        }
    }
}

struct FinishedGamesView: View {
    @Environment(\.dismiss) var dismiss
    @State private var games: [QueryDocumentSnapshot] = []
    @State private var uid = Auth.auth().currentUser?.uid ?? ""
    @State private var selectedGameId: String? = nil

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack {
                Text("Biten Oyunlar")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white)
                    .padding()
                
                List(games, id: \.documentID) { game in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Rakip: \(opponentName(from: game))")
                            .font(.headline)
                            .foregroundColor(.blue)
                        Text("Senin Puanın: \(myScore(from: game))")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text("Rakibin Puanı: \(opponentScore(from: game))")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(10)
                    .listRowBackground(Color.clear)
                }
                .listStyle(PlainListStyle())
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Label("Geri", systemImage: "chevron.left")
                }
            }
        }
        .onAppear(perform: fetchGames)
    }

    func fetchGames() {
        let db = Firestore.firestore()
        db.collection("games")
            .whereField("status", isEqualTo: "finished")
            .whereFilter(Filter.orFilter([
                Filter.whereField("player1", isEqualTo: uid),
                Filter.whereField("player2", isEqualTo: uid)
            ]))
            .getDocuments { snapshot, error in
                if let documents = snapshot?.documents {
                    self.games = documents
                }
            }
    }

    func opponentName(from game: QueryDocumentSnapshot) -> String {
        let player1 = game["player1"] as? String ?? ""
        let player2 = game["player2"] as? String ?? ""
        return uid == player1 ? player2 : player1
    }

    func myScore(from game: QueryDocumentSnapshot) -> Int {
        let player1 = game["player1"] as? String ?? ""
        return uid == player1 ? (game["player1Score"] as? Int ?? 0) : (game["player2Score"] as? Int ?? 0)
    }

    func opponentScore(from game: QueryDocumentSnapshot) -> Int {
        let player1 = game["player1"] as? String ?? ""
        return uid == player1 ? (game["player2Score"] as? Int ?? 0) : (game["player1Score"] as? Int ?? 0)
    }
}
