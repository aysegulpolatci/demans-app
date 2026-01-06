# Demans Asistanı - Kullanıcı Senaryoları

## 1. Genel Bakış

Bu dokümanda, Demans Asistanı uygulamasının temel kullanım senaryoları detaylı olarak açıklanmaktadır. Senaryolar, uygulamanın iki ana kullanıcı tipine (Hasta Yakını ve Hasta) göre kategorize edilmiştir.

---

## 2. Hasta Yakını Senaryoları

### Senaryo 2.1: Yeni Kullanıcı Kaydı ve İlk Kurulum

**Kullanıcı:** Ayşe Hanım (Hasta yakını, 45 yaşında)

**Amaç:** Uygulamaya kayıt olmak ve hasta bilgilerini eklemek.

**Adımlar:**
1. Uygulamayı ilk kez açtığında "Kayıt Ol" ekranına yönlendirilir.
2. Ad, soyad, e-posta adresi ve şifre bilgilerini girer.
3. "Hasta Yakını" rolünü seçer.
4. Kayıt işlemini tamamlar ve otomatik olarak giriş yapar.
5. Profil ayarları sayfasına gider.
6. Hasta bilgilerini ekler:
   - Hasta adı: "Zeynep Korkmaz"
   - Telefon: "+90 555 123 4567"
   - Adres: "Gül Sokak No:12, Moda / İstanbul"
   - Doğum tarihi: "15.05.1950"
   - Notlar: "Alzheimer teşhisi, ilaçlarını unutma eğilimi var"
7. Bilgileri kaydeder.

**Beklenen Sonuç:** Hasta yakını hesabı oluşturulur ve hasta bilgileri Firestore'a kaydedilir. Kullanıcı, hasta yakını arayüzüne (3 sekme: Hatırlatıcılar, Konum Takibi, Kişi Albümü) erişir.

**Süre:** Yaklaşık 5-7 dakika

---

### Senaryo 2.2: Hatırlatıcı Ekleme ve Yönetimi

**Kullanıcı:** Ayşe Hanım (Hasta yakını)

**Amaç:** Annesi için günlük ilaç hatırlatıcıları ve randevu hatırlatıcıları eklemek.

**Adımlar:**
1. Ana sayfada "Hatırlatıcılar" sekmesine gider.
2. Sağ alttaki "Yeni hatırlatıcı" butonuna tıklar.
3. İlk hatırlatıcıyı ekler:
   - Kategori: İlaç
   - Başlık: "D Vitamini"
   - Alt Başlık: "Sabah ilacı"
   - Saat: "11:30"
   - Not: "Kahvaltıdan sonra bir bardak su ile alın."
   - Doz: "1 kapsül"
   - Konum: "Mutfak çekmecesi"
   - Tekrarlama: Günlük
4. "Kaydet" butonuna tıklar.
5. İkinci hatırlatıcıyı ekler:
   - Kategori: Randevu
   - Başlık: "Fizyoterapi seansı"
   - Alt Başlık: "Dr. Yıldız"
   - Saat: "14:00"
   - Not: "Girişte refakatçi kartını göstermeyi unutmayın."
   - Doz: "30 dk"
   - Konum: "Medikal Park"
   - Tekrarlama: Yok
6. Üçüncü hatırlatıcıyı ekler:
   - Kategori: Görev
   - Başlık: "Hafıza egzersizi"
   - Alt Başlık: "Mobil uygulama"
   - Saat: "16:00"
   - Not: "Bulmaca serisinin 3. bölümünü tamamlayın."
   - Doz: "15 dk"
   - Konum: "Salon koltuğu"
   - Tekrarlama: Haftalık
7. Ana sayfaya döner ve eklediği hatırlatıcıları görür.

**Beklenen Sonuç:** Tüm hatırlatıcılar Firestore'a kaydedilir ve listede görünür. Günlük tekrarlayan hatırlatıcılar için otomatik bildirimler zamanlanır.

**Süre:** Yaklaşık 10-15 dakika

---

### Senaryo 2.3: Hatırlatıcı Düzenleme ve Silme

**Kullanıcı:** Ayşe Hanım (Hasta yakını)

