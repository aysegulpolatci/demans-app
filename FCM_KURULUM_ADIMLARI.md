# Firebase Cloud Messaging (FCM) - Adım Adım Kurulum Rehberi

## 🎯 Önce Run Edin ve Test Edin

Önce uygulamayı çalıştırıp temel işlevselliği test edin:

```bash
flutter run
```

Uygulama açıldıktan sonra:
1. Giriş yapın
2. Firebase Console'a gidin: https://console.firebase.google.com/
3. Projenizi seçin: **demans-asistan**
4. Sol menüden **Firestore Database** seçin
5. `fcm_tokens` koleksiyonunu kontrol edin
6. Token'ınızın kaydedildiğini görmelisiniz ✅

---

## 📋 Adım 1: Firebase Console'da Cloud Messaging'i Etkinleştirin

### 1.1 Firebase Console'a Giriş
1. Tarayıcınızda şu adrese gidin: https://console.firebase.google.com/
2. **demans-asistan** projenizi seçin

### 1.2 Cloud Messaging'i Kontrol Edin
1. Sol menüden **Build** (Yapı) sekmesine tıklayın
2. **Cloud Messaging** seçeneğine tıklayın
3. Eğer ilk kez açıyorsanız, "Get started" butonuna tıklayın
4. Cloud Messaging'in etkin olduğundan emin olun

**✅ Bu adım tamamlandığında:** Cloud Messaging servisi aktif olacak.

---

## 📋 Adım 2: Firestore Güvenlik Kurallarını Güncelleyin

### 2.1 Firestore Console'a Gidin
1. Firebase Console'da sol menüden **Firestore Database** seçin
2. **Rules** (Kurallar) sekmesine tıklayın

### 2.2 Mevcut Kuralları Bulun
Şu anda muhtemelen şöyle bir kural var:
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

### 2.3 Kuralları Güncelleyin
Mevcut kurallarınızın sonuna şunları ekleyin:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Mevcut kurallarınız burada
    
    // FCM Token'ları için kurallar
    match /fcm_tokens/{userId} {
      // Kullanıcı sadece kendi token'ını okuyabilir/yazabilir
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Bildirim istekleri için kurallar
    match /notification_requests/{requestId} {
      // Giriş yapmış kullanıcılar okuyabilir ve oluşturabilir
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      // Cloud Function güncelleme yapabilir (admin)
      allow update: if request.auth != null;
      allow delete: if request.auth != null;
    }
  }
}
```

### 2.4 Kuralları Kaydedin
1. **Publish** (Yayınla) butonuna tıklayın
2. Onaylayın

**✅ Bu adım tamamlandığında:** Firestore güvenlik kuralları FCM için hazır olacak.

---

## 📋 Adım 3: Cloud Functions Kurulumu (Gerçek Push Notification İçin)

> ⚠️ **Not:** Bu adım opsiyoneldir ama gerçek push notification göndermek için gereklidir. Şimdilik atlayabilirsiniz, daha sonra yapabilirsiniz.

### 3.1 Node.js Kurulumu
Cloud Functions için Node.js gereklidir:
1. Node.js'i indirin: https://nodejs.org/ (v18 veya üzeri)
2. Kurulumu tamamlayın
3. Terminal'de kontrol edin:
   ```bash
   node --version
   npm --version
   ```

### 3.2 Firebase CLI Kurulumu
1. Terminal'de şu komutu çalıştırın:
   ```bash
   npm install -g firebase-tools
   ```
2. Firebase'e giriş yapın:
   ```bash
   firebase login
   ```
3. Tarayıcı açılacak, Google hesabınızla giriş yapın

### 3.3 Projeye Cloud Functions Ekleme
1. Proje klasörünüzde terminal açın:
   ```bash
   cd C:\Users\Aysegul\Desktop\DemansApp\demansapp
   ```
2. Firebase projesini başlatın:
   ```bash
   firebase init functions
   ```
3. Sorulara şu şekilde cevap verin:
   - **Select a Firebase project:** demans-asistan (mevcut projenizi seçin)
   - **What language would you like to use?** JavaScript
   - **Do you want to use ESLint?** No (veya Yes, tercihinize göre)
   - **Do you want to install dependencies?** Yes

### 3.4 Cloud Function Kodunu Yazma
1. `functions/index.js` dosyasını açın (veya oluşturun)
2. Şu kodu ekleyin:

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendNotification = functions.firestore
  .document('notification_requests/{requestId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    
    console.log('Bildirim isteği alındı:', data);
    
    // FCM token'ı al
    const tokenDoc = await admin.firestore()
      .collection('fcm_tokens')
      .doc(data.targetUserId)
      .get();
    
    if (!tokenDoc.exists) {
      console.log('Token bulunamadı:', data.targetUserId);
      await snap.ref.update({ 
        status: 'failed', 
        error: 'Token bulunamadı' 
      });
      return null;
    }
    
    const token = tokenDoc.data().token;
    console.log('Token bulundu:', token);
    
    // Bildirim mesajı oluştur
    const message = {
      notification: {
        title: data.title,
        body: data.body,
      },
      data: {
        type: data.data?.type || 'default',
        patientId: data.data?.patientId || '',
        patientName: data.data?.patientName || '',
        ...data.data,
      },
      token: token,
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'high_importance_channel',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };
    
    try {
      const response = await admin.messaging().send(message);
      console.log('Bildirim başarıyla gönderildi:', response);
      
      // İsteği tamamlandı olarak işaretle
      await snap.ref.update({ 
        status: 'completed',
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        messageId: response,
      });
    } catch (error) {
      console.error('Bildirim gönderme hatası:', error);
      await snap.ref.update({ 
        status: 'failed', 
        error: error.message,
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    
    return null;
  });
```

