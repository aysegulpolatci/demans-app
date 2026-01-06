# Demans Asistanı - Teknoloji Stack'i

## 🎨 FRONTEND TEKNOLOJİLERİ

### 1. **Flutter Framework**
- **Versiyon**: SDK ^3.10.1
- **Açıklama**: Google tarafından geliştirilen, tek kod tabanıyla Android ve iOS için native performanslı mobil uygulamalar geliştirmeye olanak sağlayan UI framework'ü.
- **Kullanım Amacı**: 
  - Cross-platform mobil uygulama geliştirme
  - Tek kod tabanıyla hem Android hem iOS desteği
  - Hot reload ile hızlı geliştirme döngüsü
  - Widget-based deklaratif UI yapısı

### 2. **Dart Programlama Dili**
- **Versiyon**: ^3.10.1
- **Açıklama**: Flutter'ın kullandığı, Google tarafından geliştirilen modern, tip güvenli programlama dili.
- **Kullanım Amacı**:
  - Tüm uygulama mantığının yazılması
  - State yönetimi
  - Business logic implementasyonu
  - Async/await ile asenkron işlemler

### 3. **Material Design 3**
- **Açıklama**: Google'ın en güncel tasarım sistemi, modern ve erişilebilir UI bileşenleri sağlar.
- **Kullanım Amacı**:
  - Modern, tutarlı kullanıcı arayüzü
  - Erişilebilirlik standartlarına uyum
  - Responsive tasarım desteği
  - Material 3 bileşenleri (NavigationBar, FilledButton, vb.)

### 4. **Cupertino Icons**
- **Versiyon**: ^1.0.8
- **Açıklama**: iOS tarzı ikon seti.
- **Kullanım Amacı**: Platform tutarlılığı için ikon desteği.

---

## 🔧 FRONTEND YARDIMCI KÜTÜPHANELER

### 5. **Image Picker**
- **Versiyon**: ^1.1.2
- **Açıklama**: Cihaz galerisinden veya kameradan fotoğraf seçmek için kullanılan paket.
- **Kullanım Amacı**: 
  - Kişi albümü modülünde fotoğraf yükleme
  - Kullanıcı profil fotoğrafı ekleme
  - Galeri ve kamera erişimi

### 6. **URL Launcher**
- **Versiyon**: ^6.3.2
- **Açıklama**: Telefon, SMS, e-posta, web tarayıcı gibi harici uygulamaları açmak için kullanılan paket.
- **Kullanım Amacı**:
  - Acil durum modülünde telefon araması yapma
  - SMS gönderme
  - Konum paylaşımı (Google Maps linki)

### 7. **Flutter TTS (Text-to-Speech)**
- **Versiyon**: ^3.8.3
- **Açıklama**: Metni sese dönüştüren paket.
- **Kullanım Amacı**:
  - Kişi albümünde fotoğraf açıldığında otomatik seslendirme
  - Eve dön rehberinde adım adım yönlendirme seslendirmesi
  - Demans hastaları için erişilebilirlik

### 8. **Flutter Local Notifications**
- **Versiyon**: ^19.5.0
- **Açıklama**: Cihazda yerel bildirimler göstermek için kullanılan paket.
- **Kullanım Amacı**:
  - Hatırlatıcı bildirimleri
  - Güvenli bölge dışına çıkma uyarıları
  - Acil durum bildirimleri
  - Zamanlanmış bildirimler

### 9. **Timezone**
- **Versiyon**: ^0.10.1
- **Açıklama**: Zaman dilimi yönetimi için kullanılan paket.
- **Kullanım Amacı**: Bildirim zamanlamalarında doğru zaman dilimi kullanımı.

---

## 📍 KONUM VE HARİTA TEKNOLOJİLERİ

### 10. **Geolocator**
- **Versiyon**: ^14.0.2
- **Açıklama**: Cihazın GPS konumunu almak ve izlemek için kullanılan paket.
- **Kullanım Amacı**:
  - Hasta konumunu sürekli takip etme
  - Güvenli bölge (geofence) kontrolü
  - Eve dön rehberinde başlangıç konumu belirleme
  - Acil durumda konum paylaşımı

### 11. **Google Maps Flutter**
- **Versiyon**: ^2.14.0
- **Açıklama**: Google Maps'i Flutter uygulamasına entegre eden paket.
- **Kullanım Amacı**:
  - Konum takibi sayfasında harita görüntüleme
  - Güvenli bölge çemberi çizme
  - Hasta konumunu marker ile gösterme
  - Eve dön rehberinde rota görselleştirme

---

## 🔥 BACKEND TEKNOLOJİLERİ (Firebase)

### 12. **Firebase Core**
- **Versiyon**: ^4.2.1
- **Açıklama**: Firebase servislerinin temel başlatma paketi.
- **Kullanım Amacı**:
  - Firebase projesini uygulamaya bağlama
  - Tüm Firebase servislerinin initialization'ı
  - Platform-specific yapılandırma (Android/iOS)

### 13. **Firebase Authentication**
- **Versiyon**: ^6.1.2
- **Açıklama**: Kullanıcı kimlik doğrulama servisi.
- **Kullanım Amacı**:
  - Email/Password ile kullanıcı girişi
  - Kullanıcı kaydı
  - Oturum yönetimi (persistent login)
  - Güvenli şifre saklama (hashing)
  - Otomatik token yenileme
- **Özellikler**:
  - Email doğrulama desteği (gelecekte eklenebilir)
  - Şifre sıfırlama (gelecekte eklenebilir)
  - Çoklu oturum yönetimi

