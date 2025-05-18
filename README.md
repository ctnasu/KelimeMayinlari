💣 Kelime Mayınları – Türkçe Stratejik Mobil Kelime Oyunu

Kelime Mayınları, SwiftUI ile geliştirilen ve Firebase altyapısıyla desteklenen, iki oyunculu gerçek zamanlı bir Türkçe kelime oyunudur. Oyuncular, 15x15'lik bir oyun tahtasında rastgele harflerle kelimeler oluştururken gizli mayınlar ve ödüllerle karşılaşır. Oyun; kelime dağarcığının yanı sıra strateji, dikkat ve zaman yönetimini bir araya getirir.

🛠️ Teknolojiler

Teknoloji	Açıklama
SwiftUI	Modern, deklaratif iOS kullanıcı arayüzü oluşturma framework’ü
Firebase Auth	E-posta & şifre ile kullanıcı kayıt ve kimlik doğrulama
Cloud Firestore	Gerçek zamanlı veritabanı, eş zamanlı oyun durumu takibi
Client-Server Yapı	Oyuncular arası veri alışverişi ve oyun senkronizasyonu
📱 Uygulama Özeti

İki oyunculu, çevrimiçi mobil kelime oyunu
15x15 karelik tahta üzerinde Türkçe kelime oluşturma
Her hamlede risk içeren gizli mayınlar ve ödüller
Çarpanlı karelerle (H², K³ vb.) puan artırımı
Gerçek zamanlı oyun ilerleyişi ve sıra takibi
Firebase üzerinden anlık veri paylaşımı
🎮 Oyun Mekanikleri

🎯 Oyun Kuralları
Oyun 15x15’lik bir matris üzerinde oynanır.
Her oyuncuya başlangıçta 7 harf verilir (userLetters[]).
İlk hamle mutlaka merkeze (7,7) yapılır.
Her yeni harf, tahtadaki mevcut harflerden en az biriyle komşu olmalıdır.
Harfler yerleştirildikten sonra hamle onaylanmalıdır.
Doğrulama, turkce_kelime_listesi.txt dosyasındaki kelimelerle yapılır.
📊 Puanlama Sistemi
Her harfin puanı pointTable sözlüğünde tanımlıdır.
H² / K³ gibi çarpanlı kareler puanı etkiler.
calculateWordScore() fonksiyonu:
Harf puanlarını ve çarpanları birlikte hesaba katar.
Aktif mayın varsa skoru değiştirir.
💣 Mayınlar ve 🎁 Ödüller

💣 Mayın Türleri (applyMine() ile uygulanır)
Tür	Etkisi
scoreSplit	Puanın sadece %30'u alınır.
scoreTransfer	Tüm puan rakibe aktarılır.
loseLetter	Kalan harfler iade edilir, yeni 7 harf alınır.
blockExtraMove	Hücre çarpanları devre dışı kalır.
cancelWord	Kelime geçersiz olur, sıra geçer.
regionBan	Rakip belirli bölgelere hamle yapamaz. (bannedTiles ile tanımlanır)
🎁 Ödül Türleri (collectReward() ile uygulanır)
Tür	Etkisi
extraMoveJoker	Oyuncu, sırayla iki kez hamle yapabilir.
letterBan	Rakibin elindeki 2 harf bir tur boyunca kullanılamaz.
wildcard	Rakip sadece tahtanın sağ tarafını kullanabilir.
🧠 Ana Fonksiyonlar

Fonksiyon	Açıklama
placeLetter()	Harf yerleştirme ve komşuluk kontrolü
confirmMove()	Hamle onayı ve kelime geçerliliği
calculateWordScore()	Skor hesaplama (çarpan ve mayın etkisi dahil)
switchTurn()	Oyuncular arasında sıra geçişi
populateMinesAndRewards()	Mayın ve ödülleri başlangıçta rastgele yerleştirir
applyMine()	Mayın etkisini oyun mantığına uygular
collectReward()	Ödül etkisini oyun mantığına uygular
startTimer()	Oyun süresini başlatır ve Firebase’e bitiş verisi yollar

📸 Oyun Görselleri
![Simulator Screenshot - iPhone 16 Pro Max - 2025-05-18 at 14 24 22](https://github.com/user-attachments/assets/b5a048e7-18d5-4985-a6ba-7ccf5ec4ae54)
![Simulator Screenshot - iPhone 16 Pro Max - 2025-05-18 at 14 25 13](https://github.com/user-attachments/assets/a9ebbbf4-a736-4757-a725-ee5d2b054a3b)
![Simulator Screenshot - iPhone 16 Pro Max - 2025-05-18 at 14 25 41](https://github.com/user-attachments/assets/938e4118-8b33-4032-8f69-648a627ecae7)
![Simulator Screenshot - iPhone 16 Pro Max - 2025-05-18 at 14 25 43](https://github.com/user-attachments/assets/9c01598b-1793-4154-8556-189ec15145bb)
![Simulator Screenshot - iPhone 16 Pro Max - 2025-05-18 at 14 26 55](https://github.com/user-attachments/assets/edf9b581-58a5-4a5a-999f-d212a0bb22cc)
![Simulator Screenshot - iPhone 16 Pro Max - 2025-05-18 at 14 27 52](https://github.com/user-attachments/assets/d5be81c0-36a6-46b1-86b6-227aa8c77c95)
![Simulator Screenshot - iPhone 16 Pro Max - 2025-05-18 at 14 27 58](https://github.com/user-attachments/assets/baad6d3b-d775-4e9a-a703-0036ae60593d)
![Simulator Screenshot - iPhone 16 Pro Max - 2025-05-18 at 14 28 02](https://github.com/user-attachments/assets/1e1b4da9-5778-41a2-a7d7-8be94bd81693)
![Simulator Screenshot - iPhone 16 Pro Max - 2025-05-18 at 14 28 32](https://github.com/user-attachments/assets/b5bee451-51a4-46df-a4cb-34806b8d7317)
![Simulator Screenshot - iPhone 16 Pro Max - 2025-05-18 at 14 28 42](https://github.com/user-attachments/assets/2fc659ff-97a2-47b0-aff6-bbc607cdf215)
![Simulator Screenshot - iPhone 16 Pro Max - 2025-05-18 at 14 28 47](https://github.com/user-attachments/assets/4536943c-aaa3-43bf-a9e4-51246a96efa8)
![Simulator Screenshot - iPhone 16 - 2025-05-18 at 14 29 14](https://github.com/user-attachments/assets/80c23b5f-e4ed-467c-93f5-479c7fc7ecfc)
![Simulator Screenshot - iPhone 16 - 2025-05-18 at 14 29 26](https://github.com/user-attachments/assets/292019e7-667d-4d3f-94a1-cace0c7f8595)

