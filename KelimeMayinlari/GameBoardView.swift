import SwiftUI
import FirebaseFirestore
import FirebaseAuth

enum MineType: String {
    case scoreSplit, scoreTransfer, loseLetter, blockExtraMove, cancelWord, regionBan
}

enum RewardType: String {
    case extraMoveJoker, letterBan, wildcard
}

struct Position: Hashable {
    let row: Int
    let col: Int
}

struct Tile {
    var letter: String
    var multiplier: Multiplier
    var mine: MineType? = nil
    var reward: RewardType? = nil
}

enum Multiplier: String, Codable {
    case none, h2, h3, k2, k3

    var color: Color {
        switch self {
        case .h2: return Color.blue.opacity(0.4)
        case .h3: return Color.purple.opacity(0.4)
        case .k2: return Color.green.opacity(0.4)
        case .k3: return Color.brown.opacity(0.4)
        default: return Color.white
        }
    }

    var label: String {
        switch self {
        case .h2: return "H²"
        case .h3: return "H³"
        case .k2: return "K²"
        case .k3: return "K³"
        default: return ""
        }
    }
}

struct GameLetter: Identifiable, Hashable {
    let id = UUID()
    let letter: String
    var count: Int
}

struct GameBoardView: View {
    let gameID: String

    @State private var board: [[Tile]] = Array(repeating: Array(repeating: Tile(letter: "", multiplier: .none), count: 15), count: 15)
    @State private var userLetters: [GameLetter] = []
    @State private var selectedLetter: String? = nil
    @State private var infoMessage: String? = nil

    @State private var player1: String = ""
    @State private var player2: String = ""
    @State private var turn: String = ""
    @State private var uid: String = Auth.auth().currentUser?.uid ?? ""

    @State private var player1Score: Int = 0
    @State private var player2Score: Int = 0

    @State private var remainingTime: Int = 0
    @State private var timer: Timer? = nil

    @State private var player1Username: String = ""
    @State private var player2Username: String = ""

    @State private var isFirstMove: Bool = true
    @State private var selectedMoveFrom: (row: Int, col: Int)? = nil
    @State private var currentWord: String = ""
    @State private var validWords: Set<String> = []
    
    @State private var selectedPosition: (row: Int, col: Int)? = nil
    
    @State private var firstMoveDone = false
    
    @State private var selectedFromPosition: (row: Int, col: Int)? = nil
    @State private var activeMine: MineType? = nil
    @State private var showMinesDebug: Bool = false

    @State private var canDrawLetters = true
    @State private var bannedTiles: Set<Position> = []
    @State private var jokerReplacement: String? = nil

    @State private var showJokerPrompt: Bool = false
    @State private var pendingJokerPosition: (row: Int, col: Int)? = nil

    @State private var isGameFinished: Bool = false
    @State private var mineTriggeredCount: Int = 0

