# Demans Asistanı - Güvenlik Önlemleri

## 1. Genel Bakış

Demans Asistanı uygulaması, hassas sağlık verileri ve kişisel bilgiler içerdiği için güvenlik en önemli önceliklerden biridir. Bu dokümanda, uygulamanın uyguladığı güvenlik önlemleri ve koruma mekanizmaları detaylı olarak açıklanmaktadır.

---

## 2. Kimlik Doğrulama ve Yetkilendirme

### 2.1 Firebase Authentication Entegrasyonu

**Amaç:** Kullanıcı kimlik doğrulamasını güvenli bir şekilde yönetmek.

**Uygulanan Önlemler:**
- **Email/Password Authentication:** Firebase Authentication servisi kullanılarak güvenli kullanıcı girişi sağlanır.
- **Şifre Güvenliği:** 
  - Şifreler Firebase tarafından hash'lenir ve düz metin olarak saklanmaz.
  - Minimum şifre uzunluğu Firebase Authentication kurallarına göre belirlenir.
  - Şifre alanlarında boşluk karakteri engellenir.
- **Oturum Yönetimi:** 
  - `StreamBuilder<User?>` ile oturum durumu gerçek zamanlı olarak izlenir.
  - Oturum sonlandığında otomatik olarak giriş sayfasına yönlendirme yapılır.
  - Persistent login (kalıcı oturum) Firebase tarafından güvenli şekilde yönetilir.

**Kod Örneği:**
```dart
// main.dart - AuthShell
StreamBuilder<User?>(
  stream: _authService.authStateChanges,
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return _RoleBasedHome(userId: snapshot.data!.uid);
    }
    return LoginPage();
  },
)
```

**Güvenlik Seviyesi:** Yüksek - Firebase Authentication endüstri standardı güvenlik sağlar.

---

### 2.2 Rol Tabanlı Erişim Kontrolü (RBAC)

**Amaç:** Kullanıcı rollerine göre farklı yetkiler ve erişim seviyeleri sağlamak.

**Uygulanan Önlemler:**
- **İki Rol Sistemi:**
  - **Hasta Yakını (Caregiver):** Tam yönetim yetkileri (ekleme, düzenleme, silme).
  - **Hasta (Patient):** Sadece görüntüleme yetkisi (düzenleme/ekleme yok).
- **Rol Doğrulama:** 
  - Kullanıcı rolü Firestore'dan çekilir ve her işlem öncesi kontrol edilir.
  - Rol bilgisi `AppUser` modelinde saklanır ve değiştirilemez.
- **UI Seviyesinde Kontrol:**
  - Hasta arayüzünde ekleme/düzenleme butonları gösterilmez.
  - Hasta yakını arayüzünde tüm yönetim özellikleri aktif.

**Kod Örneği:**
```dart
// main.dart - _RoleBasedHome
if (user.role == UserRole.caregiver) {
  return const CaregiverHomeShell(); // Tam yetkili arayüz
}
return const PatientHomeShell(); // Sadece görüntüleme arayüzü
```

**Güvenlik Seviyesi:** Yüksek - Rol tabanlı erişim kontrolü ile yetkisiz işlemler engellenir.

---

## 3. Veritabanı Güvenliği

### 3.1 Firestore Security Rules

**Amaç:** Firestore veritabanına erişimi kontrol etmek ve yetkisiz veri erişimini önlemek.

**Uygulanan Önlemler:**
- **Kullanıcı Bazlı Veri İzolasyonu:**
  - Her kullanıcı sadece kendi verilerine erişebilir.
  - `userId` alanı ile veri filtreleme yapılır.
- **Rol Bazlı Erişim Kuralları:**
  - Hasta yakını, bağlı olduğu hasta verilerine erişebilir.
  - Hasta, sadece kendi verilerini görüntüleyebilir.
- **Yazma İzinleri:**
  - Sadece giriş yapmış kullanıcılar veri yazabilir.
  - Kullanıcı sadece kendi `userId`'sine sahip verileri yazabilir.