**Amaç:** Mevcut hatırlatıcıyı güncellemek ve gereksiz hatırlatıcıyı silmek.

**Adımlar:**
1. "Hatırlatıcılar" sekmesinde mevcut hatırlatıcıları görür.
2. "D Vitamini" hatırlatıcısının sağ üst köşesindeki üç nokta menüsüne tıklar.
3. "Düzenle" seçeneğini seçer.
4. Saat bilgisini "11:30"dan "10:00"a değiştirir.
5. Not bilgisini "Kahvaltıdan önce bir bardak su ile alın." olarak günceller.
6. "Kaydet" butonuna tıklar.
7. "Hafıza egzersizi" hatırlatıcısının üç nokta menüsüne tıklar.
8. "Sil" seçeneğini seçer.
9. Onay dialog'unda "Sil" butonuna tıklar.

**Beklenen Sonuç:** Düzenlenen hatırlatıcı güncellenir ve silinen hatırlatıcı listeden kaldırılır. Bildirimler otomatik olarak güncellenir.

**Süre:** Yaklaşık 3-5 dakika

---

### Senaryo 2.4: Kişi Albümüne Fotoğraf Ekleme

**Kullanıcı:** Ayşe Hanım (Hasta yakını)

**Amaç:** Annesinin hatırlaması için aile üyelerinin fotoğraflarını eklemek ve sesli açıklamalar yazmak.

**Adımlar:**
1. "Kişi Albümü" sekmesine gider.
2. Sağ alttaki "Fotoğraf yükle" butonuna tıklar.
3. İlk kişiyi ekler:
   - Fotoğraf: Galeriden kendi fotoğrafını seçer
   - İsim: "Ayşe Korkmaz"
   - Yakınlık: "Kızı"
   - Açıklama: "Her sabah kahve içip günün planını birlikte yapıyorsunuz."
   - Sesli Açıklama (TTS): "Bu Ayşe, senin kızın. Her sabah kahve içip gününü birlikte planlıyorsunuz."
4. "Kaydet" butonuna tıklar.
5. İkinci kişiyi ekler:
   - Fotoğraf: Galeriden kardeşinin fotoğrafını seçer
   - İsim: "Mehmet Korkmaz"
   - Yakınlık: "Oğlu"
   - Açıklama: "Hafta sonları seni yürüyüşe çıkarıyor."
   - Sesli Açıklama: "Bu Mehmet, senin oğlun. Hafta sonları birlikte parkta yürüyüş yapıyorsunuz."
6. Favori işaretini aktif eder.
7. "Kaydet" butonuna tıklar.

**Beklenen Sonuç:** Fotoğraflar Firebase Storage'a yüklenir ve kişi bilgileri Firestore'a kaydedilir. Annesi bu kişileri görüntüleyebilir ve fotoğrafa tıklayınca sesli açıklama dinleyebilir.

**Süre:** Yaklaşık 15-20 dakika (fotoğraf seçimi ve yükleme süresi dahil)

---

### Senaryo 2.5: Konum Takibi ve Güvenli Bölge Ayarlama

**Kullanıcı:** Ayşe Hanım (Hasta yakını)

**Amaç:** Annesinin güvenliği için güvenli bölge (safe zone) belirlemek ve konum takibini aktif etmek.

**Adımlar:**
1. "Konum Takibi" sekmesine gider.
2. Harita üzerinde annesinin ev adresini görür (profil ayarlarından eklenmiş adres).
3. Güvenli bölge yarıçapını ayarlar:
   - Slider'ı kullanarak yarıçapı 200 metreye ayarlar
4. "Uyarı Sistemi" toggle'ını aktif eder.
5. Sistem, annesi güvenli bölge dışına çıktığında bildirim gönderecektir.

**Beklenen Sonuç:** Güvenli bölge ayarları kaydedilir ve konum takibi aktif olur. Hasta güvenli bölge dışına çıktığında hasta yakınına bildirim gönderilir.

**Süre:** Yaklaşık 2-3 dakika

---

### Senaryo 2.6: Hatırlatıcı Tamamlama ve Geçmiş Görüntüleme

**Kullanıcı:** Ayşe Hanım (Hasta yakını)