    @State private var earnedRewards: [RewardType] = []
    @State private var showRewardButtons: Bool = false
    
var body: some View {
    ScrollView {
        VStack(spacing: 10) {
            playerInfoSection
            timerSection
            HStack {
                Spacer()
                Button(action: { showMinesDebug.toggle() }) {
                    Text(showMinesDebug ? "Mayınları Gizle" : "Mayınları Göster")
                        .font(.caption)
                        .padding(4)
                        .background(Color.black.opacity(0.5))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
            }
            .padding(.horizontal)
            boardSection
            if let msg = infoMessage {
                Text(msg)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(8)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            infoMessage = nil
                        }
                    }
            }
            if !currentWord.isEmpty {
                VStack {
                    Text(currentWord)
                        .foregroundColor(isCurrentWordValid ? .green : .red)
                        .font(.title2)
                    Text("Toplam Puan: \(calculateWordScore(word: currentWord))")
                        .font(.subheadline)
                }
                .padding()
            }
            lettersSection
            if showRewardButtons {
                HStack {
                    ForEach(earnedRewards, id: \.self) { reward in
                        Button(action: {
                            activateReward(reward)
                        }) {
                            Image(systemName: rewardIconName(for: reward))
                                .resizable()
                                .frame(width: 40, height: 40)
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                    }
                }
                .padding()
            }
        }
        .padding()
    }
    .alert("Joker Harf Seçimi", isPresented: $showJokerPrompt) {
        let letters = ["A","B","C","Ç","D","E","F","G","Ğ","H","I","İ","J","K","L","M","N","O","Ö","P","R","S","Ş","T","U","Ü","V","Y","Z"]
        ForEach(letters, id: \.self) { letter in
            Button(letter) {
                if let pos = pendingJokerPosition {
                    board[pos.row][pos.col].letter = letter
                    selectedPosition = pos
                    if let fullWord = extractWordsAround(row: pos.row, col: pos.col).first {
                        currentWord = fullWord
                    } else {
                        currentWord = ""
                    }
                    selectedLetter = nil
                    pendingJokerPosition = nil
                }
            }
        }
        Button("İptal", role: .cancel) {
            showJokerPrompt = false
            pendingJokerPosition = nil
        }
    } message: {
        Text("Joker harfi yerine hangi harfi kullanmak istiyorsunuz?")
    }
    .onAppear {
        initializeUserStatsIfNeeded()
        setupInitialMultipliers()
        listenGameUpdates()
        loadUserLetters()
        loadValidWords()
        populateMinesAndRewards()
    }
    .sheet(isPresented: $isGameFinished) {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.pink.opacity(0.8), Color.purple.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("🏁 Oyun Bitti")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 30)
                    .onAppear {
                        updateUserStatsIfGameFinishedAndWon()
                    }

                VStack(spacing: 12) {
                    Text("Toplam Puanınız: \(uid == player1 ? player1Score : player2Score)")
                    Text("Rakip Puanı: \(uid == player1 ? player2Score : player1Score)")
                    Text("Elinizdeki Harf Sayısı: \(userLetters.reduce(0) { $0 + $1.count })")

                    if let mine = activeMine {
                        Text("Mayına Basıldı: \(mine.rawValue)")
                            .foregroundColor(.red)
                    } else {
                        Text("Mayına Basılmadı")
                    }
                    Text("Toplam Mayın Sayısı: \(mineTriggeredCount)")
                        .foregroundColor(.white)
                }
                .font(.title3)
                .foregroundColor(.white)
                .padding()

                Divider()
                    .background(Color.white)

                if (player1Score == player2Score) {
                    Text("🤝 Oyun Berabere")
                        .font(.title2)
                        .foregroundColor(.yellow)
                } else if (uid == player1 && player1Score > player2Score) || (uid == player2 && player2Score > player1Score) {
                    Text("🎉 Tebrikler, Kazandınız!")
                        .font(.title)
                        .foregroundColor(.green)
                } else {
                    Text("😞 Kaybettiniz.")
                        .font(.title)
                        .foregroundColor(.red)
                }

                Spacer()

                Button(action: {
                    isGameFinished = false
                }) {
                    Text("Ana Sayfaya Dön")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.9))
                        .foregroundColor(.black)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                .padding(.bottom, 30)
            }
            .padding()
        }
    }
}
    
    
    var isCurrentWordValid: Bool {
            validWords.contains(currentWord.lowercased())
        }
    
   

    var playerInfoSection: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Sen: \(uid == player1 ? player1Username : player2Username)")
                Text("Puan: \(uid == player1 ? player1Score : player2Score)")
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("Rakip: \(uid == player1 ? player2Username : player1Username)")
                Text("Puan: \(uid == player1 ? player2Score : player1Score)")
            }
        }
    }

    var timerSection: some View {
        VStack {
            Text("Sıra: \(turn == uid ? "Sende" : "Rakipte")")
                .foregroundColor(turn == uid ? .green : .red)
            Text("Kalan Süre: \(remainingTime) saniye")
                .foregroundColor(.blue)
                .bold()
        }
    }

    var boardSection: some View {
        GeometryReader { geometry in
            let cellSize = geometry.size.width / 15
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellSize), spacing: 0), count: 15), spacing: 0) {
                ForEach(0..<15*15, id: \.self) { index in
                    let row = index / 15
                    let col = index % 15
                    let tile = board[row][col]

                    ZStack {
                        Rectangle()
                            .fill(tile.multiplier.color)
                            .frame(width: cellSize, height: cellSize)
                            .border(Color.gray, width: 0.5)
                        if tile.letter.isEmpty {
                            if row == 7 && col == 7 {
                                Image(systemName: "star.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(.orange)
                            } else {
                                Text(tile.multiplier.label)
                                    .font(.caption2)
                                    .foregroundColor(.black)
                            }
                        } else {
                            Text(tile.letter)
                                .font(.system(size: 14, weight: .bold))
                        }
                        if showMinesDebug, let mineType = tile.mine {
                            switch mineType {
                            case .scoreSplit:
                                Text("Bölünme")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(2)
                                    .background(Color.red.opacity(0.7))
                                    .cornerRadius(4)
                            case .scoreTransfer:
                                Text("Transfer")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(2)
                                    .background(Color.red.opacity(0.7))
                                    .cornerRadius(4)
                            case .loseLetter:
                                Text("Harf Kaybı")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(2)
                                    .background(Color.red.opacity(0.7))
                                    .cornerRadius(4)
                            case .blockExtraMove:
                                Text("Engelle")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(2)
                                    .background(Color.red.opacity(0.7))
                                    .cornerRadius(4)
                            case .cancelWord:
                                Text("İptal")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(2)
                                    .background(Color.red.opacity(0.7))
                                    .cornerRadius(4)
                            case .regionBan:
                                Text("Yasak")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(2)
                                    .background(Color.red.opacity(0.7))
                                    .cornerRadius(4)
                            }
                        }
                        if showMinesDebug, let reward = tile.reward {
                            let iconName: String = {
                                switch reward {
                                case .letterBan:
                                    return "nosign"
                                case .extraMoveJoker:
                                    return "plus.circle"
                                case .wildcard:
                                    return "star.circle"
                                }
                            }()
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Image(systemName: iconName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: cellSize * 0.4, height: cellSize * 0.4)
                                        .foregroundColor(.green)
                                        .background(Color.white.opacity(0.6))
                                        .clipShape(Circle())
                                        .padding(2)
                                }
                            }
                            .frame(width: cellSize, height: cellSize)
                            .zIndex(1)
                        }
                    }
                    .onTapGesture {
                        if turn == uid && selectedLetter != nil {
                            if board[row][col].letter.isEmpty {
                                if isBoardEmpty() {
                                    if row == 7 && col == 7 {
                                        if selectedLetter == "*" {
                                            pendingJokerPosition = (row, col)
                                            showJokerPrompt = true
                                        } else {
                                            placeLetter(row: row, col: col)
                                        }
                                    } else {
                                        print("İlk harf 8,8'e konulmalı!")
                                    }
                                } else {
                                    if isAdjacentToLetter(row: row, col: col) {
                                        if selectedLetter == "*" {
                                            pendingJokerPosition = (row, col)
                                            showJokerPrompt = true
                                        } else {
                                            placeLetter(row: row, col: col)
                                        }
                                    } else {
                                        print("Yeni harf, tahtadaki mevcut bir harfe komşu olmalı!")
                                    }
                                }
                            } else {
                                print("Seçilen kare dolu!")
                            }
                        } else if turn == uid && selectedLetter == nil {
                            if let from = selectedMoveFrom {
                                // İkinci kare seçildi → taşı
                                moveLetter(from: from, to: (row, col))
                                selectedMoveFrom = nil
                            } else {
                                // İlk kare seçildi → harf var mı kontrol et
                                if !board[row][col].letter.isEmpty {
                                    selectedMoveFrom = (row, col)
                                    print("Taşıma için seçilen harf konumu: \(row), \(col)")
                                }
                            }
                        }
                    }
                }
            }
        }
        .frame(height: 400)
    }

    var lettersSection: some View {
            VStack(alignment: .center) {
                Text("Harfleriniz:")
                    .font(.headline)
                    .padding(.top)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(userLetters) { letter in
                            VStack {
                                Text(letter.letter)
                                    .font(.title2)
                                    .frame(width: 50, height: 50)
                                    .background(selectedLetter == letter.letter ? Color.blue.opacity(0.6) : Color.gray.opacity(0.3))
                                    .cornerRadius(8)
                                    .onTapGesture {
                                        selectedLetter = letter.letter
                                    }

                                Text("x\(letter.count)")
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                HStack(spacing: 15) {
                    Button("Onayla") {
                        confirmMove()
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(turn != uid || selectedLetter != nil || !isCurrentWordValid)

                    Button("Pas Geç") {
                        passTurn()
                    }
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(turn != uid)

                    Button("Teslim Ol") {
                        surrender()
                    }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(turn != uid)
                }
                .padding(.top)
            }
        }
    
    
    
    func surrender() {
        let db = Firestore.firestore()
        let gameRef = db.collection("games").document(gameID)

        let winnerID = (uid == player1) ? player2 : player1
        let loserID = uid

        if uid == player1 {
            player1Score = 0
        } else {
            player2Score = 0
        }

        gameRef.updateData([
            "isFinished": true,
            "status": "finished",
            "winner": winnerID,
            "loser": loserID,
            "player1Score": player1Score,
            "player2Score": player2Score
        ]) { error in
            if let error = error {
                print("Teslim olma sırasında hata: \(error.localizedDescription)")
            } else {
                print("Oyun teslimiyetle bitirildi.")
                isGameFinished = true
            }
        }
    }

    
    func passTurn() {
        let db = Firestore.firestore()
        let gameRef = db.collection("games").document(gameID)

        gameRef.getDocument { snapshot, error in
            guard let data = snapshot?.data() else { return }

            var player1PassCount = data["player1PassCount"] as? Int ?? 0
            var player2PassCount = data["player2PassCount"] as? Int ?? 0

            if uid == player1 && player1PassCount >= 2 {
                print("En fazla 2 kez pas geçebilirsiniz!")
                return
            }

            if uid == player2 && player2PassCount >= 2 {
                print("En fazla 2 kez pas geçebilirsiniz!")
                return
            }

            // Geçerli pas - sayaç arttır
            if uid == player1 {
                player1PassCount += 1
            } else {
                player2PassCount += 1
            }

            gameRef.updateData([
                "player1PassCount": player1PassCount,
                "player2PassCount": player2PassCount
            ])

            // Normal geçiş
            currentWord = ""
            selectedLetter = nil
            selectedPosition = nil
            switchTurn()
            saveBoard()
            let usedCount = 7 - userLetters.reduce(0) { $0 + $1.count }
            drawLetters(count: usedCount)
        }
    }

    
    
    func setupInitialMultipliers() {
        let h2: [(Int, Int)] = [(0,3), (0,11), (2,6), (2,8), (3,0), (3,7), (3,14), (6,2), (6,6), (6,8), (6,12), (7,3), (7,11), (8,2), (8,6), (8,8), (8,12), (11,0), (11,7), (11,14), (12,6), (12,8), (14,3), (14,11)]
        let h3: [(Int, Int)] = [(1,5), (1,9), (5,1), (5,13), (9,1), (9,13), (13,5), (13,9)]
        let k2: [(Int, Int)] = [(1,1), (2,2), (3,3), (4,4), (10,10), (11,11), (12,12), (13,13)]
        let k3: [(Int, Int)] = [(0,0), (0,14), (14,0), (14,14)]

        for (r, c) in h2 { board[r][c].multiplier = .h2 }
        for (r, c) in h3 { board[r][c].multiplier = .h3 }
        for (r, c) in k2 { board[r][c].multiplier = .k2 }
        for (r, c) in k3 { board[r][c].multiplier = .k3 }
    }

    func listenGameUpdates() {
        Firestore.firestore().collection("games").document(gameID).addSnapshotListener { snapshot, error in
            guard let data = snapshot?.data() else { return }

            self.player1 = data["player1"] as? String ?? ""
            self.player2 = data["player2"] as? String ?? ""
            self.turn = data["currentTurn"] as? String ?? ""
            self.player1Score = data["player1Score"] as? Int ?? 0
            self.player2Score = data["player2Score"] as? Int ?? 0

            fetchUsername(for: self.player1) { username in
                self.player1Username = username
            }
            fetchUsername(for: self.player2) { username in
                self.player2Username = username
            }

            if let boardString = data["board"] as? String,
               let boardData = boardString.data(using: .utf8),
               let boardArray = try? JSONSerialization.jsonObject(with: boardData) as? [[String]] {
                for i in 0..<15 {
                    for j in 0..<15 {
                        board[i][j].letter = boardArray[i][j]
                    }
                }
            }

            if timer == nil, let duration = data["duration"] as? Int, let startTimestamp = data["startTime"] as? Timestamp {
                startTimer(startDate: startTimestamp.dateValue(), duration: duration)
            }

            // --- Oyun bitişini kontrol et
            if let status = data["status"] as? String, status == "finished" {
                self.isGameFinished = true
            } else if let isFinished = data["isFinished"] as? Bool, isFinished == true {
                self.isGameFinished = true
            }
            // --- Hamle süresi aşımı kontrolü
            else if let duration = data["duration"] as? Int, let startTimestamp = data["startTime"] as? Timestamp {
                let elapsed = Int(Date().timeIntervalSince(startTimestamp.dateValue()))
                if elapsed > duration {
                    let gameRef = Firestore.firestore().collection("games").document(gameID)
                    let didPlayerMove: Bool = {
                        if let boardStr = data["board"] as? String {
                            return boardStr != "[]" && !boardStr.isEmpty
                        }
                        return false
                    }()
                    let loserID = turn
                    let winnerID = (turn == player1) ? player2 : player1
                    if !didPlayerMove {
                        gameRef.updateData([
                            "status": "finished",
                            "isFinished": true,
                            "winner": winnerID,
                            "loser": loserID,
                            "player1Score": player1Score,
                            "player2Score": player2Score
                        ])
                        self.isGameFinished = true
                    }
                }
            }
        }
    }
    
    
    func moveLetter(from: (Int, Int), to: (Int, Int)) {
        guard !isGameFinished else { return }
        let (fromRow, fromCol) = from
        let (toRow, toCol) = to

        guard turn == uid else {
            print("Sıra sizde değil.")
            return
        }

        guard abs(toRow - fromRow) <= 1 && abs(toCol - fromCol) <= 1 else {
            print("Sadece bir birim hareket edebilirsiniz.")
            return
        }

        guard !board[fromRow][fromCol].letter.isEmpty else {
            print("Taşımak istediğiniz yerde harf yok.")
            return
        }

        guard board[toRow][toCol].letter.isEmpty else {
            print("Hedef konum dolu.")
            return
        }

        board[toRow][toCol].letter = board[fromRow][fromCol].letter
        board[fromRow][fromCol].letter = ""

        currentWord = ""
        selectedLetter = nil
        selectedPosition = nil
        switchTurn()
        saveBoard()
    }

    func fetchUsername(for uid: String, completion: @escaping (String) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { document, error in
            if let data = document?.data(), let username = data["username"] as? String {
                completion(username)
            } else {
                completion(uid) // fallback
            }
        }
    }

    func loadUserLetters() {
        let db = Firestore.firestore()
        db.collection("games").document(gameID).getDocument { snapshot, error in
            guard let data = snapshot?.data(),
                  var pool = data["letterPool"] as? [String: Int] else {
                print("Harf havuzu bulunamadı veya boş.")
                return
            }

            if userLetters.reduce(0, { $0 + $1.count }) < 7 {
                var lettersNeeded = 7 - userLetters.reduce(0) { $0 + $1.count }
                var newLetters: [GameLetter] = []

                while lettersNeeded > 0, let letter = pool.keys.filter({ (pool[$0] ?? 0) > 0 }).randomElement() {
                    if let index = newLetters.firstIndex(where: { $0.letter == letter }) {
                        newLetters[index].count += 1
                    } else {
                        newLetters.append(GameLetter(letter: letter, count: 1))
                    }
                    pool[letter]! -= 1
                    lettersNeeded -= 1
                }

                for letter in newLetters {
                    if let index = userLetters.firstIndex(where: { $0.letter == letter.letter }) {
                        userLetters[index].count += letter.count
                    } else {
                        userLetters.append(letter)
                    }
                }

                db.collection("games").document(gameID).updateData(["letterPool": pool])
            }
        }
    }

    func startTimer(startDate: Date, duration: Int) {
        timer?.invalidate()
        let elapsed = Int(Date().timeIntervalSince(startDate))
        remainingTime = max(duration - elapsed, 0)

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingTime > 0 {
                remainingTime -= 1
            } else {
                timer?.invalidate()
                
                // 🔴 OYUN SÜRESİ BİTTİ — Oyunu bitir
                let db = Firestore.firestore()
                let gameRef = db.collection("games").document(gameID)

                var winnerID = ""
                var loserID = ""

                if uid == player1 {
                    winnerID = player2
                    loserID = player1
                } else {
                    winnerID = player1
                    loserID = player2
                }

                gameRef.updateData([
                    "status": "finished",
                    "isFinished": true,
                    "winner": winnerID,
                    "loser": loserID,
                    "player1Score": player1Score,
                    "player2Score": player2Score
                ]) { error in
                    if let error = error {
                        print("Süre bitimi sonrası güncelleme hatası: \(error.localizedDescription)")
                    } else {
                        print("Süre dolduğu için oyun sonlandırıldı.")
                    }
                }
            }
        }
    }

    func placeLetter(row: Int, col: Int) {
        guard !isGameFinished else { return }
        if bannedTiles.contains(Position(row: row, col: col)) && uid != turn {
            print("Bu bölgeye hamle yapılamaz!")
            return
        }
        guard let letter = selectedLetter else {
            print("Harf seçilmedi!")
            return
        }

        guard board[row][col].letter.isEmpty else {
            print("Bu hücre dolu!")
            return
        }

        // ✅ Sadece tahta tamamen boşsa ilk hamle kontrol edilir
        if isBoardEmpty() {
            if row != 7 || col != 7 {
                print("İlk hamle: harf 8,8'e konulmalı!")
                return
            }
        } else {
            if !isAdjacentToLetter(row: row, col: col) {
                print("Yeni harf tahtadaki mevcut bir harfe komşu olmalı!")
                return
            }
        }

       
        var finalLetter = letter
        if letter == "*" {
            return // Joker harfi kullanıcıdan alınacak
        }

        board[row][col].letter = finalLetter
        selectedPosition = (row, col)
        if let fullWord = extractWordsAround(row: row, col: col).first {
            self.currentWord = fullWord
        } else {
            self.currentWord = ""
        }

        if let mine = board[row][col].mine {
            applyMine(mine, at: row, col: col)
            board[row][col].mine = nil
        }
        if let reward = board[row][col].reward {
            collectReward(reward)
            board[row][col].reward = nil
        }

        if let index = userLetters.firstIndex(where: { $0.letter == letter }) {
            userLetters[index].count -= 1
            if userLetters[index].count == 0 {
                userLetters.remove(at: index)
            }
        }

        selectedLetter = nil
    }
    
    func isBoardEmpty() -> Bool {
        for row in 0..<15 {
            for col in 0..<15 {
                if !board[row][col].letter.isEmpty {
                    return false
                }
            }
        }
        return true
    }
    

    func saveBoard() {
        let boardArray = board.map { $0.map { $0.letter } }
        let boardData = try? JSONSerialization.data(withJSONObject: boardArray)
        let boardString = boardData.flatMap { String(data: $0, encoding: .utf8) } ?? "[]"

        Firestore.firestore().collection("games").document(gameID).updateData([
            "board": boardString,
            "player1Score": player1Score,
            "player2Score": player2Score,
            "turn": turn
        ])
    }

    func switchTurn() {
        turn = (turn == player1) ? player2 : player1

        Firestore.firestore().collection("games").document(gameID).updateData([
            "currentTurn": turn
        ]) { error in
            if let error = error {
                print("Firestore'da sıra güncellenirken hata: \(error.localizedDescription)")
            } else {
                print("Sıra başarıyla diğer oyuncuya geçti.")
            }
        }
    }
    
    
    func drawLetters(count: Int) {
        guard canDrawLetters else {
            canDrawLetters = true
            return
        }
        let db = Firestore.firestore()
        db.collection("games").document(gameID).getDocument { document, error in
            guard let data = document?.data(),
                  var pool = data["letterPool"] as? [String: Int] else { return }
            
            let vowels = ["A", "E", "I", "İ", "O", "Ö", "U", "Ü"]
            var newLetters: [GameLetter] = []
            var currentVowelCount = userLetters.filter { vowels.contains($0.letter) }.reduce(0) { $0 + $1.count }

            var addedVowels = 0
            while addedVowels < max(0, 2 - currentVowelCount) && newLetters.count < count {
                let availableVowels = vowels.filter { (pool[$0] ?? 0) > 0 }
                if let vowel = availableVowels.randomElement() {
                    if let index = newLetters.firstIndex(where: { $0.letter == vowel }) {
                        newLetters[index].count += 1
                    } else {
                        newLetters.append(GameLetter(letter: vowel, count: 1))
                    }
                    pool[vowel]! -= 1
                    addedVowels += 1
                } else {
                    break
                }
            }

            while newLetters.count < count {
                let availableLetters = pool.keys.filter { pool[$0]! > 0 }
                if let letter = availableLetters.randomElement() {
                    if let index = newLetters.firstIndex(where: { $0.letter == letter }) {
                        newLetters[index].count += 1
                    } else {
                        newLetters.append(GameLetter(letter: letter, count: 1))
                    }
                    pool[letter]! -= 1
                } else {
                    break
                }
            }

            for letter in newLetters {
                if let index = userLetters.firstIndex(where: { $0.letter == letter.letter }) {
                    userLetters[index].count += letter.count
                } else {
                    userLetters.append(letter)
                }
            }

            db.collection("games").document(gameID).updateData(["letterPool": pool])
        }
    }
    
    

    func confirmMove() {
            guard !isGameFinished else { return }
            guard let position = selectedPosition else {
                print("Harfin konum bilgisi yok!")
                return
            }

            let words = extractWordsAround(row: position.row, col: position.col)
            guard !words.isEmpty else {
                print("Herhangi bir kelime oluşmadı!")
                return
            }

            let allValid = words.allSatisfy { validWords.contains($0.lowercased()) }

            if allValid {
                // 1. Puan hesaplaması: tüm geçerli kelimeler için puan topla
                var gainedScore = words.reduce(0) { $0 + calculateWordScore(word: $1) }
                let mineType = activeMine
                activeMine = nil
                if let mine = mineType {
                    let originalScore = gainedScore
                    switch mine {
                    case .scoreSplit:
                        gainedScore = Int(Double(originalScore) * 0.3)
                        infoMessage = "Puan Bölünmesi uygulandı: \(originalScore) → \(gainedScore)"
                    case .scoreTransfer:
                                                    // Kullanıcının puanı 0 olur, rakip orijinal puanı alır
                                                    gainedScore = 0
                                                    infoMessage = "Puan Transferi uygulandı: \(originalScore) puan rakibe aktarıldı"

                                                    if uid == player1 {
                                                        player2Score += originalScore
                                                    } else {
                                                        player1Score += originalScore
                                                    }

                                                case .cancelWord:
                        gainedScore = 0
                        infoMessage = "Kelimeniz iptal edildi, puan almadınız."
                    default:
                        break
                    }
                }

                // 2. Puan güncellemesi
                if uid == player1 {
                    player1Score += gainedScore
                    if mineType == .scoreTransfer {
                        player2Score += words.reduce(0) { $0 + calculateWordScore(word: $1) }
                    }
                } else {
                    player2Score += gainedScore
                    if mineType == .scoreTransfer {
                        player1Score += words.reduce(0) { $0 + calculateWordScore(word: $1) }
                    }
                }

                // 3. Firestore'da puan güncelle
                Firestore.firestore().collection("games").document(gameID).updateData([
                    "player1Score": player1Score,
                    "player2Score": player2Score
                ]) { error in
                    if let error = error {
                        print("Skor güncellenirken hata oluştu: \(error.localizedDescription)")
                    } else {
                        print("Skor güncellendi.")
                    }
                }

                // 4. Sıra rakibe geçsin
                switchTurn()
                currentWord = ""
                selectedLetter = nil
                selectedPosition = nil
                // 5. Tahta kaydedilsin
                saveBoard()
                // 6. Harf havuzu güncellensin
                let usedCount = 7 - userLetters.reduce(0) { $0 + $1.count }
                drawLetters(count: usedCount)
            } else {
                print("Geçersiz kelime var!")
            }
        }
    func loadValidWords() {
        let filePath = "/Users/ASUS/Downloads/Turkce-Kelime-Listesi-master/turkce_kelime_listesi.txt"
        
        do {
            let contents = try String(contentsOfFile: filePath, encoding: .utf8)
            let words = contents.components(separatedBy: .newlines)
            self.validWords = Set(words.map { $0.lowercased() })
            print("Kelime listesi başarıyla yüklendi.")
        } catch {
            print("Kelime listesi bulunamadı veya yüklenemedi.")
        }
    }

    func populateMinesAndRewards() {
        let mines: [(MineType, Int)] = [
            (.scoreSplit, 5), (.scoreTransfer, 4), (.loseLetter, 3),
            (.blockExtraMove, 2), (.cancelWord, 2), (.regionBan, 2)
        ]
        let rewards: [(RewardType, Int)] = [
            (.letterBan, 3), (.extraMoveJoker, 2), (.wildcard, 2)
        ]

        var usedIndices = Set<Int>()
        func randomPos() -> (Int,Int) {
            var p: (Int,Int)
            var idx: Int
            repeat {
                p = (Int.random(in: 0..<15), Int.random(in: 0..<15))
                idx = p.0 * 15 + p.1
            } while usedIndices.contains(idx)
            usedIndices.insert(idx)
            return p
        }

        for (type, count) in mines {
            for _ in 0..<count {
                let (r, c) = randomPos()
                board[r][c].mine = type
            }
        }
        for (type, count) in rewards {
            for _ in 0..<count {
                let (r, c) = randomPos()
                board[r][c].reward = type
            }
        }
    }
    
    
    
    func isAdjacentToLetter(row: Int, col: Int) -> Bool {
        let directions = [
            (-1, 0), (1, 0), (0, -1), (0, 1), // yukarı, aşağı, sola, sağa
            (-1, -1), (-1, 1), (1, -1), (1, 1) // çaprazlar
        ]
        
        for (dr, dc) in directions {
            let newRow = row + dr
            let newCol = col + dc
            
            if newRow >= 0 && newRow < 15 && newCol >= 0 && newCol < 15 {
                if !board[newRow][newCol].letter.isEmpty {
                    return true
                }
            }
        }
        
        return false
    }

    func extractWordsAround(row: Int, col: Int) -> [String] {
            var foundWords: Set<String> = []

            // Tüm yönlerde tarama
            let directions = [
                (0, 1),
                (1, 0),
                (1, 1),
                (-1, 1)
            ]

            for (dy, dx) in directions {
                var fullWord = ""
                var wordPositions: [(Int, Int)] = []

                var startRow = row
                var startCol = col

                // Kelimenin başını bul
                while startRow - dy >= 0, startRow - dy < 15,
                      startCol - dx >= 0, startCol - dx < 15,
                      !board[startRow - dy][startCol - dx].letter.isEmpty {
                    startRow -= dy
                    startCol -= dx
                }

                // Baştan sona kadar tüm harfleri topla
                var r = startRow
                var c = startCol
                while r >= 0, r < 15, c >= 0, c < 15, !board[r][c].letter.isEmpty {
                    fullWord += board[r][c].letter.lowercased()
                    wordPositions.append((r, c))
                    r += dy
                    c += dx
                }

                if fullWord.count > 1 {
                    for i in 0..<fullWord.count {
                        for j in (i+1)...fullWord.count {
                            let substring = String(fullWord[fullWord.index(fullWord.startIndex, offsetBy: i)..<fullWord.index(fullWord.startIndex, offsetBy: j)])

                            // Yeni harfin bu substring içinde olup olmadığını pozisyonlardan kontrol et
                            let positionsSubset = wordPositions[i..<j]
                            let includesNewLetter = positionsSubset.contains(where: { $0 == (row, col) })

                            if includesNewLetter && validWords.contains(substring) {
                                foundWords.insert(substring)
                            }
                        }
                    }
                }
            }

            return Array(foundWords)
        }
    func calculateWordScore(word: String) -> Int {
        guard let pos = selectedPosition ?? selectedMoveFrom else { return 0 }

        let positions = getPositionsOfWord(row: pos.row, col: pos.col, word: word)
        let pointTable: [String: Int] = [
            "A": 1, "B": 2, "C": 4, "Ç": 4, "D": 3, "E": 1, "F": 7, "G": 5, "Ğ": 8, "H": 5,
            "I": 2, "İ": 1, "J": 10, "K": 1, "L": 1, "M": 2, "N": 1, "O": 2, "Ö": 7, "P": 5,
            "R": 1, "S": 2, "Ş": 4, "T": 1, "U": 2, "Ü": 3, "V": 7, "Y": 3, "Z": 4, "*": 0
        ]

        var total = 0
        var wordMultiplier = 1

        for (i, (row, col)) in positions.enumerated() {
            let tile = board[row][col]
            let letter = String(word[word.index(word.startIndex, offsetBy: i)])
            var letterScore = pointTable[letter.uppercased()] ?? 0

            if activeMine != .blockExtraMove {
                switch tile.multiplier {
                case .h2:
                    letterScore *= 2
                case .h3:
                    letterScore *= 3
                case .k2:
                    wordMultiplier *= 2
                case .k3:
                    wordMultiplier *= 3
                default:
                    break
                }
            }

            total += letterScore
        }

        return total * wordMultiplier
    }

    func getPositionsOfWord(row: Int, col: Int, word: String) -> [(Int, Int)] {
        var result: [(Int, Int)] = []

        var startCol = col
        while startCol > 0 && !board[row][startCol - 1].letter.isEmpty {
            startCol -= 1
        }
        var temp: [(Int, Int)] = []
        var c = startCol
        while c < 15 && !board[row][c].letter.isEmpty {
            temp.append((row, c))
            c += 1
        }
        if temp.count == word.count {
            return temp
        }

        var startRow = row
        while startRow > 0 && !board[startRow - 1][col].letter.isEmpty {
            startRow -= 1
        }
        temp = []
        var r = startRow
        while r < 15 && !board[r][col].letter.isEmpty {
            temp.append((r, col))
            r += 1
        }
        if temp.count == word.count {
            return temp
        }

        var sr = row
        var sc = col
        while sr > 0 && sc > 0 && !board[sr - 1][sc - 1].letter.isEmpty {
            sr -= 1
            sc -= 1
        }
        temp = []
        var rr = sr
        var cc = sc
        while rr < 15 && cc < 15 && !board[rr][cc].letter.isEmpty {
            temp.append((rr, cc))
            rr += 1
            cc += 1
        }
        if temp.count == word.count {
            return temp
        }

        sr = row
        sc = col
        while sr < 14 && sc > 0 && !board[sr + 1][sc - 1].letter.isEmpty {
            sr += 1
            sc -= 1
        }
        temp = []
        rr = sr
        cc = sc
        while rr >= 0 && cc < 15 && !board[rr][cc].letter.isEmpty {
            temp.append((rr, cc))
            if rr == 0 { break }
            rr -= 1
            cc += 1
        }
        if temp.count == word.count {
            return temp
        }

        return []
    }
    
    
    func extractWord() -> String {
            var horizontalWord = ""
            var verticalWord = ""

            for col in 0..<15 {
                if !board[7][col].letter.isEmpty {
                    horizontalWord += board[7][col].letter
                }
            }

            for row in 0..<15 {
                if !board[row][7].letter.isEmpty {
                    verticalWord += board[row][7].letter
                }
            }

            return (verticalWord.count >= horizontalWord.count) ? verticalWord : horizontalWord
        }
    
    
    func applyMine(_ mine: MineType, at row: Int, col: Int) {
        mineTriggeredCount += 1
        var description: String
        switch mine {
        case .scoreSplit:
            description = "Puan Bölme"
            activeMine = mine
        case .scoreTransfer:
            description = "Puan Transferi"
            activeMine = mine
        case .loseLetter:
            description = "Harf Kaybı"
            let db = Firestore.firestore()
            db.collection("games").document(gameID).getDocument { snapshot, error in
                guard let data = snapshot?.data(),
                      var pool = data["letterPool"] as? [String: Int] else { return }

                for letter in userLetters {
                    pool[letter.letter, default: 0] += letter.count
                }

                userLetters = []

                var lettersNeeded = 7
                var newLetters: [GameLetter] = []

                while lettersNeeded > 0, let letter = pool.keys.filter({ pool[$0, default: 0] > 0 }).randomElement() {
                    if let index = newLetters.firstIndex(where: { $0.letter == letter }) {
                        newLetters[index].count += 1
                    } else {
                        newLetters.append(GameLetter(letter: letter, count: 1))
                    }
                    pool[letter, default: 0] -= 1
                    lettersNeeded -= 1
                }

                userLetters = newLetters

                db.collection("games").document(gameID).updateData(["letterPool": pool])
                activeMine = mine
            }
        case .blockExtraMove:
            description = "Ekstra Hamle Engelleme"
            activeMine = mine
        case .cancelWord:
            description = "Kelime İptali"
            activeMine = mine
        case .regionBan:
            description = "Bölge Yasağı"
            for dr in -2...2 {
                for dc in -2...2 {
                    let r = row + dr, c = col + dc
                    if r >= 0 && r < 15 && c >= 0 && c < 15 {
                        bannedTiles.insert(Position(row: r, col: c))
                    }
                }
            }
        }
        infoMessage = "Mayına basıldı: \(description)"
    }
    
    
    func initializeUserStatsIfNeeded() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)

        userRef.getDocument { snapshot, error in
            if let error = error {
                print("Kullanıcı verisi alınamadı: \(error.localizedDescription)")
                return
            }

            var updates: [String: Any] = [:]
            if let data = snapshot?.data() {
                if data["totalGames"] == nil {
                    updates["totalGames"] = 0
                }
                if data["wonGames"] == nil {
                    updates["wonGames"] = 0
                }
            } else {
                updates["totalGames"] = 0
                updates["wonGames"] = 0
            }

            if !updates.isEmpty {
                userRef.setData(updates, merge: true) { err in
                    if let err = err {
                        print("Alanlar eklenirken hata oluştu: \(err.localizedDescription)")
                    } else {
                        print("Kullanıcı istatistik alanları başarıyla eklendi.")
                    }
                }
            }
        }
    }
    
    
    func updateUserStatsIfGameFinishedAndWon() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let isWinner = (uid == player1 && player1Score > player2Score) ||
                       (uid == player2 && player2Score > player1Score)

        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)

        userRef.getDocument { doc, error in
            var won = doc?.data()?["wonGames"] as? Int ?? 0
            var total = doc?.data()?["totalGames"] as? Int ?? 0

            total += 1
            if isWinner { won += 1 }

            let rate = total > 0 ? Double(won) / Double(total) : 0.0

            userRef.updateData([
                "wonGames": won,
                "totalGames": total,
                "successRate": rate
            ])
        }
    }
    
    
    

    func collectReward(_ reward: RewardType) {
        if !earnedRewards.contains(reward) {
            earnedRewards.append(reward)
        }
        showRewardButtons = true
        infoMessage = "\(reward.rawValue) ödülünü kazandınız! Kullanmak için simgeye dokunun."
    }

    func rewardIconName(for reward: RewardType) -> String {
        switch reward {
        case .extraMoveJoker:
            return "arrow.triangle.2.circlepath"
        case .letterBan:
            return "nosign"
        case .wildcard:
            return "rectangle.split.3x1"
        }
    }

    func activateReward(_ reward: RewardType) {
        switch reward {
        case .extraMoveJoker:
            infoMessage = "Ekstra hamle hakkı kazandınız!"
            canDrawLetters = false
        case .letterBan:
            infoMessage = "Rakibin 2 harfi donduruldu!"
        case .wildcard:
            let isRightBan = Bool.random()
            if isRightBan {
                let banColRange = 7..<15
                infoMessage = "Rakip sadece sol tarafa hamle yapabilir!"
                for r in 0..<15 {
                    for c in banColRange {
                        bannedTiles.insert(Position(row: r, col: c))
                    }
                }
            } else {
                // Rakip sadece sağ tarafa hamle yapabilir (sol yasaklanır)
                let banColRange = 0..<7
                infoMessage = "Rakip sadece sağ tarafa hamle yapabilir!"
                for r in 0..<15 {
                    for c in banColRange {
                        bannedTiles.insert(Position(row: r, col: c))
                    }
                }
            }
        }
        earnedRewards.removeAll { $0 == reward }
        if earnedRewards.isEmpty {
            showRewardButtons = false
        }
    }
}
