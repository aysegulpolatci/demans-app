# main.dart Dosyası Analizi

## 1. Genel Yapı ve Amaç

**Amaç:** Demans hastaları ve hasta yakınları için hatırlatıcı, konum takibi, kişi albümü, eve dönüş rehberi ve acil durum özelliklerini içeren mobil uygulamanın ana giriş noktası ve navigasyon yönetimi.

**Teknolojiler:** 
- Flutter Framework (Dart)
- Firebase Core (Firebase servislerinin başlatılması)
- Firebase Authentication (Kullanıcı kimlik doğrulama)
- Cloud Firestore (Kullanıcı verileri ve uygulama verileri)
- Firebase Cloud Messaging (Push bildirimler)
- Flutter Local Notifications (Yerel bildirimler)
- Material Design 3 (UI tasarım sistemi)

## 2. Ana Fonksiyon (main)

**Konum:** Satır 18-32

**İşlevler:**
- `WidgetsFlutterBinding.ensureInitialized()`: Flutter framework'ünü başlatır ve widget sistemini hazırlar.
- `Firebase.initializeApp()`: Firebase servislerini (Authentication, Firestore, Storage) başlatır ve platform bazlı yapılandırmayı yükler.
- `NotificationService.initialize()`: Yerel bildirim sistemini başlatır ve Android/iOS izinlerini yapılandırır.
- `NotificationService.requestPermissions()`: Kullanıcıdan bildirim izinlerini ister.
- `FcmService.initialize()`: Firebase Cloud Messaging servisini başlatır ve push notification token'ını alır.
- `runApp(MyApp())`: Uygulamayı çalıştırır ve kök widget'ı render eder.

**Önem:** Uygulama çalışmadan önce tüm temel servislerin (Firebase, bildirimler) hazır olmasını sağlar ve hata durumlarını önler.

## 3. Uygulama Kök Widget'ı (MyApp)

**Konum:** Satır 34-58

**Yapılandırmalar:**

### MaterialApp Ayarları:
- `debugShowCheckedModeBanner: false`: Debug banner'ını gizler.
- `title: 'Demans Asistanı'`: Uygulama başlığı.
- `home: AuthShell`: Ana sayfa olarak kimlik doğrulama shell'ini ayarlar.

### Tema Yapılandırması (ThemeData):
- `useMaterial3: true`: Material Design 3 kullanımını etkinleştirir.
- `scaffoldBackgroundColor: Color(0xFFF4F5FB)`: Sayfa arka plan rengi (açık gri).
- `colorScheme`: 
  - Seed Color: `Color(0xFF4B7CFB)` (Mavi)
  - Brightness: Light (Açık tema)
- `textTheme`: 
  - Font Family: 'SF Pro Display'
  - Body Color: `Color(0xFF1F1F28)` (Koyu gri)
  - Display Color: `Color(0xFF1F1F28)`

**Önem:** Tüm uygulama boyunca tutarlı bir görsel tasarım ve renk şeması sağlar.

## 4. Kimlik Doğrulama Yönetimi (AuthShell)

**Konum:** Satır 60-95

**İşlevler:**
- `StreamBuilder<User?>`: Firebase Authentication'dan gelen kullanıcı oturum durumunu gerçek zamanlı olarak dinler.
- **Durum Kontrolü:**
  - `ConnectionState.waiting`: Yüklenme durumunda `CircularProgressIndicator` gösterir.
  - `snapshot.hasData`: Kullanıcı giriş yapmışsa `_RoleBasedHome` widget'ına yönlendirir.
  - Kullanıcı yoksa: `LoginPage` widget'ını gösterir.

**Akış:**
```
Firebase Auth Durumu
  ├─ Kullanıcı VAR → _RoleBasedHome (Ana sayfa)
  └─ Kullanıcı YOK → LoginPage (Giriş sayfası)
```

**Önem:** Uygulamanın güvenlik katmanını oluşturur ve kullanıcıyı oturum durumuna göre doğru sayfaya yönlendirir.

