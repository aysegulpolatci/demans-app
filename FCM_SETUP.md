# Firebase Cloud Messaging (FCM) Kurulum Rehberi

Bu rehber, Firebase Cloud Messaging entegrasyonunun nasıl tamamlanacağını açıklar.

## ✅ Tamamlanan Özellikler

1. **FCM Paketi Eklendi**: `firebase_messaging: ^16.0.4`
2. **FCM Servisi Oluşturuldu**: `lib/services/fcm_service.dart`
3. **Android Konfigürasyonu**: `AndroidManifest.xml` güncellendi
4. **iOS Konfigürasyonu**: `AppDelegate.swift` ve `Info.plist` güncellendi
5. **Emergency Sayfası Entegrasyonu**: Acil durum bildirimleri için FCM entegre edildi
6. **Token Yönetimi**: FCM token'ları Firestore'a otomatik kaydediliyor

## 📱 Nasıl Çalışır?

### 1. Token Yönetimi
- Uygulama başlatıldığında FCM token'ı otomatik olarak alınır
- Token Firestore'daki `fcm_tokens` koleksiyonuna kaydedilir
- Token yenilendiğinde otomatik olarak güncellenir

### 2. Bildirim Alma
- **Foreground**: Uygulama açıkken gelen bildirimler local notification olarak gösterilir
- **Background**: Uygulama arka plandayken bildirimler otomatik gösterilir
- **Terminated**: Uygulama kapalıyken bildirime tıklandığında uygulama açılır

### 3. Bildirim Gönderme
Şu anda `FcmService.sendNotificationToUser()` metodu Firestore'a bildirim isteği kaydediyor. Gerçek push notification göndermek için aşağıdaki yöntemlerden birini kullanmanız gerekir:

#### Seçenek 1: Firebase Cloud Functions (Önerilen)

Firebase Console'da Cloud Functions oluşturun:

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendNotification = functions.firestore
  .document('notification_requests/{requestId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    
    // FCM token'ı al
    const tokenDoc = await admin.firestore()
      .collection('fcm_tokens')
      .doc(data.targetUserId)
      .get();
    
    if (!tokenDoc.exists) {
      console.log('Token bulunamadı');
      return null;
    }
    
    const token = tokenDoc.data().token;
    
    // Bildirim gönder
    const message = {
      notification: {
        title: data.title,
        body: data.body,
      },
      data: {
        ...data.data,
        type: data.data.type || 'default',
      },
      token: token,
    };
    
    try {
      await admin.messaging().send(message);
      console.log('Bildirim gönderildi');
      
      // İsteği tamamlandı olarak işaretle
      await snap.ref.update({ status: 'completed' });
    } catch (error) {
      console.error('Bildirim gönderme hatası:', error);
      await snap.ref.update({ status: 'failed', error: error.message });
    }
    
    return null;
  });
```

#### Seçenek 2: Backend Servisi

Kendi backend servisinizde Firestore'daki `notification_requests` koleksiyonunu dinleyin ve FCM Admin SDK kullanarak bildirim gönderin.

## 🔧 Firebase Console Ayarları

### 1. Cloud Messaging'i Etkinleştirin
1. Firebase Console'a gidin: https://console.firebase.google.com/
2. Projenizi seçin
3. Sol menüden **Build** > **Cloud Messaging** seçin
4. Cloud Messaging'in etkin olduğundan emin olun

### 2. Android için Google Services JSON
- `android/app/google-services.json` dosyasının Firebase Console'dan indirilip projeye eklendiğinden emin olun

### 3. iOS için APNs Sertifikası
- Apple Developer Console'dan APNs sertifikası oluşturun
- Firebase Console'da **Project Settings** > **Cloud Messaging** > **iOS** bölümüne sertifikayı yükleyin

## 📋 Firestore Koleksiyonları

### `fcm_tokens` Koleksiyonu
Her kullanıcının FCM token'ı burada saklanır:
```json
{
  "token": "fcm_token_here",
  "userId": "user_uid",
  "updatedAt": "timestamp"
}
```

### `notification_requests` Koleksiyonu
Bildirim istekleri burada saklanır (Cloud Function tarafından işlenir):
```json
{
  "targetUserId": "user_uid",
  "title": "Bildirim Başlığı",
  "body": "Bildirim İçeriği",
  "data": {
    "type": "emergency",
    "patientId": "patient_uid"
  },
  "createdAt": "timestamp",
  "status": "pending"
}
```

## 🔒 Firestore Güvenlik Kuralları

`fcm_tokens` koleksiyonu için güvenlik kuralları:

```javascript
match /fcm_tokens/{userId} {
  allow read: if request.auth != null && request.auth.uid == userId;
  allow write: if request.auth != null && request.auth.uid == userId;
}

match /notification_requests/{requestId} {
  allow read: if request.auth != null;
  allow create: if request.auth != null;
  allow update: if request.auth != null; // Cloud Function için
  allow delete: if request.auth != null;
}
```

## 🧪 Test Etme

### 1. Token Kontrolü
Uygulamayı çalıştırdıktan sonra Firestore'da `fcm_tokens` koleksiyonunu kontrol edin. Token'ınızın kaydedildiğini görmelisiniz.

### 2. Test Bildirimi Gönderme
Firebase Console'dan manuel olarak test bildirimi gönderebilirsiniz:
1. Firebase Console > Cloud Messaging
2. "Send your first message" butonuna tıklayın
3. Bildirim başlığı ve içeriğini girin
4. "Send test message" butonuna tıklayın
5. FCM token'ınızı girin ve gönderin

### 3. Acil Durum Bildirimi Testi
1. Hasta hesabıyla giriş yapın
2. Acil Durum sayfasına gidin
3. "Bildirim" butonuna tıklayın
4. Firestore'da `notification_requests` koleksiyonunu kontrol edin
5. Cloud Function çalışıyorsa bildirim gönderilir

## 📝 Notlar

- **Cloud Functions**: Gerçek push notification göndermek için Cloud Functions kurulumu gereklidir
- **Token Yenileme**: Token'lar otomatik olarak yenilenir ve Firestore'a kaydedilir
- **Çıkış Yapma**: Kullanıcı çıkış yaptığında token silinir (şu anda `FcmService.deleteToken()` metodu mevcut ama çağrılmıyor, gerekirse `AuthService`'e entegre edilebilir)

## 🚀 Sonraki Adımlar

1. Firebase Cloud Functions kurulumunu yapın
2. APNs sertifikasını iOS için yükleyin
3. Firestore güvenlik kurallarını güncelleyin
4. Test bildirimleri gönderin
5. Production'a deploy edin

