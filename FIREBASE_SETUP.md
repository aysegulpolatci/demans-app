# Firebase Firestore Veritabanı Kurulum Rehberi

Bu rehber, hatırlatıcılar ve diğer modüller için Firestore veritabanını nasıl kuracağınızı adım adım açıklar.

## 📋 Adım 1: Firebase Console'da Firestore Database Oluşturma

1. **Firebase Console'a giriş yapın:**
   - [https://console.firebase.google.com/](https://console.firebase.google.com/) adresine gidin
   - Projenizi seçin (veya yeni bir proje oluşturun)

2. **Firestore Database'i oluşturun:**
   - Sol menüden **"Build"** bölümüne tıklayın
   - **"Firestore Database"** seçeneğine tıklayın
   - **"Create database"** butonuna tıklayın

3. **Güvenlik kurallarını seçin:**
   - **"Start in test mode"** seçeneğini seçin (geliştirme aşaması için)
   - ⚠️ **ÖNEMLİ:** Production'da mutlaka güvenlik kurallarını güncelleyin!
   - **"Next"** butonuna tıklayın

4. **Veritabanı konumunu seçin:**
   - Size en yakın bölgeyi seçin (örneğin: `europe-west1` veya `europe-west3`)
   - **"Enable"** butonuna tıklayın
   - Veritabanı oluşturulması birkaç dakika sürebilir

## 🔒 Adım 2: Güvenlik Kurallarını Ayarlama

Firestore veritabanı oluşturulduktan sonra güvenlik kurallarını ayarlamanız gerekir:

1. **Firestore Database sayfasında:**
   - Üst menüden **"Rules"** sekmesine tıklayın

2. **Geliştirme aşaması için (Test Mode):**
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```
   Bu kural: Sadece giriş yapmış kullanıcılar okuyup yazabilir.

3. **Production için (Daha güvenli):**
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       // Hatırlatıcılar koleksiyonu
       match /reminders/{reminderId} {
         allow read, write: if request.auth != null 
           && request.auth.uid == resource.data.userId;
         allow create: if request.auth != null 
           && request.auth.uid == request.resource.data.userId;
       }
       
       // Diğer koleksiyonlar için benzer kurallar ekleyebilirsiniz
     }
   }
   ```
   Bu kural: Kullanıcılar sadece kendi verilerini okuyup yazabilir.

4. **"Publish"** butonuna tıklayarak kuralları kaydedin

## 📊 Adım 3: Veritabanı Yapısı

Firestore'da veriler **koleksiyonlar (collections)** ve **dokümanlar (documents)** şeklinde organize edilir.

### Hatırlatıcılar (Reminders) Koleksiyonu Yapısı:

```
reminders (collection)
  ├── {reminderId} (document)
  │   ├── title: "D Vitamini"
  │   ├── subtitle: "Sabah ilacı"
  │   ├── timeLabel: "11:30"
  │   ├── note: "Kahvaltıdan sonra bir bardak su ile alın."
  │   ├── dosage: "1 kapsül"
  │   ├── location: "Mutfak çekmecesi"
  │   ├── category: "medication" (veya "appointment", "activity")
  │   ├── createdAt: "2024-01-15T10:30:00Z"
  │   └── userId: "user123" (opsiyonel - kullanıcı bazlı filtreleme için)
  └── ...
```

### Diğer Modüller İçin Örnek Yapılar:

**Kişi Albümü (Memory Contacts):**
```
memoryContacts (collection)
  ├── {contactId}
  │   ├── name: "Ahmet Yılmaz"
  │   ├── relationship: "Oğul"
  │   ├── phone: "+90 555 123 4567"
  │   ├── photoUrl: "https://..."
  │   └── userId: "user123"
```

**Güvenli Bölgeler (Safe Zones):**
```
safeZones (collection)
  ├── {zoneId}
  │   ├── name: "Ev"
  │   ├── latitude: 41.0082
  │   ├── longitude: 28.9784
  │   ├── radius: 100
  │   └── userId: "user123"
```

## 🧪 Adım 4: Test Verisi Ekleme (Opsiyonel)

Firebase Console'dan manuel olarak test verisi eklemek için:

1. Firestore Database sayfasında **"Start collection"** butonuna tıklayın
2. Collection ID: `reminders` yazın
3. **"Next"** butonuna tıklayın
4. Document ID'yi otomatik oluşturması için **"Auto-ID"** seçin
5. Aşağıdaki alanları ekleyin:
   - `title` (string): "D Vitamini"
   - `subtitle` (string): "Sabah ilacı"
   - `timeLabel` (string): "11:30"
   - `note` (string): "Kahvaltıdan sonra bir bardak su ile alın."
   - `dosage` (string): "1 kapsül"
   - `location` (string): "Mutfak çekmecesi"
   - `category` (string): "medication"
   - `createdAt` (string): "2024-01-15T10:30:00Z"
6. **"Save"** butonuna tıklayın

## 🔧 Adım 5: Flutter Uygulamasında Kullanım

Kod tarafında zaten hazır! `ReminderService` sınıfı oluşturuldu. Kullanım örneği:

```dart
// Servis örneği oluştur
final reminderService = ReminderService();

// Hatırlatıcıları dinle (Stream)
reminderService.getReminders().listen((reminders) {
  print('Toplam ${reminders.length} hatırlatıcı var');
});

// Yeni hatırlatıcı ekle
final newReminder = Reminder(
  title: 'Yeni İlaç',
  subtitle: 'Akşam',
  timeLabel: '20:00',
  note: 'Yemekten sonra',
  dosage: '1 tablet',
  location: 'Mutfak',
  category: ReminderCategory.medication,
);

await reminderService.addReminder(newReminder);

// Hatırlatıcı güncelle
final updatedReminder = Reminder(
  id: 'existing-id',
  title: 'Güncellenmiş Başlık',
  // ... diğer alanlar
);
await reminderService.updateReminder(updatedReminder);

// Hatırlatıcı sil
await reminderService.deleteReminder('reminder-id');
```

## ⚠️ Önemli Notlar

1. **Güvenlik:** Test mode'da tüm kullanıcılar verileri okuyup yazabilir. Production'a geçmeden önce mutlaka güvenlik kurallarını güncelleyin!

2. **Faturalandırma:** Firestore ücretsiz kotası vardır, ancak kullanım limitlerini kontrol edin.

3. **Indexler:** `orderBy` ve `where` sorguları birlikte kullanıldığında composite index oluşturmanız gerekebilir. Firebase Console size otomatik olarak bildirim gönderir.

4. **Kullanıcı Bazlı Veri:** Her veri için `userId` alanı ekleyerek kullanıcıların sadece kendi verilerini görmesini sağlayabilirsiniz.

## 📚 Ek Kaynaklar

- [Firestore Dokümantasyonu](https://firebase.google.com/docs/firestore)
- [Flutter Firestore Paketi](https://pub.dev/packages/cloud_firestore)
- [Güvenlik Kuralları Rehberi](https://firebase.google.com/docs/firestore/security/get-started)