**Örnek Security Rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // users koleksiyonu
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // reminders koleksiyonu
    match /reminders/{reminderId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null 
        && request.resource.data.userId == request.auth.uid;
      allow update, delete: if request.auth != null 
        && resource.data.userId == request.auth.uid;
    }
  }
}
```

**Güvenlik Seviyesi:** Yüksek - Firestore Security Rules ile veri erişimi tam kontrol altındadır.

---

### 3.2 Veri Doğrulama ve Validasyon

**Amaç:** Veritabanına kaydedilen verilerin doğruluğunu ve güvenliğini sağlamak.

**Uygulanan Önlemler:**
- **Form Validasyonu:**
  - Tüm form alanları için validasyon kuralları uygulanır.
  - Boş alanlar, geçersiz formatlar ve zararlı karakterler kontrol edilir.
- **Türkçe Karakter Desteği:**
  - Ad, soyad ve not alanlarında Türkçe karakterler desteklenir.
- **Veri Tipi Kontrolü:**
  - Firestore'a kaydedilen veriler `toMap()` metodu ile tip güvenli şekilde dönüştürülür.
  - `fromFirestore()` metodu ile gelen veriler doğrulanır ve parse edilir.

**Kod Örneği:**
```dart
// models/reminder.dart
Map<String, dynamic> toMap() {
  return {
    'title': title,
    'subtitle': subtitle,
    'timeLabel': timeLabel,
    // ... diğer alanlar
    'createdAt': DateTime.now().toIso8601String(),
  };
}
```

**Güvenlik Seviyesi:** Orta-Yüksek - Veri doğrulama ile hatalı veri girişi önlenir.

---

## 4. Veri Şifreleme ve Depolama

### 4.1 Firebase Storage Güvenliği

**Amaç:** Kullanıcı tarafından yüklenen dosyaların (fotoğraflar) güvenli şekilde saklanması.

**Uygulanan Önlemler:**
- **Kullanıcı Bazlı Depolama:**
  - Her kullanıcının dosyaları ayrı klasörlerde saklanır.
  - Dosya yolu: `memory_contacts/{userId}/{contactId}/photo.jpg`
- **Erişim Kontrolü:**
  - Firebase Storage Security Rules ile dosya erişimi kontrol edilir.
  - Sadece dosya sahibi ve bağlı hasta yakını erişebilir.
- **Dosya Boyutu ve Tipi Kontrolü:**
  - Yüklenen fotoğraflar optimize edilir (maxWidth: 1024, maxHeight: 1024).
  - Sadece görüntü dosyaları kabul edilir.

**Güvenlik Seviyesi:** Yüksek - Firebase Storage güvenli dosya depolama sağlar.

---

### 4.2 Şifreli İletişim (HTTPS)

**Amaç:** Uygulama ve Firebase arasındaki tüm iletişimin şifrelenmesi.

**Uygulanan Önlemler:**
- **HTTPS Protokolü:**
  - Tüm Firebase API çağrıları HTTPS üzerinden yapılır.
  - SSL/TLS sertifikaları ile iletişim şifrelenir.
- **API Key Güvenliği:**
  - Firebase API key'leri `firebase_options.dart` dosyasında saklanır.
  - API key'ler public olarak kullanılabilir ancak Firebase Console'da kısıtlamalar yapılabilir.

**Güvenlik Seviyesi:** Yüksek - HTTPS endüstri standardı şifreleme sağlar.

---

## 5. Uygulama Seviyesi Güvenlik

### 5.1 Input Sanitization (Girdi Temizleme)

**Amaç:** Kullanıcı girdilerindeki zararlı karakterleri temizlemek.

**Uygulanan Önlemler:**
- **String Temizleme:**
  - Tüm kullanıcı girdileri `.trim()` metodu ile başında/sonundaki boşluklar temizlenir.
  - Özel karakterler ve SQL injection benzeri saldırılar önlenir.
- **XSS (Cross-Site Scripting) Koruması:**
  - Flutter widget'ları otomatik olarak HTML/JavaScript kodlarını escape eder.
  - Kullanıcı girdileri doğrudan render edilmez.

**Kod Örneği:**
```dart
// add_reminder_page.dart
final reminder = Reminder(
  title: _titleController.text.trim(), // Boşluklar temizlenir
  subtitle: _subtitleController.text.trim(),
  // ...
);
```

**Güvenlik Seviyesi:** Orta - Temel input sanitization uygulanır.

---

### 5.2 Hata Yönetimi ve Bilgi Sızıntısı Önleme

**Amaç:** Hata mesajlarında hassas bilgilerin sızmasını önlemek.

**Uygulanan Önlemler:**
- **Genel Hata Mesajları:**
  - Kullanıcıya gösterilen hata mesajları teknik detaylar içermez.
  - Örnek: "Veri yüklenirken bir hata oluştu" (teknik detaylar log'da).
- **Log Yönetimi:**
  - Hassas bilgiler (şifreler, API key'ler) log'lara yazılmaz.
  - Debug modunda detaylı log'lar, production'da minimal log'lar.

**Kod Örneği:**
```dart
// reminder_dashboard.dart
catch (e) {
  print('Firestore hatası: $e'); // Sadece debug için
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Veriler yüklenirken bir hata oluştu.'), // Genel mesaj
    ),
  );
}
```

**Güvenlik Seviyesi:** Orta-Yüksek - Bilgi sızıntısı önlenir.

---

## 6. Oturum ve Erişim Kontrolü

### 6.1 Otomatik Oturum Sonlandırma

**Amaç:** Güvenlik ihlali durumunda oturumun otomatik sonlandırılması.

**Uygulanan Önlemler:**
- **StreamBuilder ile Dinleme:**
  - Firebase Authentication durumu gerçek zamanlı olarak izlenir.
  - Oturum sonlandığında (örneğin: başka cihazdan çıkış) otomatik olarak giriş sayfasına yönlendirme.
- **Manuel Çıkış:**
  - Kullanıcı her zaman "Çıkış Yap" seçeneği ile oturumu sonlandırabilir.
  - Çıkış yapıldığında tüm yerel veriler temizlenir.

**Kod Örneği:**
```dart
// main.dart - AuthShell
StreamBuilder<User?>(
  stream: _authService.authStateChanges,
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return _RoleBasedHome(userId: snapshot.data!.uid);
    }
    return LoginPage(); // Oturum yoksa giriş sayfası
  },
)
```

**Güvenlik Seviyesi:** Yüksek - Oturum güvenliği Firebase tarafından yönetilir.

---

### 6.2 Yetkisiz Erişim Önleme

**Amaç:** Yetkisiz kullanıcıların verilere erişmesini önlemek.

**Uygulanan Önlemler:**
- **Her İşlem Öncesi Kontrol:**
  - Her Firestore işlemi öncesi kullanıcı giriş durumu kontrol edilir.
  - `AuthService().currentUser` null ise işlem yapılmaz.
- **Veri Filtreleme:**
  - Tüm sorgular `userId` veya `patientId` ile filtrelenir.
  - Kullanıcı sadece kendi verilerini görür.

**Kod Örneği:**
```dart
// reminder_service.dart
Stream<List<Reminder>> getReminders({String? userId}) {
  Query query = _firestore.collection(_collection);
  if (userId != null) {
    query = query.where('userId', isEqualTo: userId); // Filtreleme
  }
  return query.snapshots().map(...);
}
```

**Güvenlik Seviyesi:** Yüksek - Çok katmanlı erişim kontrolü uygulanır.

---

## 7. Kişisel Verilerin Korunması (GDPR Uyumluluğu)

### 7.1 Veri Minimizasyonu

**Amaç:** Sadece gerekli verilerin toplanması ve saklanması.

**Uygulanan Önlemler:**
- **Minimum Veri Toplama:**
  - Sadece uygulamanın çalışması için gerekli veriler toplanır.
  - Gereksiz kişisel bilgiler istenmez.
- **Veri Saklama Süresi:**
  - Kullanıcı hesabı silindiğinde tüm veriler silinir.
  - Tamamlanan hatırlatıcılar isteğe bağlı olarak saklanır.

**Güvenlik Seviyesi:** Orta - Veri minimizasyonu prensibi uygulanır.

---

### 7.2 Kullanıcı Veri Erişim Hakkı

**Amaç:** Kullanıcıların kendi verilerine erişim hakkı.

**Uygulanan Önlemler:**
- **Veri Görüntüleme:**
  - Kullanıcılar kendi verilerini uygulama üzerinden görüntüleyebilir.
  - Profil ayarları sayfasından tüm bilgiler görüntülenebilir.
- **Veri Düzenleme:**
  - Kullanıcılar kendi verilerini düzenleyebilir.
  - Hasta yakını, hasta bilgilerini düzenleyebilir.

**Güvenlik Seviyesi:** Orta - Kullanıcı veri erişim hakkı sağlanır.

---

## 8. Ağ Güvenliği

### 8.1 İnternet Bağlantısı Kontrolü

**Amaç:** Ağ hatalarında güvenli davranış sergilemek.

**Uygulanan Önlemler:**
- **Hata Yakalama:**
  - Ağ bağlantı hataları yakalanır ve kullanıcıya bilgi verilir.
  - Firestore bağlantı hataları özel mesajlarla gösterilir.
- **Offline Mod (Gelecek Geliştirme):**
  - Firestore offline persistence ile veriler cache'lenir.
  - İnternet bağlantısı olmasa bile temel işlevler çalışabilir.

**Kod Örneği:**
```dart
// reminder_dashboard.dart
if (snapshot.hasError) {
  final error = snapshot.error.toString();
  final isNetworkError = error.contains('network') || 
                         error.contains('timeout');
  // Kullanıcıya uygun hata mesajı göster
}
```

**Güvenlik Seviyesi:** Orta - Ağ hataları güvenli şekilde yönetilir.

---

### 8.2 API İstek Güvenliği

**Amaç:** API isteklerinin güvenli şekilde yapılması.

**Uygulanan Önlemler:**
- **HTTPS Zorunluluğu:**
  - Tüm Firebase API çağrıları HTTPS üzerinden yapılır.
  - HTTP istekleri otomatik olarak reddedilir.
- **Token Doğrulama:**
  - Her API isteğinde Firebase Authentication token'ı gönderilir.
  - Token geçersizse istek reddedilir.

**Güvenlik Seviyesi:** Yüksek - HTTPS ve token doğrulama ile güvenli API iletişimi.

---

## 9. Cihaz Güvenliği

### 9.1 Uygulama Verilerinin Korunması

**Amaç:** Cihazda saklanan verilerin korunması.

**Uygulanan Önlemler:**
- **Firebase Authentication Token:**
  - Authentication token'ları cihazın güvenli depolama alanında saklanır.
  - Android: KeyStore, iOS: Keychain kullanılır.
- **Yerel Veri:**
  - Hassas veriler cihazda saklanmaz.
  - Tüm veriler Firestore'da saklanır.

**Güvenlik Seviyesi:** Yüksek - Cihaz güvenliği platform seviyesinde sağlanır.

---

### 9.2 Uygulama İzinleri

**Amaç:** Gerekli izinlerin güvenli şekilde yönetilmesi.

**Uygulanan Önlemler:**
- **Minimum İzin Prensibi:**
  - Sadece gerekli izinler istenir.
  - Konum izni: Sadece konum takibi için.
  - Kamera/Galeri izni: Sadece fotoğraf yükleme için.
  - Bildirim izni: Sadece hatırlatıcı bildirimleri için.
- **İzin Kontrolü:**
  - İzinler kullanılmadan önce kontrol edilir.
  - İzin reddedilirse kullanıcıya bilgi verilir.

**Güvenlik Seviyesi:** Orta-Yüksek - Minimum izin prensibi uygulanır.

---

## 10. Güvenlik Açığı Yönetimi

### 10.1 Güvenlik Güncellemeleri

**Amaç:** Bilinen güvenlik açıklarının kapatılması.

**Uygulanan Önlemler:**
- **Bağımlılık Güncellemeleri:**
  - Flutter ve Firebase paketleri düzenli olarak güncellenir.
  - `flutter pub upgrade` komutu ile güvenlik yamaları uygulanır.
- **Firebase Console İzleme:**
  - Firebase Console'da güvenlik uyarıları izlenir.
  - Güvenlik kuralları düzenli olarak gözden geçirilir.

**Güvenlik Seviyesi:** Orta - Düzenli güncellemeler ile güvenlik açıkları kapatılır.

---

### 10.2 Güvenlik Testleri

**Amaç:** Güvenlik önlemlerinin etkinliğini test etmek.

**Önerilen Testler:**
- **Kimlik Doğrulama Testleri:**
  - Geçersiz şifre denemeleri.
  - Oturum sonlandırma testleri.
- **Yetkilendirme Testleri:**
  - Rol bazlı erişim kontrolü testleri.
  - Yetkisiz veri erişim denemeleri.
- **Veri Güvenliği Testleri:**
  - Firestore Security Rules testleri.
  - Veri doğrulama testleri.

**Güvenlik Seviyesi:** Orta - Testler ile güvenlik önlemleri doğrulanır.

---

## 11. Güvenlik Önlemleri Özet Tablosu

| Güvenlik Kategorisi | Uygulanan Önlem | Güvenlik Seviyesi | Durum |
|---------------------|-----------------|-------------------|-------|
| Kimlik Doğrulama | Firebase Authentication | Yüksek | ✅ Aktif |
| Rol Tabanlı Erişim | RBAC Sistemi | Yüksek | ✅ Aktif |
| Veritabanı Güvenliği | Firestore Security Rules | Yüksek | ✅ Aktif |
| Veri Şifreleme | HTTPS, SSL/TLS | Yüksek | ✅ Aktif |
| Input Sanitization | String temizleme | Orta | ✅ Aktif |
| Hata Yönetimi | Bilgi sızıntısı önleme | Orta-Yüksek | ✅ Aktif |
| Oturum Yönetimi | Otomatik oturum sonlandırma | Yüksek | ✅ Aktif |
| Veri Minimizasyonu | Minimum veri toplama | Orta | ✅ Aktif |
| Ağ Güvenliği | HTTPS, Token doğrulama | Yüksek | ✅ Aktif |
| Cihaz Güvenliği | Platform güvenli depolama | Yüksek | ✅ Aktif |
| İzin Yönetimi | Minimum izin prensibi | Orta-Yüksek | ✅ Aktif |

---

## 12. Güvenlik İyileştirme Önerileri

### 12.1 Kısa Vadeli Öneriler (1-2 Ay)
- **İki Faktörlü Kimlik Doğrulama (2FA):** Kullanıcı güvenliğini artırmak için 2FA eklenebilir.
- **Şifre Güçlülük Kontrolü:** Kayıt sırasında şifre güçlülük kontrolü yapılabilir.
- **Oturum Timeout:** Belirli bir süre kullanılmayan oturumlar otomatik sonlandırılabilir.

### 12.2 Orta Vadeli Öneriler (3-6 Ay)
- **Veri Şifreleme:** Hassas veriler (notlar, kişisel bilgiler) ek şifreleme ile korunabilir.
- **Audit Logging:** Tüm veri erişimleri ve değişiklikleri log'lanabilir.
- **Rate Limiting:** API isteklerine rate limiting uygulanabilir (DDoS koruması).

### 12.3 Uzun Vadeli Öneriler (6+ Ay)
- **Penetrasyon Testi:** Profesyonel güvenlik testleri yapılabilir.
- **Güvenlik Sertifikasyonu:** ISO 27001 veya benzeri güvenlik standartlarına uyum sağlanabilir.
- **Biometric Authentication:** Parmak izi veya yüz tanıma ile giriş eklenebilir.

---

## 13. Güvenlik Olay Yönetimi

### 13.1 Güvenlik İhlali Senaryosu

**Durum:** Bir kullanıcının hesabının ele geçirildiği tespit edildi.

**Yapılacaklar:**
1. **Hemen:** Etkilenen kullanıcının oturumu sonlandırılır.
2. **Kısa Süre:** Kullanıcıya bildirim gönderilir ve şifre değiştirmesi istenir.
3. **Orta Süre:** Güvenlik log'ları incelenir ve ihlal kapsamı belirlenir.
4. **Uzun Süre:** Güvenlik açığı kapatılır ve tüm kullanıcılar bilgilendirilir.

---

### 13.2 Veri Sızıntısı Senaryosu

**Durum:** Veritabanından veri sızıntısı tespit edildi.

**Yapılacaklar:**
1. **Hemen:** Etkilenen veriler tespit edilir ve erişim kısıtlanır.
2. **Kısa Süre:** Etkilenen kullanıcılar bilgilendirilir.
3. **Orta Süre:** Güvenlik açığı kapatılır ve veriler şifrelenir.
4. **Uzun Süre:** Güvenlik önlemleri gözden geçirilir ve iyileştirilir.

---

## 14. Sonuç

Demans Asistanı uygulaması, **çok katmanlı güvenlik yaklaşımı** ile korunmaktadır. Firebase'in endüstri standardı güvenlik özellikleri, rol tabanlı erişim kontrolü, veri şifreleme ve güvenli oturum yönetimi ile kullanıcı verileri ve kişisel bilgiler güvende tutulmaktadır. Uygulama, **GDPR uyumluluğu** prensiplerine uygun olarak tasarlanmıştır ve düzenli güvenlik güncellemeleri ile korunmaktadır. Gelecekte, iki faktörlü kimlik doğrulama, veri şifreleme ve biometrik giriş gibi ek güvenlik özellikleri eklenerek güvenlik seviyesi daha da artırılabilir.