### 3.5 Cloud Function'ı Deploy Etme
1. Terminal'de şu komutu çalıştırın:
   ```bash
   firebase deploy --only functions
   ```
2. İlk deploy biraz zaman alabilir (5-10 dakika)
3. Başarılı olduğunda terminal'de URL göreceksiniz

**✅ Bu adım tamamlandığında:** Gerçek push notification gönderme aktif olacak.

---

## 📋 Adım 4: iOS için APNs Sertifikası (Sadece iOS Kullanıyorsanız)

> ⚠️ **Not:** Şu anda Android üzerinde çalışıyorsanız bu adımı atlayabilirsiniz.

### 4.1 Apple Developer Console'a Giriş
1. https://developer.apple.com/account/ adresine gidin
2. Apple Developer hesabınızla giriş yapın

### 4.2 APNs Key Oluşturma
1. **Certificates, Identifiers & Profiles** bölümüne gidin
2. **Keys** sekmesine tıklayın
3. **+** butonuna tıklayın
4. Key adı girin (örn: "DemansApp APNs Key")
5. **Apple Push Notifications service (APNs)** seçeneğini işaretleyin
6. **Continue** ve **Register** butonlarına tıklayın
7. **Download** butonuna tıklayın (sadece bir kez indirebilirsiniz!)
8. `.p8` dosyasını güvenli bir yere kaydedin

### 4.3 Firebase Console'a APNs Key Yükleme
1. Firebase Console'a gidin
2. **Project Settings** (Proje Ayarları) > **Cloud Messaging** sekmesine gidin
3. **iOS app configuration** bölümüne scroll edin
4. **APNs Authentication Key** bölümünde:
   - **Upload** butonuna tıklayın
   - İndirdiğiniz `.p8` dosyasını seçin
   - **Key ID**'yi girin (Apple Developer Console'da görebilirsiniz)
   - **Team ID**'yi girin (Apple Developer Console'da görebilirsiniz)
5. **Upload** butonuna tıklayın

**✅ Bu adım tamamlandığında:** iOS cihazlarda push notification çalışacak.

---

## 🧪 Test Etme

### Test 1: Token Kaydı
1. Uygulamayı çalıştırın: `flutter run`
2. Giriş yapın
3. Firebase Console > Firestore Database > `fcm_tokens` koleksiyonunu kontrol edin
4. Token'ınızın kaydedildiğini görmelisiniz ✅

### Test 2: Firebase Console'dan Manuel Bildirim
1. Firebase Console > **Cloud Messaging** sekmesine gidin
2. **Send your first message** butonuna tıklayın
3. Bildirim başlığı: "Test Bildirimi"
4. Bildirim metni: "Bu bir test bildirimidir"
5. **Send test message** butonuna tıklayın
6. Firestore'dan token'ınızı kopyalayın ve yapıştırın
7. **Test** butonuna tıklayın
8. Cihazınızda bildirimi görmelisiniz ✅

### Test 3: Acil Durum Bildirimi (Cloud Function Kuruluysa)
1. Hasta hesabıyla giriş yapın
2. Acil Durum sayfasına gidin
3. **Bildirim** butonuna tıklayın
4. Firestore > `notification_requests` koleksiyonunu kontrol edin
5. İsteğin `status: 'completed'` olarak güncellendiğini görmelisiniz
6. Hasta yakını cihazında bildirimi görmelisiniz ✅

---

## 📝 Özet

✅ **Adım 1:** Cloud Messaging etkinleştirildi  
✅ **Adım 2:** Firestore güvenlik kuralları güncellendi  
⏳ **Adım 3:** Cloud Functions kurulumu (opsiyonel, daha sonra yapılabilir)  
⏳ **Adım 4:** APNs sertifikası (sadece iOS için, daha sonra yapılabilir)

**Şimdilik Adım 1 ve 2'yi yapmanız yeterli!** Cloud Functions ve APNs'i daha sonra ekleyebilirsiniz.

---

## ❓ Sorun Giderme

### Token kaydedilmiyor
- Firestore güvenlik kurallarını kontrol edin
- Uygulamanın internet bağlantısı olduğundan emin olun
- Firebase Console'da Firestore'un etkin olduğundan emin olun

### Bildirim gelmiyor
- Cloud Functions kurulu mu kontrol edin
- `notification_requests` koleksiyonunda `status` alanını kontrol edin
- Firebase Console > Functions sekmesinde hata var mı kontrol edin

### iOS'ta bildirim gelmiyor
- APNs sertifikası yüklü mü kontrol edin
- iOS cihazda bildirim izinleri verilmiş mi kontrol edin