## 5. Kullanıcı Veri Yükleyici (_UserDataLoader)

**Konum:** Satır 97-235

**İşlevler:**
- **Yeni Kullanıcı Kaydı:** Firebase Authentication'da kullanıcı var ama Firestore'da yoksa, otomatik olarak Firestore'a kullanıcı kaydı oluşturur.
- **Varsayılan Rol:** Yeni kullanıcılara otomatik olarak "hasta" (patient) rolü atanır.
- **Durum Yönetimi:**
  - Loading: "Kullanıcı bilgileri kaydediliyor..." mesajı gösterir.
  - Başarılı: `_RoleBasedHome` widget'ına yönlendirir.
  - Hata: Hata mesajı gösterir ve "Çıkış Yap" / "Devam Et" butonları sunar.

**Hata Yönetimi:**
- Firestore bağlantı hatalarını yakalar.
- Kullanıcıya anlaşılır hata mesajları gösterir.
- Alternatif aksiyonlar (çıkış yap, devam et) sunar.

**Önem:** Kullanıcı kayıt akışını otomatikleştirir ve veri tutarlılığını sağlar.

## 6. Rol Tabanlı Ana Sayfa (_RoleBasedHome)

**Konum:** Satır 237-380

**İşlevler:**
- `StreamBuilder<AppUser?>`: Firestore'dan kullanıcı bilgilerini gerçek zamanlı olarak çeker.
- **Rol Kontrolü:**
  - `UserRole.caregiver` (Hasta Yakını): `CaregiverHomeShell` widget'ını gösterir.
  - `UserRole.patient` (Hasta): `PatientHomeShell` widget'ını gösterir.

**Hata Yönetimi:**
- Ağ bağlantı hatalarını kontrol eder ve kullanıcıya bilgi verir.
- Firestore bağlantı hatalarını kontrol eder.
- Kullanıcı bilgisi bulunamazsa `_UserDataLoader` widget'ını çağırır.

**Önem:** Rol tabanlı erişim kontrolü sağlar ve kullanıcıya rolüne uygun arayüzü sunar.

## 7. Hasta Yakını Arayüzü (CaregiverHomeShell)

**Konum:** Satır 382-466

**Yapılandırmalar:**

### AppBar:
- `backgroundColor: Colors.transparent`: Şeffaf arka plan.
- `elevation: 0`: Gölge yok.
- **Actions:**
  - Ayarlar butonu: `ProfileSettingsPage` sayfasına yönlendirir.
  - Popup menü: Çıkış yapma seçeneği.

### Alt Navigasyon Bar (NavigationBar):
- **Sekmeler:**
  1. **Hatırlatıcılar** (`ReminderDashboard`): İlaç, görev ve randevu hatırlatıcıları yönetimi.
  2. **Konum Takibi** (`SafeZonePage`): Güvenli bölge yönetimi ve konum takibi.
  3. **Kişi Albümü** (`AlbumPage`): Aile üyelerinin fotoğrafları ve bilgileri yönetimi.

### Sayfa Yönetimi:
- `IndexedStack`: Sayfa durumlarını korur (sayfa yeniden oluşturulmaz, performans optimizasyonu).
- `_pages` listesi: Tüm sayfaları içerir.

**Önem:** Hasta yakınlarının tüm yönetim özelliklerine (ekleme, düzenleme, silme) erişmesini sağlar.

## 8. Hasta Arayüzü (PatientHomeShell)

**Konum:** Satır 468-547

**Yapılandırmalar:**

### AppBar:
- `backgroundColor: Colors.transparent`: Şeffaf arka plan.
- `elevation: 0`: Gölge yok.
- **Actions:**
  - Popup menü: Çıkış yapma seçeneği.

