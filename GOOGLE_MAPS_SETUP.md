# Google Maps Entegrasyonu Kurulum Rehberi

Bu uygulama Google Maps kullanarak gerçek harita görünümü ve navigasyon özellikleri sunmaktadır.

## Gereksinimler

1. Google Cloud Console hesabı
2. Google Maps API key

## Kurulum Adımları

### 1. Google Cloud Console'da Proje Oluşturma

1. [Google Cloud Console](https://console.cloud.google.com/) adresine gidin
2. Yeni bir proje oluşturun veya mevcut bir projeyi seçin

### 2. API'leri Etkinleştirme

Aşağıdaki API'leri etkinleştirmeniz gerekmektedir:

- **Maps SDK for Android** (Android için)
- **Maps SDK for iOS** (iOS için)
- **Directions API** (Navigasyon için - opsiyonel)
- **Geocoding API** (Adres dönüşümü için - opsiyonel)

**API'leri etkinleştirme:**
1. Google Cloud Console'da "APIs & Services" > "Library" bölümüne gidin
2. Yukarıdaki API'leri arayın ve "Enable" butonuna tıklayın

### 3. API Key Oluşturma

1. "APIs & Services" > "Credentials" bölümüne gidin
2. "Create Credentials" > "API Key" seçeneğini seçin
3. Oluşturulan API key'i kopyalayın

**Güvenlik için öneriler:**
- API key'i kısıtlayın (Application restrictions)
- Android için: Package name ve SHA-1 certificate fingerprint ekleyin
- iOS için: Bundle identifier ekleyin

### 4. Android Yapılandırması

`android/app/src/main/AndroidManifest.xml` dosyasında:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE" />
```

`YOUR_GOOGLE_MAPS_API_KEY_HERE` kısmını kendi API key'inizle değiştirin.

### 5. iOS Yapılandırması

`ios/Runner/AppDelegate.swift` dosyasında:

```swift
import GoogleMaps

// didFinishLaunchingWithOptions metodunda:
GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY_HERE")
```

`YOUR_GOOGLE_MAPS_API_KEY_HERE` kısmını kendi API key'inizle değiştirin.

### 6. iOS Podfile Güncelleme

`ios/Podfile` dosyasını açın ve aşağıdaki satırı ekleyin (eğer yoksa):

```ruby
platform :ios, '12.0'
```

Sonra terminalde şu komutu çalıştırın:

```bash
cd ios
pod install
cd ..
```

## Özellikler

### Harita Özellikleri

- ✅ Gerçek Google Maps görünümü
- ✅ Hasta konumunu marker olarak gösterme
- ✅ Güvenli bölge çemberini haritada gösterme
- ✅ Güvenli bölge merkezini marker olarak gösterme
- ✅ Haritaya tıklayarak güvenli bölge merkezi ayarlama
- ✅ Konumuma git butonu
- ✅ Navigasyon başlat butonu (Google Maps uygulamasını açar)

### Navigasyon

- Hasta yakını, hasta konumuna navigasyon başlatabilir
- Google Maps uygulaması açılır ve rota gösterilir

## Sorun Giderme

### Android'de harita görünmüyor

1. API key'in doğru eklendiğinden emin olun
2. Maps SDK for Android'in etkinleştirildiğinden emin olun
3. SHA-1 certificate fingerprint'in API key kısıtlamalarına eklendiğinden emin olun
4. Logcat'te hata mesajlarını kontrol edin

### iOS'te harita görünmüyor

1. API key'in doğru eklendiğinden emin olun
2. Maps SDK for iOS'in etkinleştirildiğinden emin olun
3. Bundle identifier'ın API key kısıtlamalarına eklendiğinden emin olun
4. `pod install` komutunu çalıştırdığınızdan emin olun

### Navigasyon açılmıyor

1. Google Maps uygulamasının cihazda yüklü olduğundan emin olun
2. İnternet bağlantısını kontrol edin

## Fiyatlandırma

Google Maps API kullanımı ücretsiz bir kota ile gelir. Detaylar için:
- [Google Maps Platform Pricing](https://mapsplatform.google.com/pricing/)

**Not:** Geliştirme aşamasında genellikle ücretsiz kota yeterlidir. Production'da kullanım miktarınıza göre ücretlendirme yapılır.

