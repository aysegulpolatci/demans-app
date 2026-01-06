# Demans Asistanı - Veritabanı Tasarımı ve Teknolojileri

## 📊 VERİTABANI MİMARİSİ

### Kullanılan Teknoloji: **Cloud Firestore**

**Cloud Firestore** Google'ın geliştirdiği, NoSQL tabanlı, gerçek zamanlı (real-time) veritabanı servisidir.

#### Özellikler:
- ✅ **NoSQL Yapısı**: Koleksiyon (Collection) ve Doküman (Document) yapısı
- ✅ **Real-time Synchronization**: Veri değişikliklerinin anlık senkronizasyonu
- ✅ **Offline Support**: İnternet bağlantısı olmasa bile cache ile çalışma
- ✅ **Otomatik Ölçeklenebilirlik**: Kullanıcı sayısı arttıkça otomatik ölçeklenme
- ✅ **Güvenlik Kuralları**: Firestore Security Rules ile veri erişim kontrolü
- ✅ **Global CDN**: Dünya çapında hızlı veri erişimi

---

## 🗂️ VERİTABANI ŞEMASI

### 1. **users** Koleksiyonu

Kullanıcı profillerini saklar. Her doküman bir kullanıcıyı temsil eder.

#### Doküman Yapısı:
```json
{
  "name": "Zeynep Korkmaz",
  "email": "zeynep@example.com",
  "role": "patient" | "caregiver",
  "patientId": "hasta_uid_123" (sadece hasta yakını için),
  "createdAt": "2025-12-02T10:30:00Z",
  "updatedAt": "2025-12-02T15:45:00Z"
}
```

#### Alanlar:
- **name** (String, Required): Kullanıcı adı soyadı
- **email** (String, Required): E-posta adresi (unique)
- **role** (String, Required): Kullanıcı rolü
  - `"patient"`: Hasta
  - `"caregiver"`: Hasta yakını
- **patientId** (String, Optional): Hasta yakını için bağlı olduğu hasta UID'si
- **createdAt** (String, Timestamp): Hesap oluşturulma tarihi
- **updatedAt** (String, Timestamp): Son güncelleme tarihi

#### İlişkiler:
- **One-to-Many**: Bir hasta yakını → Bir hasta (patientId ile)
- **One-to-Many**: Bir kullanıcı → Birden fazla hatırlatıcı
- **One-to-Many**: Bir kullanıcı → Birden fazla kişi albümü kaydı

#### Kullanılan Servis:
- `UserService` (`lib/services/user_service.dart`)

#### Örnek Sorgular:
```dart
// Kullanıcı getir (UID ile)
await _firestore.collection('users').doc(uid).get();

// Email'e göre kullanıcı bul
await _firestore.collection('users')
  .where('email', isEqualTo: email)
  .limit(1)
  .get();

// Hasta yakını bul (patientId ile)
await _firestore.collection('users')
  .where('patientId', isEqualTo: patientId)
  .where('role', isEqualTo: 'caregiver')
  .limit(1)
  .get();
```

---

### 2. **reminders** Koleksiyonu

Hatırlatıcıları saklar. Her doküman bir hatırlatıcıyı temsil eder.

#### Doküman Yapısı:
```json
{
  "title": "D Vitamini",
  "subtitle": "Sabah ilacı",
  "timeLabel": "11:30",
  "note": "Kahvaltıdan sonra bir bardak su ile alın.",
  "dosage": "1 kapsül",
  "location": "Mutfak çekmecesi",
  "category": "medication" | "appointment" | "activity",
  "userId": "hasta_uid_123",
  "createdAt": "2025-12-02T10:30:00Z",
  "updatedAt": "2025-12-02T15:45:00Z"
}
```

#### Alanlar:
- **title** (String, Required): Hatırlatıcı başlığı
- **subtitle** (String, Required): Alt başlık/açıklama
- **timeLabel** (String, Required): Zaman (örn: "11:30", "14:00")
- **note** (String, Required): Detaylı not
- **dosage** (String, Required): Dozaj bilgisi (ilaç için)
- **location** (String, Required): Konum bilgisi
- **category** (String, Required): Kategori
  - `"medication"`: İlaç
  - `"appointment"`: Randevu
  - `"activity"`: Aktivite