**Amaç:** Tamamlanan hatırlatıcıları görüntülemek ve geçmiş aktiviteleri kontrol etmek.

**Adımlar:**
1. "Hatırlatıcılar" sekmesinde "Aktif" sekmesinde hatırlatıcıları görür.
2. "D Vitamini" hatırlatıcısının "Tamamla" butonuna tıklar (hatırlatıcı tamamlandığında).
3. Hatırlatıcı listeden kaybolur.
4. "Tamamlanan" sekmesine geçer.
5. Tamamlanan hatırlatıcıları görür (tarih sırasına göre).
6. Bir hatırlatıcının üç nokta menüsünden "Geri Al" seçeneğini seçerek tekrar aktif hale getirebilir.

**Beklenen Sonuç:** Tamamlanan hatırlatıcılar "Tamamlanan" sekmesinde görünür ve geçmiş aktiviteler takip edilebilir.

**Süre:** Yaklaşık 1-2 dakika

---

## 3. Hasta Senaryoları

### Senaryo 3.1: Hasta Olarak Giriş ve İlk Kullanım

**Kullanıcı:** Zeynep Korkmaz (Hasta, 75 yaşında, Alzheimer teşhisi)

**Amaç:** Uygulamaya giriş yapmak ve hatırlatıcıları görüntülemek.

**Adımlar:**
1. Uygulamayı açar.
2. E-posta ve şifre ile giriş yapar (kızı tarafından oluşturulmuş hesap).
3. Otomatik olarak hasta arayüzüne yönlendirilir (4 sekme: Hatırlatıcılar, Kişiler, Eve Dön, Acil).
4. "Hatırlatıcılar" sekmesinde bugünkü hatırlatıcıları görür.
5. Kızının eklediği hatırlatıcıları okur.

**Beklenen Sonuç:** Hasta, sadece görüntüleme modunda hatırlatıcıları görür. Ekleme/düzenleme butonları görünmez.

**Süre:** Yaklaşık 1-2 dakika

---

### Senaryo 3.2: Hatırlatıcı Sesli Okutma

**Kullanıcı:** Zeynep Korkmaz (Hasta)

**Amaç:** Hatırlatıcıyı sesli olarak dinlemek.

**Adımlar:**
1. "Hatırlatıcılar" sekmesinde "D Vitamini" hatırlatıcısını görür.
2. Hatırlatıcı kartının sağ tarafındaki ses ikonuna tıklar.
3. Uygulama, hatırlatıcı bilgilerini Türkçe olarak sesli okur:
   - "D Vitamini. Sabah ilacı. Kahvaltıdan sonra bir bardak su ile alın. Zaman: 11:30. Doz: 1 kapsül. Konum: Mutfak çekmecesi."

**Beklenen Sonuç:** TTS (Text-to-Speech) servisi hatırlatıcıyı sesli olarak okur ve hasta bilgileri dinleyebilir.

**Süre:** Yaklaşık 10-15 saniye

---

### Senaryo 3.3: Kişi Albümünde Fotoğraf Görüntüleme ve Sesli Açıklama

**Kullanıcı:** Zeynep Korkmaz (Hasta)

**Amaç:** Aile üyelerinin fotoğraflarını görüntülemek ve kim olduklarını sesli olarak dinlemek.

**Adımlar:**
1. "Kişiler" sekmesine gider.
2. Kızı Ayşe'nin fotoğrafını görür.
3. Fotoğrafa tıklar.
4. Uygulama otomatik olarak sesli açıklamayı okur:
   - "Bu Ayşe, senin kızın. Her sabah kahve içip gününü birlikte planlıyorsunuz."
5. Oğlu Mehmet'in fotoğrafına tıklar.
6. Sesli açıklama otomatik olarak okunur:
   - "Bu Mehmet, senin oğlun. Hafta sonları birlikte parkta yürüyüş yapıyorsunuz."

**Beklenen Sonuç:** Hasta, fotoğrafa tıkladığında otomatik olarak sesli açıklama dinler ve kişinin kim olduğunu hatırlar.

**Süre:** Her fotoğraf için yaklaşık 5-10 saniye

---

### Senaryo 3.4: Eve Dönüş Rehberi Kullanımı

