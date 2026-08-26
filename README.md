# Waypoint Safe Check-in Application 🛰️🛡️

Waypoint, modern mobil güvenlik tehditlerine karşı geliştirilmiş, Clean Architecture prensiplerine uygun, Riverpod durum yönetimli, Google Maps entegrasyonlu ve gelişmiş konum doğrulama (antispoofing) yeteneklerine sahip bir Flutter mobil uygulamasıdır.

Uygulamanın ana amacı; kullanıcıların belirli kontrol noktalarında (geofence) güvenli ve konum manipülasyonu (Fake GPS, Root, VPN, Emulator) yapılmamış bir şekilde "Check-in" işlemini gerçekleştirmesini sağlamaktır.

---

## 🚀 Öne Çıkan Özellikler

### 1. 🛡️ Gelişmiş Antispoofing Çekirdeği (Konum Doğrulama)
Uygulama, konum manipülasyonu girişimlerini engellemek için **katmanlı ve ağırlıklı bir güvenlik modeli** kullanır:
*   **K1 (OS Mock Flag Tespiti):** İşletim sistemi düzeyinde (Android `isFromMockProvider`, iOS `isSimulated`) sahte konum flag'lerini anlık olarak yakalar. (Ağırlık: +75 puan)
*   **K3 (Geliştirici Seçenekleri Tespiti):** Cihazda Geliştirici Seçenekleri veya USB Hata Ayıklama (Debugging) özelliklerinin aktif olup olmadığını denetler. (Ağırlık: +35 puan)
*   **K4 (İmkânsız Hız / Işınlanma Kontrolü):** Ardışık konum güncellemeleri arasındaki Haversine mesafesini ve zaman farkını oranlayarak anlık hızı hesaplar. Hızın mantık sınırlarını (**> 150 km/h**) aşması durumunda tetiklenir. (Ağırlık: +70 puan)
*   **K5 (Sensör Çapraz Doğrulaması):** Cihazın fiziksel ivmeölçerinden (`sensors_plus`) gelen hareket verileri ile GPS üzerindeki hız değişimini karşılaştırır. GPS hızı artarken cihazın fiziksel olarak hareket etmediğini (sabit durma manipülasyonu) algılarsa tetiklenir. (Ağırlık: +40 puan)

### 2. 📊 Ağırlıklı Risk Skoru ve Seviyeleri (0 - 100 Puan)
Algılanan anomaliler normalize edilerek 0 ile 100 arasında bir risk skoru üretilir:
*   🟢 **0 - 34: GÜVENLİ** (İşleme izin verilir)
*   🟡 **35 - 69: ŞÜPHELİ** (Check-in kilitlenir)
*   🔴 **70 - 100: SAHTE / GÜVENSİZ** (İşlem tamamen engellenir ve engelleme kaydı tutulur)

### 3. 🔌 Yerel Veritabanı ve Çevrimdışı (Offline) Kuyruk
*   **Yerel Depolama (Hive):** Tüm başarılı ve engellenmiş check-in denemeleri, cihaz bütünlük bilgileri (Root, VPN, Emulator) ile birlikte yerel veritabanında güvenle saklanır.
*   **REST API Entegrasyonu (Dio):** Kayıtlar JSON formatında sunucuya (mockapi.io) gönderilir.
*   **Offline Queue (Kuyruk Eşitleme):** İnternet bağlantısı koptuğunda kayıtlar yerel veritabanında kuyruğa alınır (`isSynced: false`). İnternet geri geldiğinde 30 saniyelik otomatik arka plan görevi (worker) veya arayüzdeki **Senkronizasyon** butonu sayesinde kuyruktaki veriler otomatik olarak sunucuya gönderilir ve eşitlenir (`isSynced: true`).

### 4. 🗺️ Google Maps ve Geofencing
*   Canlı konum verileri harita üzerinde anlık güncellenir ve kamera kullanıcıyı takip eder.
*   Hedef kontrol noktası geofence alanı haritada yarı saydam çember (Circle) olarak çizilir.
*   Kullanıcı geofence alanı dışındayken "Check-in Yap" butonu kilitlenir ve kalan mesafe anlık gösterilir (Örn: *Hedefe 120 m uzaktasın*).

### 5. 🌡️ Yönetici Isı Haritası (Heatmap) & Güvenlik Analitiği
*   **Çok Katmanlı Radyal Isı Görselleştirmesi:** Google Maps üzerinde radyal gradyan çemberler (`Circle`) ile check-in yoğunluğu ve güvenlik tehditleri modellenir.
*   **Görünüm Modları:**
    *   🔥 **Yoğunluk Modu:** Check-in sayısına göre dinamik renk skalası (Mavi [Düşük] ➔ Yeşil [Orta] ➔ Turuncu [Yüksek] ➔ Kırmızı [Kritik Hotspot]).
    *   🛡️ **Risk / Tehdit Modu:** Tehditlerin toplandığı bölgeleri vurgular (Yeşil: Güvenli, Turuncu: Şüpheli, Parlayan Kırmızı: Sahte GPS/VPN ihlali olan saldırı noktaları).
    *   📍 **Noktasal Mod:** Bireysel check-in lokasyonları.
