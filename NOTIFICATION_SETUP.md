# Bildirim Sistemi Kurulum Rehberi

Bu rehber, hatırlatıcı bildirimlerinin nasıl çalıştığını ve yapılandırmasını açıklar.

## ✅ Tamamlanan Özellikler

1. **NotificationService** servisi oluşturuldu
2. **Local notifications** entegrasyonu yapıldı
3. **Otomatik bildirim zamanlama** sistemi eklendi
4. **Android izinleri** yapılandırıldı

## 📱 Android Yapılandırması

### AndroidManifest.xml
Aşağıdaki izinler `android/app/src/main/AndroidManifest.xml` dosyasına eklendi:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
```

### Bildirim Kanalı
- **Kanal ID:** `reminder_channel`
- **Kanal Adı:** "Hatırlatıcı Bildirimleri"
- **Önem:** High
- **Ses:** Açık
- **Titreşim:** Açık

## 🍎 iOS Yapılandırması

### Info.plist
`ios/Runner/Info.plist` dosyasına aşağıdaki izinler eklenmelidir:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

### Bildirim İzinleri
iOS'ta bildirim izinleri uygulama ilk açıldığında otomatik olarak istenir. `NotificationService.requestPermissions()` metodu çağrılıyor.

## 🔔 Bildirim Nasıl Çalışır?

### 1. Uygulama Başlatıldığında
- `main.dart` içinde `NotificationService` başlatılır
- Bildirim izinleri istenir (iOS için)
- Timezone ayarları yapılır (Europe/Istanbul)

### 2. Hatırlatıcılar Yüklendiğinde
- `ReminderDashboard` içinde `StreamBuilder` hatırlatıcıları dinler
- Hatırlatıcılar değiştiğinde otomatik olarak bildirimler zamanlanır
- Her hatırlatıcı için günlük tekrarlayan bildirim oluşturulur

### 3. Bildirim Zamanlama
- `timeLabel` formatı: "HH:mm" (örn: "11:30")
- Eğer zaman geçmişse, yarın için zamanlanır
- Her gün aynı saatte tekrarlanır (`DateTimeComponents.time`)

### 4. Bildirim İçeriği
- **Başlık:** Kategori emojisi + Hatırlatıcı başlığı
  - 💊 İlaç
  - 🏥 Randevu
  - ✅ Görev
- **İçerik:** Alt başlık veya not

## 🎯 Kullanım

### Bildirim Zamanlama
```dart
final notificationService = NotificationService();
await notificationService.initialize();

// Tek bir hatırlatıcı için
await notificationService.scheduleReminderNotification(reminder);

// Tüm hatırlatıcılar için
await notificationService.scheduleAllReminders(reminders);
```

### Bildirim İptal Etme
```dart
// Tek bir hatırlatıcı için
await notificationService.cancelReminderNotification(reminderId);

// Tüm bildirimler için
await notificationService.cancelAllNotifications();
```

## ⚠️ Önemli Notlar

1. **Android 13+ (API 33+)**
   - `POST_NOTIFICATIONS` izni gereklidir
   - Uygulama ilk açıldığında otomatik olarak istenir

2. **Exact Alarm İzinleri**
   - Android 12+ için `SCHEDULE_EXACT_ALARM` izni gereklidir
   - Kullanıcı ayarlarından manuel olarak açılabilir

3. **Bildirim Sesleri**
   - Şu anda sistem varsayılan sesi kullanılıyor
   - Özel ses dosyası eklemek için:
     - Android: `android/app/src/main/res/raw/notification_sound.mp3`
     - iOS: `ios/Runner/notification_sound.wav`

4. **Timezone**
   - Varsayılan timezone: `Europe/Istanbul`
   - Değiştirmek için `NotificationService.initialize()` içinde düzenleyin

## 🧪 Test Etme

### Bildirimleri Test Etmek İçin:
1. Uygulamayı çalıştırın
2. Bir hatırlatıcı ekleyin (örn: 2 dakika sonra)
3. Uygulamayı kapatın veya arka plana alın
4. Belirtilen saatte bildirim gelmeli

### Bekleyen Bildirimleri Kontrol Etmek:
```dart
final notifications = await NotificationService().getPendingNotifications();
print('Bekleyen bildirim sayısı: ${notifications.length}');
```

## 🔧 Sorun Giderme

### Bildirimler Gelmiyor
1. **Android:**
   - Bildirim izinlerinin verildiğinden emin olun
   - Ayarlar > Uygulamalar > Demans Asistanı > Bildirimler
   - Exact alarm izninin açık olduğundan emin olun

2. **iOS:**
   - Ayarlar > Bildirimler > Demans Asistanı
   - Bildirimlerin açık olduğundan emin olun

3. **Genel:**
   - Uygulama arka planda çalışıyor olmalı
   - Cihazın saat dilimi doğru olmalı
   - Bildirim servisinin başlatıldığından emin olun

### Bildirimler Geç Geliyor
- Android'de "Doze Mode" bildirimleri geciktirebilir
- `AndroidScheduleMode.exactAllowWhileIdle` kullanılıyor
- Cihazın pil optimizasyonunu kapatmayı deneyin

## 📝 Gelecek Geliştirmeler

- [ ] Özel bildirim sesleri ekleme
- [ ] Bildirim tıklama işlemleri (deep linking)
- [ ] Bildirim öncelikleri
- [ ] Tekrarlama seçenekleri (haftalık, aylık)
- [ ] Bildirim geçmişi

