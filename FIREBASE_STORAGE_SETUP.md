# Firebase Storage Kurulum Rehberi

Bu rehber, Firebase Storage'ı etkinleştirmek ve güvenlik kurallarını ayarlamak için adımları içerir.

## 📋 Adım 1: Firebase Console'da Storage'ı Etkinleştir

1. [Firebase Console](https://console.firebase.google.com/) adresine gidin
2. Projenizi seçin (demans-asistan)
3. Sol menüden **"Storage"** seçeneğine tıklayın
4. **"Get started"** butonuna tıklayın
5. **"Start in test mode"** veya **"Start in production mode"** seçin
6. Storage bucket konumunu seçin (örn: `europe-west1`)
7. **"Done"** butonuna tıklayın

## 🔒 Adım 2: Güvenlik Kurallarını Ayarla

Firebase Console'da Storage sekmesinde **"Rules"** sekmesine gidin ve aşağıdaki kuralları ekleyin:

### Test Modu (Geliştirme için):
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Production Modu (Güvenli):
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Memory contacts klasörü - sadece kendi dosyalarını yükleyebilir
    match /memory_contacts/{userId}_{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null 
                   && request.auth.uid == userId.split('_')[0];
    }
    
    // Diğer klasörler için genel kural
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**Önemli:** Production modunda, kullanıcılar sadece kendi dosyalarını yükleyebilir ve silebilir.

## ✅ Adım 3: Kuralları Yayınla

1. Kuralları yazdıktan sonra **"Publish"** butonuna tıklayın
2. Kuralların aktif olması birkaç saniye sürebilir

## 🧪 Adım 4: Test Et

1. Uygulamayı çalıştırın
2. Hasta yakını olarak giriş yapın
3. "Kişi Albümü" sekmesine gidin
4. "Fotoğraf yükle" butonuna tıklayın
5. Bir fotoğraf seçin ve bilgileri doldurun
6. "Kaydet" butonuna tıklayın
7. Firebase Console'da Storage sekmesinde yüklenen fotoğrafı görebilmelisiniz

## 🔍 Sorun Giderme

### Hata: "permission-denied"
- **Çözüm:** Firebase Console'da Storage güvenlik kurallarını kontrol edin
- Kullanıcının giriş yaptığından emin olun

### Hata: "storage/object-not-found"
- **Çözüm:** Storage bucket'ın doğru yapılandırıldığından emin olun
- `firebase_options.dart` dosyasında `storageBucket` değerini kontrol edin

### Hata: "network-error"
- **Çözüm:** İnternet bağlantınızı kontrol edin
- Emülatör/cihazın internete bağlı olduğundan emin olun

## 📝 Notlar

- Storage'da yüklenen dosyalar için otomatik olarak benzersiz isimler oluşturulur
- Format: `{userId}_{timestamp}.jpg`
- Her kullanıcı sadece kendi dosyalarını görebilir ve yönetebilir
- Storage kullanımı Firebase ücretsiz planında sınırlıdır (5 GB)

