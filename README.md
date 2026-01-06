# Demans Asistanı

Demans hastaları için geliştirilmiş kapsamlı bir mobil hatırlatıcı asistan uygulaması. Bu uygulama, hasta yakınları ve hastalar için farklı arayüzler sunarak, günlük ilaç hatırlatıcıları, kişi albümü, konum takibi ve acil durum özellikleri sağlar.

## 📱 Özellikler

### Hasta Yakını Arayüzü
- ✅ **Hatırlatıcı Yönetimi:** İlaç, randevu ve aktivite hatırlatıcıları oluşturma, düzenleme ve silme
- ✅ **Konum Takibi:** Güvenli bölge tanımlama ve hasta konum takibi
- ✅ **Kişi Albümü:** Yakınların fotoğraflarını yükleme ve sesli anlatım ekleme
- ✅ **Profil Yönetimi:** Hasta ve hasta yakını bilgilerini yönetme

### Hasta Arayüzü
- ✅ **Hatırlatıcı Görüntüleme:** Günlük hatırlatıcıları görüntüleme
- ✅ **Kişi Albümü:** Yakınların fotoğraflarına tıklayarak sesli anlatım dinleme
- ✅ **Eve Dön Rehberi:** Adım adım navigasyon talimatları
- ✅ **Acil Durum Butonu:** Tek tuşla acil durum aksiyonları

## 🛠️ Teknolojiler

- **Flutter** - Cross-platform mobil uygulama framework'ü
- **Firebase Authentication** - Kullanıcı kimlik doğrulama
- **Cloud Firestore** - NoSQL veritabanı
- **Firebase Storage** - Dosya depolama
- **Firebase Cloud Messaging** - Push bildirimleri
- **Material Design 3** - Modern UI tasarım sistemi

## 📦 Kullanılan Paketler

- `firebase_core: ^4.2.1`
- `cloud_firestore: ^6.1.0`
- `firebase_auth: ^6.1.2`
- `firebase_storage: ^13.0.4`
- `firebase_messaging: ^16.0.4`
- `flutter_local_notifications: ^19.5.0`
- `geolocator: ^14.0.2`
- `google_maps_flutter: ^2.14.0`
- `image_picker: ^1.1.2`
- `flutter_tts: ^3.8.3`
- `url_launcher: ^6.3.2`
- `timezone: ^0.10.1`

## 🚀 Kurulum

### Gereksinimler
- Flutter SDK (^3.10.1)
- Dart SDK
- Android Studio / Xcode (platform geliştirme için)
- Firebase projesi ve yapılandırma dosyası

### Adımlar

1. **Repository'yi klonlayın:**
```bash
git clone https://github.com/KULLANICIADI/REPOSITORY-ADI.git
cd demansapp
```

2. **Bağımlılıkları yükleyin:**
```bash
flutter pub get
```

3. **Firebase yapılandırması:**
   - Firebase Console'da yeni bir proje oluşturun
   - Android ve iOS uygulamalarını ekleyin
   - `firebase_options.dart` dosyasını projeye ekleyin
   - `google-services.json` (Android) ve `GoogleService-Info.plist` (iOS) dosyalarını ekleyin

4. **Uygulamayı çalıştırın:**
```bash
flutter run
```

## 📁 Proje Yapısı

```
lib/
├── main.dart                 # Uygulama giriş noktası
├── models/                   # Veri modelleri
│   ├── app_user.dart
│   ├── reminder.dart
│   ├── memory_contact.dart
│   └── ...
├── screens/                  # UI ekranları
│   ├── auth/                 # Kimlik doğrulama
│   ├── reminders/            # Hatırlatıcılar
│   ├── album/                # Kişi albümü
│   ├── safe_zone/            # Konum takibi
│   ├── home_guide/           # Eve dön rehberi
│   ├── emergency/            # Acil durum
│   └── profile/              # Profil ayarları
└── services/                 # İş mantığı servisleri
    ├── auth_service.dart
    ├── reminder_service.dart
    ├── user_service.dart
    └── ...
```

## 🔒 Güvenlik

- Firebase Authentication ile güvenli kullanıcı girişi
- Firestore Security Rules ile veri erişim kontrolü
- Rol tabanlı erişim kontrolü (RBAC)
- HTTPS ile şifreli iletişim

## 📝 Dokümantasyon

Proje dokümantasyonu için aşağıdaki dosyalara bakabilirsiniz:

- `TECHNOLOGIES.md` - Kullanılan teknolojiler
- `DATABASE_DESIGN.md` - Veritabanı tasarımı
- `SECURITY_MEASURES.md` - Güvenlik önlemleri
- `TEST_PROCESS.md` - Test süreci
- `USER_SCENARIOS.md` - Kullanıcı senaryoları

## 👥 Kullanıcı Rolleri

### Hasta Yakını (Caregiver)
- Tüm özelliklere tam erişim
- Hatırlatıcı ekleme, düzenleme, silme
- Kişi albümü yönetimi
- Profil ayarları

### Hasta (Patient)
- Sadece görüntüleme modu
- Hatırlatıcıları görüntüleme
- Kişi albümü görüntüleme ve TTS dinleme
- Eve dön rehberi kullanma
- Acil durum butonu kullanma

## 🧪 Test

```bash
# Unit ve widget testleri
flutter test

# Coverage raporu
flutter test --coverage
```

## 📄 Lisans

Bu proje eğitim amaçlı geliştirilmiştir.

## 👨‍💻 Geliştirici

[Adınız ve iletişim bilgileriniz]

## 🙏 Teşekkürler

- Flutter Team
- Firebase Team
- Material Design Team
- Tüm açık kaynak topluluğu

---

**Not:** Bu proje, demans hastaları ve hasta yakınları için destekleyici bir araç olarak geliştirilmiştir. Tıbbi tavsiye yerine geçmez.
