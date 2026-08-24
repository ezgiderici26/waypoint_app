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
Projedeki K1 OS Mock ve K4 Işınlanma algoritmalarının doğruluğunu test etmek için terminalde şu komutu çalıştırın:
```powershell
flutter test test/antispoofing_test.dart
```

### 2. 📱 Simülasyon ve Demo Modu ile Manuel Test (Önerilen)
Uygulamayı emülatörde veya cihazda test ederken Fake GPS açmaya gerek kalmadan tüm senaryoları denemek için yerleşik **Simülasyon Modu** entegre edilmiştir:
1.  Uygulamanın **Ayarlar** sekmesine gidin.
2.  En alttaki **"SİMÜLASYON / TEST SEÇENEKLERİ (DEMO)"** panelinden test etmek istediğiniz tehditleri tetikleyin:
    *   **Sahte Konum Tetikle (K1)**
    *   **İmkânsız Hız/Işınlanma Tetikle (K4)**
    *   **VPN / Proxy Bağlantısı Tetikle** (Dashboard'da tun0/ppp0 uyarısı yanar ve check-in kilitlenir)
    *   **API Sunucusunu Çevrimdışı Simüle Et** (Açıldığında check-in kayıtları kuyrukta birikir; kapatılıp geçmiş ekranındaki döner oka basıldığında sunucuyla başarıyla senkronize olur).