*   **Filtreler & Hızlı Odaklanma:** Tümü, Sadece Güvenli, Sadece Tehditler, Son 24 Saat filtreleri ve Kadıköy, Beşiktaş, Taksim, Levent, Maslak hızlı atlama butonları.
*   **Yönetici KPI Göstergeleri:** Toplam Check-in, Güvenlik Oranı (%), Engellenen Tehdit Sayısı, Ortalama Risk Skoru, En Yoğun Hotspot ve Cihaz Güvenlik İhlalleri dökümü.
*   **Etkileşimli Küme Detayı:** Haritadaki herhangi bir ısı kümesine tıklandığında içindeki tüm check-in kayıtları, zamanları, risk puanları ve donanım bütünlük durumları modal pencerede listelenir.

---

## 🛠️ Kurulum ve Yapılandırma

### 🔑 Google Maps API Key Repo Hijyeni Yapılandırması
API anahtarlarının repoya sızmasını önlemek amacıyla güvenli enjeksiyon mekanizması kurulmuştur:
1.  Projenin root dizinindeki [android/local.properties](file:///c:/Users/90546/waypoint_app/android/local.properties) dosyasını açın.
2.  Dosyanın en altına şu satırı kendi Google Maps anahtarınızla ekleyin:
    ```properties
    MAPS_API_KEY=AIzaSyYourActualGoogleMapsAPIKeyHere
    ```
3.  Uygulamayı çalıştırın. Gradle bu anahtarı `AndroidManifest.xml` içerisindeki manifest placeholder'larına otomatik olarak güvenle enjekte edecektir.

---

## 🧪 Test Etme Kılavuzu

### 1. Otomatik Testlerin Çalıştırılması (Birim ve Mantık Testleri)
Projedeki tüm birim, güvenlik, şifreleme ve ısı haritası algoritmalarını test etmek için:
```powershell
flutter test
```
*(Antispoofing, AES-256 Şifreleme, Biyometrik Doğrulama, Heatmap Kümeleme/Filtreleme ve Smoke testleri dahil toplam 12 test çalıştırılır.)*

### 2. 📱 Simülasyon ve Demo Modu ile Manuel Test
Uygulamayı emülatörde veya cihazda test ederken Fake GPS açmaya gerek kalmadan tüm senaryoları denemek için yerleşik **Simülasyon Modu** entegre edilmiştir:
1.  Uygulamanın **Ayarlar** sekmesine gidin.
2.  En alttaki **"SİMÜLASYON / TEST SEÇENEKLERİ (DEMO)"** panelinden test etmek istediğiniz tehditleri tetikleyin:
    *   **Sahte Konum Tetikle (K1)**
    *   **İmkânsız Hız/Işınlanma Tetikle (K4)**
    *   **VPN / Proxy Bağlantısı Tetikle** (Dashboard'da tun0/ppp0 uyarısı yanar ve check-in kilitlenir)
    *   **Biyometrik Hata Simüle Et** (Parmak izi başarısız senaryolarını test eder)
    *   **API Sunucusunu Çevrimdışı Simüle Et** (Açıldığında check-in kayıtları kuyrukta birikir; kapatılıp geçmiş ekranındaki döner oka basıldığında sunucuyla senkronize olur).

### 3. 🌡️ Yönetici Isı Haritası (Heatmap) Manuel Test Adımları
1.  Alt navigasyon çubuğundan **"Isı Haritası"** sekmesine (veya Harita/Geçmiş ekranlarındaki alev ikonuna) tıklayın.
2.  Sağ üstteki **🧪 (Beher / Demo Verisi)** butonuna basın. (İstanbul geneli 22 adet gerçekçi check-in kümesi yüklenecektir.)
3.  **Yoğunluk** ve **Risk / Tehdit** modları arasında geçiş yapın:
    *   *Yoğunluk modunda* Kadıköy Meydanı'nın yüksek yoğunlukla alev aldığını gözlemleyin.
    *   *Risk / Tehdit modunda* Taksim Meydanı ve Maslak bölgelerinin kırmızı alarm halkalarıyla parladığını görün.
4.  Filtre çiğlerinden **"🔴 Tehditler"** ve **"🟢 Güvenli"** filtrelerini deneyin.
5.  Alt kısımdaki **Kadıköy, Beşiktaş, Taksim, Levent** hızlı odak butonlarına basarak kameranın ilgili bölgelere yumuşak geçişini test edin.
6.  Haritadaki herhangi bir pine veya renkli halkaya tıklayarak **küme içi detaylı cihaz ve risk loglarını** inceleyin.
7.  Alttaki analitik çubuğuna tıklayarak açılan **Yönetici Isı & Analitik Paneli** üzerinden ısı yayılım çarpanı slider'ını ve KPI kartlarını test edin.