### 14. **Cloud Firestore**
- **Versiyon**: ^6.1.0
- **Açıklama**: NoSQL, gerçek zamanlı veritabanı servisi.
- **Kullanım Amacı**:
  - Kullanıcı profilleri saklama
  - Hatırlatıcılar veritabanı
  - Kişi albümü verileri
  - Hasta bilgileri
  - Kullanıcı-hasta bağlantıları
- **Özellikler**:
  - Real-time synchronization (StreamBuilder ile)
  - Offline desteği (cache)
  - Otomatik ölçeklenebilirlik
  - Güvenlik kuralları ile veri koruması
  - Koleksiyon ve doküman yapısı

### 15. **Firebase Storage**
- **Versiyon**: ^13.0.4
- **Açıklama**: Dosya depolama servisi (fotoğraflar, videolar, vb.).
- **Kullanım Amacı**:
  - Kişi albümü fotoğraflarını saklama
  - Kullanıcı profil fotoğrafları
  - Güvenli dosya yükleme ve indirme
- **Özellikler**:
  - Otomatik CDN entegrasyonu
  - Dosya boyutu ve tip kısıtlamaları
  - Güvenlik kuralları
  - Progress tracking

### 16. **Firebase Cloud Messaging (FCM)**
- **Versiyon**: ^16.0.4
- **Açıklama**: Push notification servisi.
- **Kullanım Amacı**:
  - Acil durum bildirimleri (hasta yakınlarına)
  - Güvenli bölge ihlali uyarıları
  - Hatırlatıcı bildirimleri
  - Gerçek zamanlı uyarılar
- **Özellikler**:
  - Cross-platform bildirim desteği
  - Topic-based messaging
  - Background ve foreground bildirimleri
  - Bildirim önceliklendirme

---

## 🏗️ MİMARİ YAPISI

### Frontend Mimari
- **Widget-Based Architecture**: Flutter'ın deklaratif widget yapısı
- **State Management**: StatefulWidget ve StreamBuilder kullanımı
- **Service Layer Pattern**: 
  - `AuthService` - Kimlik doğrulama
  - `UserService` - Kullanıcı yönetimi
  - `ReminderService` - Hatırlatıcı işlemleri
  - `LocationService` - Konum işlemleri
  - `StorageService` - Dosya yönetimi
  - `NotificationService` - Bildirim yönetimi
  - `TtsService` - Seslendirme servisi

### Backend Mimari
- **Serverless Architecture**: Firebase Backend-as-a-Service (BaaS)
- **NoSQL Database**: Firestore koleksiyon yapısı
- **Real-time Updates**: Stream-based veri senkronizasyonu
- **Security Rules**: Firestore ve Storage güvenlik kuralları

---

## 📊 VERİ YAPISI

### Firestore Koleksiyonları
1. **users** - Kullanıcı profilleri
2. **reminders** - Hatırlatıcılar
3. **memoryContacts** - Kişi albümü
4. **patientInfo** - Hasta bilgileri
5. **locationEvents** - Konum geçmişi

### Storage Klasörleri
- `users/{userId}/profile.jpg` - Profil fotoğrafları
- `memoryContacts/{contactId}/photo.jpg` - Kişi fotoğrafları

---

## 🔒 GÜVENLİK

### Frontend Güvenlik
- Şifre alanlarında boşluk engelleme
- Input validation
- Form validation
- Error handling

### Backend Güvenlik
- Firebase Authentication (şifre hashing)
- Firestore Security Rules
- Storage Security Rules
- Role-based access control (Hasta/Hasta Yakını)

---

## 🚀 GELİŞTİRME ARAÇLARI

### Development
- **Flutter SDK**: ^3.10.1
- **Dart SDK**: ^3.10.1
- **Flutter Lints**: ^6.0.0 (kod kalitesi)

### Build Tools
- **Gradle** (Android)
- **CocoaPods** (iOS)
- **Flutter Build System**

---

## 📱 PLATFORM DESTEĞİ

- ✅ **Android** (minSdk: Flutter default)
- ✅ **iOS** (minVersion: Flutter default)
- ⚠️ **Web** (şu an desteklenmiyor, gelecekte eklenebilir)

---

## 🔄 VERİ AKIŞI

### Frontend → Backend
1. Kullanıcı aksiyonu (buton tıklama, form gönderme)
2. Service katmanı (AuthService, ReminderService, vb.)
3. Firebase SDK çağrısı
4. Firebase servisleri (Auth, Firestore, Storage)

### Backend → Frontend
1. Firebase real-time updates (StreamBuilder)
2. Service katmanı stream'leri
3. Widget rebuild
4. UI güncelleme

---

## 📈 ÖLÇEKLENEBİLİRLİK

### Firebase Avantajları
- Otomatik ölçeklenebilirlik
- Global CDN desteği
- Yüksek kullanılabilirlik
- Otomatik yedekleme

### Flutter Avantajları
- Native performans
- Tek kod tabanı
- Hızlı geliştirme
- Kolay bakım

---

## 🎯 KULLANIM SENARYOLARI

### Hasta Yakını
- Hatırlatıcı oluşturma/düzenleme
- Kişi albümü yönetimi
- Konum takibi
- Acil durum bildirimleri alma

### Hasta
- Hatırlatıcıları görüntüleme
- Kişi albümüne bakma
- Eve dön rehberi kullanma
- Acil durum butonu kullanma

---

## 🔮 GELECEKTE EKLENEBİLECEK TEKNOLOJİLER

- **Provider/Riverpod/Bloc**: State management için
- **Google Directions API**: Rota hesaplama
- **Geofencing Plugin**: Arka planda konum takibi
- **Biometric Authentication**: Parmak izi/yüz tanıma
- **Offline First**: Hive/SQLite ile offline veri saklama

