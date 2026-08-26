# Waypoint Safe Check-in Application 🛰️🛡️

[![Waypoint CI/CD Pipeline](https://github.com/ezgiderici26/waypoint_app/actions/workflows/ci_cd.yml/badge.svg)](https://github.com/ezgiderici26/waypoint_app/actions/workflows/ci_cd.yml)

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

### 6. 🔔 Geofence Bildirimleri ve Arka Plan Takibi
*   **Arka Plan Geçiş Tespiti:** Kullanıcı hedef geofence alanının içine girdiğinde (`ENTER`) veya dışına çıktığında (`EXIT`) gerçek zamanlı yerel bildirimler (push notifications) tetiklenir:
    *   📍 **Giriş Bildirimi:** *"Hedef Alana Girdiniz! (Kadıköy Meydan sınırları içindesiniz. Güvenli check-in yapabilirsiniz.)"*
    *   🚪 **Çıkış Bildirimi:** *"Hedef Alandan Çıktınız (Kadıköy Meydan bölgesinden uzaklaştınız. Mesafe: 380m)"*
*   **Olay Günlüğü:** Ayarlar menüsünden tüm giriş/çıkış olaylarının saat, mesafe ve hedef bilgileri listelenir.
*   **Android & iOS İzinleri:** Android 13+ `POST_NOTIFICATIONS`, `ACCESS_BACKGROUND_LOCATION` ve `FOREGROUND_SERVICE_LOCATION` izinleriyle tam uyumluluk.

### 7. ⚙️ Otomatik CI/CD Pipeline (GitHub Actions)
*   `.github/workflows/ci_cd.yml` dosyası ile tam otomatik 3 aşamalı DevOps boru hattı kurulmuştur:
    1.  **🔍 Lint & Format & Statik Analiz:** Dart formatting (`dart format`) ve `flutter analyze` linter kontrolleri.
    2.  **🧪 Otomatik Test & Coverage:** 23 testten oluşan birim/widget testlerinin icrası ve `lcov.info` test kapsama raporunun artifact olarak yüklenmesi.
    3.  **📱 Android Build & Artifact:** Debug ve Release APK (`app-release.apk`) derlenip 14 gün saklanmak üzere GitHub Actions Artifacts bölümüne otomatik yüklenmesi.
*   `push` (kod gönderimi) ve `pull_request` açıldığında otomatik tetiklenir; ayrıca GitHub UI üzerinden `workflow_dispatch` ile manuel de çalıştırılabilir.

### 8. 🎛️ Dinamik Risk Tuning & Kalibrasyon Paneli (K1 - K7)
*   **Gerçek Zamanlı Kalibrasyon:** Antispoofing güvenlik motorunun kullandığı tüm katsayılar (`K1 - K7`) ve güvenlik eşik limitleri çalışma zamanında slider'lar ile anlık olarak yeniden kalibre edilebilir:
    *   **K1:** OS Mock Provider Bayrağı (Varsayılan: 75 Puan)
    *   **K2:** Mock GPS Uygulama Paketi (Varsayılan: 50 Puan)
    *   **K3:** Geliştirici Modu & USB Hata Ayıklama (Varsayılan: 35 Puan)
    *   **K4:** İmkânsız Hız & Sıçrama (> 150 km/h) (Varsayılan: 70 Puan)
    *   **K5:** İvmeölçer Sensör Tutarsızlığı (Varsayılan: 40 Puan)
    *   **K6:** Cihaz Bütünlüğü (Root / Emülatör) (Varsayılan: 60 Puan)
    *   **K7:** Ağ Güvenliği (VPN / Proxy Tüneli) (Varsayılan: 45 Puan)
*   **Ön Ayar Profilleri (Presets):**
    *   🛡️ **Dengeli (Standart):** Standart mobil güvenlik kuralları.
    *   🔒 **Katı Kurumsal (Strict):** Yüksek toleranssız, en küçük anormallikte işlemi engelleyen sıkı profil.
    *   ⚡ **Esnek / Saha Testi (Permissive):** Saha testleri ve düşük yanlış pozitif toleransı için optimize edilmiş profil.
    *   🧪 **Özel (Custom):** Yöneticinin slider'lar ile özelleştirdiği parametreler.
*   **Canlı Test Alanı (Interactive Sandbox):** Arayüz üzerinde K1-K7 anomalilerini canlı açıp kapatarak ortaya çıkan toplam risk puanını ve sistemin vereceği kararı (`🟢 Güvenli`, `🟡 Şüpheli`, `🔴 Sahte / Engellendi`) anlık izleme.
*   **Kalıcı Depolama:** Yapılan tüm kalibrasyonlar Hive veritabanına kaydedilir ve uygulama yeniden başlatıldığında korunur.

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
Projedeki tüm birim, güvenlik, şifreleme, bildirim, risk tuning ve ısı haritası algoritmalarını test etmek için:
```powershell
flutter test
```
*(Antispoofing, Dinamik Risk Tuning & Katsayılar, AES-256 Şifreleme, Biyometrik Doğrulama, Heatmap Kümeleme/Filtreleme, Geofence Bildirimleri ve Smoke testleri dahil toplam 23 test çalıştırılır.)*

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

### 4. 🔔 Geofence Bildirimleri ve Arka Plan Takibi Manuel Test Adımları
1.  Uygulamanın **Ayarlar** sekmesine gidin.
2.  **"GEOFENCE VE ARKA PLAN BİLDİRİMLERİ"** kartı altındaki **"Test Bildirimi Gönder"** seçeneğine dokunarak cihazınıza anında sistem push bildirimi geldiğini doğrulayın.
3.  Aşağıdaki Demo panelinde yer alan **"Alana Giriş Simüle Et"** butonuna basın:
    *   Cihazınıza *"📍 Hedef Alana Girdiniz! (Kadıköy Meydan sınırları içindesiniz. Güvenli check-in yapabilirsiniz.)"* push bildirimi düşecektir.
    *   Harita ekranına döndüğünüzde yeşil *"📍 Hedef Kontrol Alanı İçindesiniz"* durum şeridinin yandığını ve **Check-in Yap** butonunun aktif olduğunu görün.
4.  Ardından **"Alandan Çıkış Simüle Et"** butonuna basın:
    *   Cihazınıza *"🚪 Hedef Alandan Çıktınız (Mesafe: 380m)"* push bildirimi düşecektir.
5.  Ayarlar sekmesindeki **"Geofence Olay Geçmişi"** butonuna basarak gerçekleşen tüm giriş/çıkış olaylarının saat, mesafe ve hedef kayıtlarını detaylı listede görüntüleyin.

### 5. ⚙️ GitHub Actions CI/CD Pipeline Manuel Test ve Çalıştırma Adımları
1.  Değişiklikleri GitHub reponuza push edin:
    ```powershell
    git push origin main
    ```
2.  Tarayıcınızda GitHub reponuzu açıp **Actions** sekmesine tıklayın.
3.  **"Waypoint CI/CD Pipeline 🛰️🛡️"** iş akışının otomatik olarak başladığını görün:
    *   🟢 **Lint, Format & Static Analysis:** Kod formatı ve `flutter analyze` adımı tamamlanır.
    *   🟢 **Automated Test Suite & Coverage:** 23 testin tamamı Linux üzerinde koşar ve test kapsama raporu üretilir.
    *   🟢 **Build Android APK & Artifact:** Release ve Debug APK dosyaları derlenir ve sayfanın en altındaki **Artifacts** bölümünden doğrudan indirilebilir hale gelir.
4.  Dilerseniz Actions sekmesinde iş akışını seçip **"Run workflow"** butonuna basarak dilediğiniz zaman manuel tetikleme de yapabilirsiniz.

### 6. 🎛️ Dinamik Risk Tuning & Kalibrasyon Manuel Test Adımları
1.  Uygulamanın **Ayarlar** sekmesini açın.
2.  **"DİNAMİK RİSK TUNING & KALİBRASYON"** kartına dokunarak kalibrasyon ekranına geçin.
3.  Üstteki ön ayar profillerinden **"🔒 Katı"** veya **"⚡ Saha"** profillerine tıklayın:
    *   Tüm K1-K7 slider'larının ve eşik değerlerinin otomatik olarak güncellendiğini görün.
4.  **Canlı Kalibrasyon Test Alanı** içerisindeki çiplere (örn: `K1: OS Mock`, `K4: Hız`, `K7: VPN`) dokunarak simülasyon yapın:
    *   Sol taraftaki dairesel puan göstergesinin (`75/100`) ve sağdaki durum etiketinin (`🟢 Güvenli`, `🟡 Şüpheli`, `🔴 Sahte / Engellendi`) anlık olarak değiştiğini izleyin.
5.  Herhangi bir katsayı slider'ını (örn: K1 katsayısını 75'ten 20'ye) düşürün:
    *   Profilin otomatik olarak **"🧪 Özel"** moduna geçtiğini ve puan hesaplamasının anında düştüğünü gözlemleyin.
6.  Alttaki **"Kalibrasyonu Kaydet & Canlı Uygula"** butonuna basın.
7.  Harita ekranına döndüğünüzde uygulamanın yeni belirlediğiniz ağırlıklarla ve eşiklerle anında çalıştığını doğrulayın.

