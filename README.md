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
![kelime_mayinlari_kolaj](https://github.com/user-attachments/assets/380f16ec-04dd-4656-823b-c21433d30c31)

📸 Oyun Görselleri
