# Firestore Veri Ekleme Rehberi

Bu rehber, Firestore veritabanına veri eklemenin farklı yöntemlerini açıklar.

## 📱 Yöntem 1: Uygulama Üzerinden (Önerilen)

### Hatırlatıcı Ekleme:
1. **Hasta Yakını** olarak giriş yapın
2. Ana ekranda **"Hatırlatıcılar"** sekmesine gidin
3. Sağ alttaki **"Yeni hatırlatıcı"** butonuna tıklayın
4. Formu doldurun:
   - Kategori seçin (İlaç, Randevu, Görev)
   - Başlık girin (zorunlu)
   - Alt başlık girin
   - Saat girin (zorunlu, örn: "11:30")
   - Not ekleyin
   - Doz/Miktar girin
   - Konum girin
5. **"Kaydet"** butonuna tıklayın
6. Veri otomatik olarak Firestore'a eklenir

### Kullanıcı Kaydı:
- Kayıt ol ekranından yeni hesap oluşturduğunuzda kullanıcı bilgileri otomatik olarak Firestore'a eklenir.

---

## 🖥️ Yöntem 2: Firebase Console'dan Manuel Ekleme

### Adım 1: Firebase Console'a Giriş
1. [Firebase Console](https://console.firebase.google.com/) adresine gidin
2. Projenizi seçin (demans-asistan)
3. Sol menüden **"Firestore Database"** seçeneğine tıklayın
4. **"Data"** sekmesine gidin

### Adım 2: Hatırlatıcı (Reminder) Ekleme

#### İlk Koleksiyonu Oluşturma:
1. **"+ Start collection"** butonuna tıklayın
2. **Collection ID:** `reminders` yazın
3. **"Next"** butonuna tıklayın

#### Doküman Ekleme:
1. **Document ID:** Auto-ID seçili bırakın (otomatik ID oluşturulur)
2. Aşağıdaki alanları ekleyin:

| Field | Type | Value |
|-------|------|-------|
| `title` | string | "D Vitamini" |
| `subtitle` | string | "Sabah ilacı" |
| `timeLabel` | string | "11:30" |
| `note` | string | "Kahvaltıdan sonra bir bardak su ile alın." |
| `dosage` | string | "1 kapsül" |
| `location` | string | "Mutfak çekmecesi" |
| `category` | string | "medication" (veya "appointment", "activity") |
| `createdAt` | string | "2024-01-15T10:30:00Z" |
| `userId` | string | (opsiyonel) Kullanıcı ID'si |

3. **"Save"** butonuna tıklayın

#### Yeni Doküman Ekleme:
- Mevcut koleksiyonda **"+ Add document"** butonuna tıklayın
- Yukarıdaki adımları tekrarlayın

### Adım 3: Kullanıcı (User) Ekleme

#### Koleksiyon Oluşturma:
1. **"+ Start collection"** butonuna tıklayın
2. **Collection ID:** `users` yazın
3. **"Next"** butonuna tıklayın

#### Doküman Ekleme:
1. **Document ID:** Kullanıcının Firebase Auth UID'sini girin (Authentication sayfasından alabilirsiniz)
2. Aşağıdaki alanları ekleyin:

| Field | Type | Value |
|-------|------|-------|
| `name` | string | "Ayşegül Polatçı" |
| `email` | string | "aysegul@example.com" |
| `role` | string | "patient" veya "caregiver" |
| `patientId` | string | (opsiyonel) Hasta yakını ise, bağlı olduğu hasta ID'si |
| `createdAt` | string | "2024-01-15T10:30:00Z" |

3. **"Save"** butonuna tıklayın

---

## 📋 Veri Yapıları

### Reminders Koleksiyonu Yapısı:
```
reminders (collection)
  ├── {auto-generated-id} (document)
  │   ├── title: "D Vitamini" (string)
  │   ├── subtitle: "Sabah ilacı" (string)
  │   ├── timeLabel: "11:30" (string)
  │   ├── note: "Kahvaltıdan sonra..." (string)
  │   ├── dosage: "1 kapsül" (string)
  │   ├── location: "Mutfak çekmecesi" (string)
  │   ├── category: "medication" (string)
  │   ├── createdAt: "2024-01-15T10:30:00Z" (string)
  │   └── userId: "user123" (string, opsiyonel)
  └── ...
```

### Users Koleksiyonu Yapısı:
```
users (collection)
  ├── {firebase-auth-uid} (document)
  │   ├── name: "Ayşegül Polatçı" (string)
  │   ├── email: "aysegul@example.com" (string)
  │   ├── role: "patient" veya "caregiver" (string)
  │   ├── patientId: "patient-uid" (string, opsiyonel)
  │   └── createdAt: "2024-01-15T10:30:00Z" (string)
  └── ...
```

---

## 🎯 Kategori Değerleri

Hatırlatıcılar için `category` alanı şu değerlerden biri olmalı:
- `"medication"` - İlaç
- `"appointment"` - Randevu
- `"activity"` - Görev/Aktivite

---

## ⚠️ Önemli Notlar

1. **Document ID:**
   - Reminders için: Auto-ID kullanın (otomatik oluşturulur)
   - Users için: Firebase Authentication UID'sini kullanın

2. **Tarih Formatı:**
   - ISO 8601 formatı kullanın: `"2024-01-15T10:30:00Z"`
   - Veya: `DateTime.now().toIso8601String()` formatı

3. **Güvenlik:**
   - Güvenlik kurallarınızın doğru ayarlandığından emin olun
   - Sadece giriş yapmış kullanıcılar veri ekleyebilir

4. **Test Verisi:**
   - Test için birkaç hatırlatıcı ekleyin
   - Uygulamada göründüğünü kontrol edin

---

## 🔍 Veri Kontrolü

Verilerin doğru eklendiğini kontrol etmek için:
1. Firebase Console → Firestore Database → Data sekmesine gidin
2. Koleksiyonları görüntüleyin
3. Dokümanları açıp alanları kontrol edin
4. Uygulamada verilerin göründüğünü doğrulayın

---

## 💡 İpuçları

- **Toplu Ekleme:** Firebase Console'dan manuel olarak birden fazla doküman ekleyebilirsiniz
- **Import/Export:** Firebase Console'dan verileri JSON formatında export edebilirsiniz
- **Test Verisi:** Geliştirme aşamasında test verileri ekleyerek uygulamayı test edebilirsiniz