### Alt Navigasyon Bar (NavigationBar):
- **Sekmeler:**
  1. **Hatırlatıcılar** (`ReminderDashboard`): Sadece görüntüleme modu (düzenleme/ekleme yetkisi yok).
  2. **Kişiler** (`AlbumPage`): Sadece görüntüleme modu, fotoğrafa tıklayınca sesli açıklama.
  3. **Eve Dön** (`HomeGuidePage`): Adım adım navigasyon rehberi ve sesli yol tarifi.
  4. **Acil** (`EmergencyPage`): Tek tuşla acil durum butonu (arama, SMS, konum paylaşımı).

### Sayfa Yönetimi:
- `IndexedStack`: Sayfa durumlarını korur.
- `_pages` listesi: Tüm sayfaları içerir.

**Önem:** Demans hastaları için karmaşık olmayan, kolay kullanılabilir ve sadece görüntüleme odaklı bir arayüz sunar.

## 9. İçe Aktarılan Modüller

### Ekranlar (Screens):
- `LoginPage`: Kullanıcı giriş ekranı (email/password).
- `ReminderDashboard`: Hatırlatıcılar ana sayfası (liste, filtreleme, ekleme).
- `SafeZonePage`: Konum takibi ve güvenli bölge yönetimi.
- `AlbumPage`: Kişi albümü (fotoğraflar, TTS seslendirme).
- `HomeGuidePage`: Eve dönüş rehberi (adım adım navigasyon).
- `EmergencyPage`: Acil durum butonu ve hızlı aksiyonlar.
- `ProfileSettingsPage`: Profil ve hasta bilgileri yönetimi.

### Servisler (Services):
- `AuthService`: Firebase Authentication işlemleri (giriş, çıkış, kayıt).
- `UserService`: Firestore kullanıcı verileri CRUD işlemleri.
- `NotificationService`: Yerel bildirimler (hatırlatıcı zamanlaması).
- `FcmService`: Firebase Cloud Messaging (push notifications).

### Modeller (Models):
- `AppUser`: Kullanıcı modeli (uid, name, email, role, patientId).
- `UserRole`: Kullanıcı rolü enum'ı (patient, caregiver).

### Firebase:
- `firebase_core`: Firebase temel servisi.
- `firebase_auth`: Firebase Authentication.
- `firebase_options.dart`: Platform bazlı Firebase yapılandırması (Android/iOS).

## 10. Uygulama Akış Diyagramı

```
main()
  ↓
WidgetsFlutterBinding.ensureInitialized()
  ↓
Firebase.initializeApp()
  ↓
NotificationService.initialize()
  ↓
FcmService.initialize()
  ↓
runApp(MyApp)
  ↓
MyApp → AuthShell
  ↓
AuthShell → StreamBuilder<User?>
  ├─ Kullanıcı YOK → LoginPage
  └─ Kullanıcı VAR → _RoleBasedHome
      ↓
      _RoleBasedHome → StreamBuilder<AppUser?>
      ├─ Kullanıcı YOK → _UserDataLoader
      └─ Kullanıcı VAR → Rol Kontrolü
          ├─ Caregiver → CaregiverHomeShell
          │   ├─ ReminderDashboard
          │   ├─ SafeZonePage
          │   └─ AlbumPage
          └─ Patient → PatientHomeShell
              ├─ ReminderDashboard (sadece görüntüleme)
              ├─ AlbumPage (sadece görüntüleme)
              ├─ HomeGuidePage
              └─ EmergencyPage
```

## 11. Temel Özellikler

### Otomatik Oturum Yönetimi:
- `StreamBuilder<User?>` ile Firebase Authentication durumu anlık dinlenir.
- Kullanıcı çıkış yaptığında otomatik olarak giriş sayfasına yönlendirilir.
- Kullanıcı giriş yaptığında otomatik olarak ana sayfaya yönlendirilir.

### Rol Tabanlı Erişim Kontrolü:
- Kullanıcı rolüne göre farklı arayüzler gösterilir.
- Hasta yakını: Tam yönetim yetkileri (ekleme, düzenleme, silme).
- Hasta: Sadece görüntüleme yetkisi.