- **userId** (String, Required): Hangi kullanıcıya ait (hasta UID'si)
- **createdAt** (String, Timestamp): Oluşturulma tarihi
- **updatedAt** (String, Timestamp): Güncelleme tarihi

#### İlişkiler:
- **Many-to-One**: Birden fazla hatırlatıcı → Bir kullanıcı (userId ile)

#### Kullanılan Servis:
- `ReminderService` (`lib/services/reminder_service.dart`)

#### Örnek Sorgular:
```dart
// Kullanıcının tüm hatırlatıcılarını getir
await _firestore.collection('reminders')
  .where('userId', isEqualTo: userId)
  .orderBy('timeLabel')
  .get();

// Kategoriye göre filtrele
await _firestore.collection('reminders')
  .where('userId', isEqualTo: userId)
  .where('category', isEqualTo: 'medication')
  .orderBy('timeLabel')
  .get();

// Real-time stream (anlık güncellemeler)
_firestore.collection('reminders')
  .where('userId', isEqualTo: userId)
  .orderBy('timeLabel')
  .snapshots();
```

---

### 3. **memory_contacts** Koleksiyonu

Kişi albümü verilerini saklar. Her doküman bir kişiyi temsil eder.

#### Doküman Yapısı:
```json
{
  "name": "Ayşe Korkmaz",
  "relationship": "Kızı",
  "description": "Her sabah kahve içip günün planını birlikte yapıyorsunuz.",
  "imageUrl": "https://firebasestorage.googleapis.com/...",
  "lastSeen": "2025-11-26T10:30:00Z",
  "ttsScript": "Bu Ayşe, senin kızın. Her sabah kahve içip gününü birlikte planlıyorsunuz.",
  "isFavorite": true,
  "userId": "hasta_uid_123",
  "createdAt": "2025-12-02T10:30:00Z",
  "updatedAt": "2025-12-02T15:45:00Z"
}
```

#### Alanlar:
- **name** (String, Required): Kişi adı
- **relationship** (String, Required): İlişki (örn: "Kızı", "Oğlu", "Torunu")
- **description** (String, Required): Açıklama
- **imageUrl** (String, Required): Fotoğraf URL'si (Firebase Storage'dan)
- **lastSeen** (String, Timestamp): Son görülme tarihi
- **ttsScript** (String, Required): TTS için seslendirme metni
- **isFavorite** (Boolean, Default: false): Favori işareti
- **userId** (String, Required): Hangi kullanıcıya ait (hasta UID'si)
- **createdAt** (String, Timestamp): Oluşturulma tarihi
- **updatedAt** (String, Timestamp): Güncelleme tarihi

#### İlişkiler:
- **Many-to-One**: Birden fazla kişi → Bir kullanıcı (userId ile)
- **One-to-One**: Bir kişi → Bir fotoğraf (Firebase Storage'da)

#### Kullanılan Servis:
- `MemoryContactService` (`lib/services/memory_contact_service.dart`)

#### Örnek Sorgular:
```dart
// Kullanıcının tüm kişilerini getir
await _firestore.collection('memory_contacts')
  .where('userId', isEqualTo: userId)
  .get();

// Favori kişileri getir
await _firestore.collection('memory_contacts')
  .where('userId', isEqualTo: userId)
  .where('isFavorite', isEqualTo: true)
  .get();

// Real-time stream
_firestore.collection('memory_contacts')
  .where('userId', isEqualTo: userId)
  .snapshots();
```

---

### 4. **patient_info** Koleksiyonu

Hasta detay bilgilerini saklar. Her doküman bir hastanın ek bilgilerini temsil eder.

#### Doküman Yapısı:
```json
{
  "phone": "+90 555 123 4567",
  "address": "Gül Sokak No:12, Moda / İstanbul",
  "birthDate": "1950-05-15",
  "notes": "Özel notlar buraya yazılabilir.",
  "updatedAt": "2025-12-02T15:45:00Z"
}
```

#### Alanlar:
- **phone** (String, Optional): Telefon numarası
- **address** (String, Optional): Adres (ev koordinatı için)
- **birthDate** (String, Optional): Doğum tarihi
- **notes** (String, Optional): Özel notlar
- **updatedAt** (String, Timestamp): Son güncelleme tarihi

#### İlişkiler:
- **One-to-One**: Bir hasta → Bir patient_info dokümanı (patientId = doküman ID'si)

#### Kullanılan Servis:
- `PatientInfoService` (`lib/services/patient_info_service.dart`)

---

## 🔗 İLİŞKİLER VE VERİ AKIŞI

### Kullanıcı-Hasta İlişkisi

```
┌─────────────┐
│   users     │
│             │
│ uid (PK)    │
│ role        │
│ patientId   │──┐
└─────────────┘  │
                 │
                 │ (Foreign Key)
                 │
                 ▼
┌─────────────┐
│   users     │
│             │
│ uid (PK)    │
│ role:patient│
└─────────────┘
```

**Açıklama:**
- Hasta yakını (`caregiver`) kullanıcısının `patientId` alanı, hasta (`patient`) kullanıcısının `uid` değerine referans verir.
- Bu sayede bir hasta yakını, bir hastaya bağlanabilir.

### Kullanıcı-Hatırlatıcı İlişkisi

```
┌─────────────┐         ┌──────────────┐
│   users     │         │  reminders   │
│             │         │              │
│ uid (PK)    │◄────────│ userId (FK)  │
│ role        │         │              │
└─────────────┘         └──────────────┘
```

**Açıklama:**
- Her hatırlatıcı, bir kullanıcıya (`userId`) aittir.
- Hasta yakını, hasta adına hatırlatıcı oluştururken, `userId` olarak hasta UID'sini kullanır.

### Kullanıcı-Kişi Albümü İlişkisi

```
┌─────────────┐         ┌──────────────────┐
│   users     │         │ memory_contacts  │
│             │         │                  │
│ uid (PK)    │◄────────│ userId (FK)      │
│ role        │         │                  │
└─────────────┘         └──────────────────┘
```

**Açıklama:**
- Her kişi albümü kaydı, bir kullanıcıya (`userId`) aittir.
- Hasta yakını, hasta adına kişi eklerken, `userId` olarak hasta UID'sini kullanır.

---

## 🛠️ KULLANILAN TEKNOLOJİLER

### 1. **Cloud Firestore SDK**
- **Paket**: `cloud_firestore: ^6.1.0`
- **Versiyon**: 6.1.0
- **Açıklama**: Firestore veritabanına erişim için Flutter SDK

#### Özellikler:
- Real-time listeners (`snapshots()`)
- Offline persistence
- Transaction desteği
- Batch operations
- Query filtering ve sorting

### 2. **Firebase Core**
- **Paket**: `firebase_core: ^4.2.1`
- **Açıklama**: Firebase servislerinin temel başlatma paketi

### 3. **Model-View-Service (MVS) Pattern**

Projede kullanılan mimari desen:

```
Model (lib/models/)          Service (lib/services/)          View (lib/screens/)
─────────────────            ─────────────────────            ──────────────────
AppUser                      UserService                      LoginPage
Reminder                     ReminderService                  ReminderDashboard
MemoryContact                MemoryContactService             AlbumPage
PatientInfo                  PatientInfoService               ProfileSettingsPage
```

---

## 📝 VERİ DÖNÜŞÜMLERİ

### Model → Firestore (toMap)

Her model sınıfında `toMap()` metodu ile Firestore'a kayıt için Map dönüşümü yapılır:

```dart
// Örnek: Reminder modeli
Map<String, dynamic> toMap() {
  return {
    'title': title,
    'subtitle': subtitle,
    'timeLabel': timeLabel,
    'note': note,
    'dosage': dosage,
    'location': location,
    'category': category.name,
    'createdAt': DateTime.now().toIso8601String(),
    'userId': userId,
  };
}
```

### Firestore → Model (fromFirestore)

Her model sınıfında `fromFirestore()` factory metodu ile Firestore'dan gelen veri model nesnesine dönüştürülür:

```dart
// Örnek: Reminder modeli
factory Reminder.fromFirestore(Map<String, dynamic> data, {String? id}) {
  final categoryStr = (data['category'] as String?) ?? 'medication';
  final category = ReminderCategory.values.firstWhere(
    (c) => c.name == categoryStr,
    orElse: () => ReminderCategory.medication,
  );

  return Reminder(
    id: id,
    title: data['title'] as String? ?? '',
    subtitle: data['subtitle'] as String? ?? '',
    // ...
  );
}
```

---

## 🔄 REAL-TIME UPDATES

### StreamBuilder Kullanımı

Firestore'un real-time özelliği, `StreamBuilder` widget'ı ile kullanılır:

```dart
StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('reminders')
      .where('userId', isEqualTo: userId)
      .snapshots(),
  builder: (context, snapshot) {
    if (snapshot.hasError) {
      return Text('Hata: ${snapshot.error}');
    }
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }
    
    final reminders = snapshot.data!.docs
        .map((doc) => Reminder.fromFirestore(
            doc.data() as Map<String, dynamic>, id: doc.id))
        .toList();
    
    return ListView.builder(
      itemCount: reminders.length,
      itemBuilder: (context, index) {
        return ReminderTile(reminder: reminders[index]);
      },
    );
  },
)
```

**Avantajlar:**
- Veri değişiklikleri anında UI'da görünür
- Manuel refresh gerekmez
- Offline durumda cache'den çalışır

---

## 🔒 GÜVENLİK KURALLARI (Security Rules)

Firestore Security Rules ile veri erişim kontrolü yapılır:

### Örnek Güvenlik Kuralları:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // users koleksiyonu
    match /users/{userId} {
      // Kullanıcı sadece kendi verisini okuyup yazabilir
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // reminders koleksiyonu
    match /reminders/{reminderId} {
      // Sadece giriş yapmış kullanıcılar okuyabilir
      allow read: if request.auth != null;
      // Sadece kendi userId'sine sahip hatırlatıcıları yazabilir
      allow create: if request.auth != null 
        && request.resource.data.userId == request.auth.uid;
      allow update, delete: if request.auth != null 
        && resource.data.userId == request.auth.uid;
    }
    
    // memory_contacts koleksiyonu
    match /memory_contacts/{contactId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null 
        && request.resource.data.userId == request.auth.uid;
      allow update, delete: if request.auth != null 
        && resource.data.userId == request.auth.uid;
    }
  }
}
```

---

## 📊 İNDEKS YÖNETİMİ

Firestore, karmaşık sorgular için composite index gerektirir:

### Gerekli İndeksler:

1. **reminders koleksiyonu:**
   - `userId` (Ascending) + `timeLabel` (Ascending)
   - `userId` (Ascending) + `category` (Ascending) + `timeLabel` (Ascending)

2. **memory_contacts koleksiyonu:**
   - `userId` (Ascending) + `isFavorite` (Ascending)

**Not:** İndeksler Firebase Console'dan otomatik oluşturulabilir veya `firestore.indexes.json` dosyası ile tanımlanabilir.

---

## 💾 OFFLINE DESTEĞİ

Firestore, offline durumda da çalışabilir:

### Özellikler:
- **Cache Persistence**: Veriler cihazda cache'lenir
- **Offline Queries**: İnternet yokken cache'den sorgu yapılabilir
- **Sync**: İnternet bağlantısı geldiğinde otomatik senkronizasyon

### Kullanım:
```dart
// Offline persistence etkinleştirme (main.dart'ta)
await FirebaseFirestore.instance.enablePersistence();
```

---

## 🚀 PERFORMANS OPTİMİZASYONU

### 1. **Query Optimization**
- Gereksiz `orderBy` kaldırıldı (client-side sorting)
- `limit()` kullanımı ile sayfalama
- `whereIn` kullanımında max 10 eleman limiti

### 2. **Stream Error Handling**
```dart
.snapshots()
.map((snapshot) => ...)
.handleError((error) {
  print('Firestore hatası: $error');
  return <Model>[]; // Boş liste döndür
});
```

### 3. **Batch Operations**
Birden fazla işlemi tek seferde yapmak için:
```dart
final batch = _firestore.batch();
batch.set(docRef1, data1);
batch.set(docRef2, data2);
await batch.commit();
```

---

## 📈 ÖLÇEKLENEBİLİRLİK

### Firestore Avantajları:
- **Otomatik Ölçeklenebilirlik**: Kullanıcı sayısı arttıkça otomatik ölçeklenir
- **Global CDN**: Dünya çapında hızlı erişim
- **Yüksek Kullanılabilirlik**: %99.95 uptime garantisi
- **Otomatik Yedekleme**: Veriler otomatik yedeklenir

### Limitler:
- **Doküman boyutu**: Max 1 MB
- **Koleksiyon adı**: Max 6144 karakter
- **whereIn**: Max 10 eleman
- **Query derinliği**: Max 100 seviye

---

## 🔍 SORGULAMA ÖRNEKLERİ

### 1. Kullanıcının Bugünkü Hatırlatıcıları
```dart
final today = DateTime.now();
final startOfDay = DateTime(today.year, today.month, today.day);
final endOfDay = startOfDay.add(Duration(days: 1));

await _firestore.collection('reminders')
  .where('userId', isEqualTo: userId)
  .where('createdAt', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
  .where('createdAt', isLessThan: endOfDay.toIso8601String())
  .get();
```

### 2. Favori Kişiler
```dart
await _firestore.collection('memory_contacts')
  .where('userId', isEqualTo: userId)
  .where('isFavorite', isEqualTo: true)
  .get();
```

### 3. Kategoriye Göre Hatırlatıcılar
```dart
await _firestore.collection('reminders')
  .where('userId', isEqualTo: userId)
  .where('category', isEqualTo: 'medication')
  .orderBy('timeLabel')
  .get();
```

---

## 📦 DOSYA DEPOLAMA (Firebase Storage)

Kişi albümü fotoğrafları Firebase Storage'da saklanır:

### Storage Yapısı:
```
memory_contacts/
  └── {contactId}/
      └── photo.jpg
```

### Kullanılan Paket:
- `firebase_storage: ^13.0.4`

### Örnek Kullanım:
```dart
// Fotoğraf yükleme
final ref = FirebaseStorage.instance
    .ref()
    .child('memory_contacts')
    .child(contactId)
    .child('photo.jpg');
    
await ref.putFile(imageFile);
final imageUrl = await ref.getDownloadURL();
```

---

## 🎯 SONUÇ

### Veritabanı Tasarım Prensipleri:
1. ✅ **NoSQL Yapısı**: Koleksiyon ve doküman yapısı
2. ✅ **Real-time Updates**: StreamBuilder ile anlık güncellemeler
3. ✅ **User-based Data**: Her veri kullanıcıya özel (userId ile)
4. ✅ **Role-based Access**: Hasta/Hasta yakını rolleri
5. ✅ **Scalable Design**: Otomatik ölçeklenebilir yapı
6. ✅ **Offline Support**: Cache ile offline çalışma
7. ✅ **Security Rules**: Güvenli veri erişimi

### Kullanılan Teknolojiler:
- **Cloud Firestore** (NoSQL Database)
- **Firebase Storage** (File Storage)
- **Firebase Authentication** (User Management)
- **Flutter Firestore SDK** (Client Library)

Bu tasarım, demans hastaları ve hasta yakınları için güvenli, ölçeklenebilir ve gerçek zamanlı bir veri yönetimi sağlar.