**Kullanıcı:** Zeynep Korkmaz (Hasta)

**Amaç:** Kaybolduğunda eve dönüş için adım adım yol tarifi almak.

**Adımlar:**
1. "Eve Dön" sekmesine gider.
2. Ev adresini görür: "Gül Sokak No:12, Moda / İstanbul"
3. Harita üzerinde rota görselleştirmesini görür.
4. Rota özetini görür:
   - Mesafe: "2,4 km"
   - Süre: "9 dk"
5. Adım adım yol tarifini okur:
   - "1. Bağdat Caddesi boyunca kuzeye ilerle (350 m, 1 dk)"
   - "2. Moda Caddesi'ne sağa dön (600 m, 2 dk)"
   - "3. Süreyya Operası kavşağında sola dön (1,1 km, 4 dk)"
   - "4. Gül Sokak boyunca devam et (350 m, 1 dk)"
   - "5. Evine ulaştın"
6. Alt kısımdaki "Başlat" butonuna tıklar.
7. Sesli yol tarifi başlar.

**Beklenen Sonuç:** Hasta, adım adım yol tarifini görsel ve sesli olarak alır ve eve dönüş yolunu takip edebilir.

**Süre:** Yaklaşık 2-3 dakika (yol tarifi dinleme süresi dahil)

---

### Senaryo 3.5: Acil Durum Butonu Kullanımı

**Kullanıcı:** Zeynep Korkmaz (Hasta)

**Amaç:** Acil bir durumda hızlıca yardım çağırmak.

**Adımlar:**
1. "Acil" sekmesine gider.
2. Büyük kırmızı "SOS" butonunu görür.
3. Acil durumda "SOS" butonuna tıklar.
4. Uygulama otomatik olarak:
   - Acil durum telefon numarasını (112) arar
   - Konum bilgisini paylaşır
   - Aile üyelerine push notification gönderir
5. Hızlı aksiyonlar bölümünden:
   - "Ara" butonuna tıklayarak kızını arayabilir
   - "SMS Gönder" butonuna tıklayarak konum bilgisini SMS ile gönderebilir

**Beklenen Sonuç:** Acil durumda hızlıca yardım çağrılır ve aile üyeleri bilgilendirilir.

**Süre:** Acil durum butonuna tıklama: 1-2 saniye, otomatik işlemler: 5-10 saniye

---

### Senaryo 3.6: Hatırlatıcı Bildirimi Alma ve Görüntüleme

**Kullanıcı:** Zeynep Korkmaz (Hasta)

**Amaç:** Zamanı gelen hatırlatıcıyı bildirim olarak almak ve görüntülemek.

**Adımlar:**
1. Saat 11:30'da telefon bildirimi alır:
   - Başlık: "D Vitamini"
   - İçerik: "Kahvaltıdan sonra bir bardak su ile alın. Konum: Mutfak çekmecesi"
2. Bildirime tıklar.
3. Uygulama açılır ve "Hatırlatıcılar" sekmesine yönlendirilir.
4. İlgili hatırlatıcıyı görür (vurgulu olarak gösterilir).
5. Ses ikonuna tıklayarak hatırlatıcıyı sesli dinler.

**Beklenen Sonuç:** Hasta, zamanı gelen hatırlatıcıyı bildirim olarak alır ve uygulamada görüntüleyebilir.

**Süre:** Bildirim alma: anlık, görüntüleme: 10-15 saniye

---

## 4. Ortak Senaryolar

### Senaryo 4.1: Çıkış Yapma ve Tekrar Giriş

**Kullanıcı:** Her iki kullanıcı tipi

**Amaç:** Güvenlik için oturumu kapatmak ve tekrar giriş yapmak.

**Adımlar:**
1. Sağ üst köşedeki üç nokta menüsüne tıklar.
2. "Çıkış Yap" seçeneğini seçer.
3. Otomatik olarak giriş sayfasına yönlendirilir.
4. Tekrar e-posta ve şifre ile giriş yapar.
5. Oturum durumuna göre uygun arayüze yönlendirilir.

**Beklenen Sonuç:** Oturum güvenli bir şekilde kapatılır ve tekrar giriş yapıldığında kullanıcı verileri korunur.