### Hata Yönetimi:
- Ağ bağlantı hataları kontrol edilir ve kullanıcıya bilgi verilir.
- Firestore bağlantı hataları kontrol edilir.
- Kullanıcıya anlaşılır hata mesajları gösterilir.
- Hata durumunda alternatif aksiyonlar (yeniden dene, çıkış yap) sunulur.

### Performans Optimizasyonu:
- `IndexedStack` kullanarak sayfa durumları korunur (sayfa yeniden oluşturulmaz).
- `StreamBuilder` ile real-time veri güncellemeleri (gereksiz rebuild'ler önlenir).
- Lazy loading ile gereksiz widget oluşturulması önlenir.

### Kullanıcı Deneyimi:
- Loading durumları gösterilir (`CircularProgressIndicator`).
- Hata durumlarında kullanıcıya bilgi verilir ve alternatif aksiyonlar sunulur.
- Çıkış yapma seçeneği her zaman erişilebilir (popup menü).
- Profil ayarlarına kolay erişim (AppBar'da ayarlar butonu).

## 12. Güvenlik Özellikleri

### Kimlik Doğrulama Kontrolü:
- Her sayfa erişiminde kullanıcı durumu kontrol edilir (`StreamBuilder<User?>`).
- Kullanıcı giriş yapmamışsa giriş sayfasına yönlendirilir.

### Rol Tabanlı Erişim:
- Kullanıcı rolüne göre farklı yetkiler ve arayüzler.
- Hasta yakını: Tam yönetim yetkileri.
- Hasta: Sadece görüntüleme yetkisi.

### Otomatik Çıkış:
- Oturum sonlandığında otomatik yönlendirme (`StreamBuilder` ile dinleme).

### Veri Doğrulama:
- Firestore'dan kullanıcı bilgisi doğrulanır.
- Kullanıcı bilgisi bulunamazsa otomatik kayıt oluşturulur veya hata mesajı gösterilir.

## 13. Kod İstatistikleri

- **Toplam Satır Sayısı:** 548 satır
- **Widget Sayısı:** 7 ana widget (MyApp, AuthShell, _UserDataLoader, _RoleBasedHome, CaregiverHomeShell, PatientHomeShell, _CategoryChip)
- **StreamBuilder Kullanımı:** 2 adet (Auth durumu, Kullanıcı bilgisi)
- **Sayfa Sayısı:** 7 farklı ekran
- **Servis Entegrasyonu:** 4 servis (Auth, User, Notification, FCM)
- **Import Sayısı:** 16 modül

## 14. Tasarım Özellikleri

### Material Design 3:
- Modern ve tutarlı arayüz tasarımı.
- Material 3 bileşenleri kullanılır (NavigationBar, AppBar, vb.).

### Responsive Layout:
- Farklı ekran boyutlarına uyumlu tasarım.
- Mobil cihazlar için optimize edilmiş.

### Renk Şeması:
- Ana Renk (Seed Color): `#4B7CFB` (Mavi)
- Arka Plan: `#F4F5FB` (Açık gri)
- Metin Rengi: `#1F1F28` (Koyu gri)

### Navigasyon:
- Alt navigasyon bar ile kolay sayfa geçişi.
- `IndexedStack` ile sayfa durumlarının korunması.

### İkonlar:
- Material Icons kullanılır.
- Her sekme için uygun ikonlar seçilmiştir.

## 15. Sonuç

`main.dart` dosyası, Demans Asistanı uygulamasının **kalbi** konumundadır. Tüm uygulama akışını yönetir, kullanıcı kimlik doğrulamasını kontrol eder, rol tabanlı erişim sağlar ve kullanıcıya uygun arayüzü sunar. Dosya, **modüler yapı**, **hata yönetimi** ve **kullanıcı deneyimi** açısından iyi organize edilmiştir. Firebase entegrasyonu, bildirim sistemleri ve rol tabanlı arayüz yönetimi ile demans hastaları ve hasta yakınları için güvenli ve kullanıcı dostu bir deneyim sunar.
