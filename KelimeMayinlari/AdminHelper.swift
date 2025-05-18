//
//  AdminHelper.swift
//  KelimeMayinlari
//
//  Created by ASUDE on 26.04.2025.
//

import FirebaseFirestore

func fixAllGamesInFirestore() {
    let db = Firestore.firestore()
    
    db.collection("games").getDocuments { snapshot, error in
        guard let documents = snapshot?.documents else {
            print("Belge bulunamadı veya hata oluştu.")
            return
        }
        
        for doc in documents {
            var updates: [String: Any] = [:]
            
            // 1. duration düzelt
            if let durationString = doc.data()["duration"] as? String {
                switch durationString {
                case "2dk":
                    updates["duration"] = 120
                case "5dk":
                    updates["duration"] = 300
                case "12saat":
                    updates["duration"] = 43200
                case "24saat":
                    updates["duration"] = 86400
                default:
                    updates["duration"] = 120 // Varsayılan
                }
            }
            
            // 2. turn -> currentTurn düzelt
            if let turn = doc.data()["turn"] as? String {
                updates["currentTurn"] = turn
            }
            
            // 3. startTime yoksa ekle
            if doc.data()["startTime"] == nil {
                updates["startTime"] = FieldValue.serverTimestamp()
            }
            
            if !updates.isEmpty {
                db.collection("games").document(doc.documentID).updateData(updates) { err in
                    if let err = err {
                        print("Hata: \\(err.localizedDescription)")
                    } else {
                        print("Belge güncellendi: \\(doc.documentID)")
                    }
                }
            }
        }
    }
}