**Süre:** Yaklaşık 30 saniye

---

### Senaryo 4.2: Ağ Bağlantısı Hatası Senaryosu

**Kullanıcı:** Her iki kullanıcı tipi

**Amaç:** İnternet bağlantısı olmadığında uygulamanın davranışını görmek.

**Adımlar:**
1. İnternet bağlantısını kapatır (Wi-Fi ve mobil veri).
2. Uygulamayı açar.
3. Uygulama, Firestore bağlantı hatası mesajı gösterir:
   - "Bağlantı Hatası"
   - "İnternet bağlantınızı kontrol edin veya Firestore veritabanının oluşturulduğundan emin olun."
4. "Yeniden Dene" butonuna tıklar.
5. İnternet bağlantısını tekrar açar.
6. Uygulama normal şekilde çalışır.

**Beklenen Sonuç:** Uygulama, ağ hatası durumunda kullanıcıya bilgi verir ve alternatif aksiyonlar sunar.

**Süre:** Hata görüntüleme: anlık, düzeltme: 1-2 dakika

---

## 5. Senaryo Özet Tablosu

| Senaryo No | Senaryo Adı | Kullanıcı Tipi | Süre | Öncelik |
|------------|-------------|----------------|------|---------|
| 2.1 | Yeni Kullanıcı Kaydı | Hasta Yakını | 5-7 dk | Yüksek |
| 2.2 | Hatırlatıcı Ekleme | Hasta Yakını | 10-15 dk | Yüksek |
| 2.3 | Hatırlatıcı Düzenleme/Silme | Hasta Yakını | 3-5 dk | Orta |
| 2.4 | Kişi Albümüne Fotoğraf Ekleme | Hasta Yakını | 15-20 dk | Yüksek |
| 2.5 | Konum Takibi Ayarlama | Hasta Yakını | 2-3 dk | Orta |
| 2.6 | Hatırlatıcı Geçmişi | Hasta Yakını | 1-2 dk | Düşük |
| 3.1 | Hasta Giriş ve İlk Kullanım | Hasta | 1-2 dk | Yüksek |
| 3.2 | Hatırlatıcı Sesli Okutma | Hasta | 10-15 sn | Yüksek |
| 3.3 | Kişi Albümü Sesli Açıklama | Hasta | 5-10 sn | Yüksek |
| 3.4 | Eve Dönüş Rehberi | Hasta | 2-3 dk | Yüksek |
| 3.5 | Acil Durum Butonu | Hasta | 1-2 sn | Çok Yüksek |
| 3.6 | Bildirim Alma | Hasta | 10-15 sn | Yüksek |
| 4.1 | Çıkış Yapma | Her İkisi | 30 sn | Orta |
| 4.2 | Ağ Hatası | Her İkisi | 1-2 dk | Orta |

---

## 6. Senaryo Test Kriterleri

### Başarı Kriterleri:
- ✅ Tüm adımlar hatasız tamamlanır
- ✅ Veriler Firestore'a doğru şekilde kaydedilir
- ✅ Kullanıcı arayüzü responsive ve kullanıcı dostudur
- ✅ Hata durumlarında kullanıcıya bilgi verilir
- ✅ Bildirimler zamanında gönderilir
- ✅ Sesli özellikler (TTS) düzgün çalışır

### Hata Senaryoları:
- ❌ İnternet bağlantısı yoksa uygun hata mesajı gösterilir
- ❌ Geçersiz giriş bilgileri durumunda hata mesajı gösterilir
- ❌ Firestore bağlantı hatası durumunda kullanıcı bilgilendirilir
- ❌ Fotoğraf yükleme hatası durumunda alternatif çözüm sunulur

---

## 7. Sonuç

Bu kullanıcı senaryoları, Demans Asistanı uygulamasının temel işlevlerini ve kullanım akışlarını kapsamaktadır. Senaryolar, gerçek kullanım durumlarını yansıtacak şekilde tasarlanmıştır ve hem hasta yakınları hem de hastalar için farklı kullanım senaryolarını içermektedir. Bu senaryolar, uygulamanın test edilmesi, dokümantasyonu ve kullanıcı eğitimi için temel oluşturmaktadır.

