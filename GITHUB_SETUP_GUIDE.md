# GitHub'a Proje Yükleme Rehberi

Bu rehber, Demans Asistanı projesini GitHub'a yüklemek için adım adım talimatlar içermektedir.

---

## Adım 1: GitHub'da Yeni Repository Oluşturma

1. **GitHub'a giriş yapın:**
   - https://github.com adresine gidin
   - Hesabınıza giriş yapın (yoksa yeni hesap oluşturun)

2. **Yeni repository oluşturun:**
   - Sağ üst köşedeki **"+"** butonuna tıklayın
   - **"New repository"** seçeneğini seçin

3. **Repository bilgilerini doldurun:**
   - **Repository name:** `demans-app` veya `demans-asistani` (istediğiniz ismi kullanabilirsiniz)
   - **Description:** "Demans hastaları için hatırlatıcı asistan mobil uygulaması"
   - **Visibility:** 
     - **Public** (herkes görebilir - önerilen)
     - **Private** (sadece siz görebilirsiniz)
   - **Initialize this repository with:**
     - ❌ README (işaretlemeyin, zaten README'miz var)
     - ❌ .gitignore (işaretlemeyin, zaten var)
     - ❌ license (opsiyonel)
   - **"Create repository"** butonuna tıklayın

4. **Repository URL'ini kopyalayın:**
   - Oluşturulan repository sayfasında, yeşil **"Code"** butonuna tıklayın
   - HTTPS URL'ini kopyalayın (örnek: `https://github.com/kullaniciadi/demans-app.git`)

---

## Adım 2: Projeyi Git Repository'ye Dönüştürme

### 2.1 Git Repository Başlatma

PowerShell veya Terminal'de proje klasörüne gidin ve şu komutları çalıştırın:

```powershell
# Proje klasörüne git
cd C:\Users\Aysegul\Desktop\DemansApp\demansapp

# Git repository başlat
git init

# Tüm dosyaları staging area'ya ekle
git add .

# İlk commit'i yap
git commit -m "Initial commit: Demans Asistanı projesi"
```

### 2.2 GitHub Repository'ye Bağlama

```powershell
# GitHub repository'yi remote olarak ekle
# NOT: Aşağıdaki URL'yi kendi repository URL'inizle değiştirin
git remote add origin https://github.com/KULLANICIADI/REPOSITORY-ADI.git

# Remote repository'yi kontrol et
git remote -v
```

---

## Adım 3: Dosyaları GitHub'a Yükleme

```powershell
# Ana branch'i main olarak ayarla (GitHub'ın yeni default'u)
git branch -M main

# Dosyaları GitHub'a yükle
git push -u origin main
```

**Not:** İlk kez push yaparken GitHub kullanıcı adı ve şifreniz istenebilir. Şifre yerine **Personal Access Token** kullanmanız gerekebilir (aşağıya bakın).

---

## Adım 4: GitHub Kimlik Doğrulama (Gerekirse)

Eğer push sırasında kimlik doğrulama hatası alırsanız:

### 4.1 Personal Access Token Oluşturma

1. GitHub'da sağ üst köşedeki profil resminize tıklayın
2. **Settings** seçeneğine gidin
3. Sol menüden **Developer settings** seçin
4. **Personal access tokens** > **Tokens (classic)** seçin
5. **Generate new token** > **Generate new token (classic)** seçin
6. **Note:** "Demans App Project" yazın
7. **Expiration:** İstediğiniz süreyi seçin
8. **Select scopes:** `repo` seçeneğini işaretleyin
9. **Generate token** butonuna tıklayın
10. **Token'ı kopyalayın** (bir daha gösterilmeyecek!)

### 4.2 Token ile Push Yapma

```powershell
# Push yaparken kullanıcı adı ve token istenecek
git push -u origin main

# Username: GitHub kullanıcı adınız
# Password: Oluşturduğunuz Personal Access Token
```

---

## Adım 5: README.md Dosyasını Güncelleme

Proje klasöründeki `README.md` dosyasını düzenleyerek proje hakkında bilgi ekleyin:

```markdown
# Demans Asistanı

Demans hastaları için hatırlatıcı asistan mobil uygulaması.

## Özellikler

- İlaç ve randevu hatırlatıcıları
- Kişi albümü ve sesli anlatım
- Konum takibi ve güvenli bölge
- Eve dönüş rehberi
- Acil durum butonu

## Teknolojiler

- Flutter
- Firebase (Authentication, Firestore, Storage, Cloud Messaging)
- Material Design 3

## Kurulum

```bash
flutter pub get
flutter run
```

## Lisans

Bu proje eğitim amaçlı geliştirilmiştir.
```

---

## Adım 6: Repository Linkini Raporunuza Ekleme

GitHub repository'nizin linkini proje raporunuza ekleyin:

**Örnek Format:**
```
GitHub Repository: https://github.com/kullaniciadi/demans-app
```

veya

```
Proje Kaynak Kodu: [GitHub Repository](https://github.com/kullaniciadi/demans-app)
```

---

## Hızlı Komut Özeti

Tüm işlemleri tek seferde yapmak için:

```powershell
# 1. Proje klasörüne git
cd C:\Users\Aysegul\Desktop\DemansApp\demansapp

# 2. Git başlat
git init

# 3. Dosyaları ekle
git add .

# 4. Commit yap
git commit -m "Initial commit: Demans Asistanı projesi"

# 5. Branch'i main yap
git branch -M main

# 6. Remote ekle (KENDİ URL'İNİZİ KULLANIN)
git remote add origin https://github.com/KULLANICIADI/REPOSITORY-ADI.git

# 7. GitHub'a yükle
git push -u origin main
```

---

## Sorun Giderme

### Hata: "fatal: not a git repository"
**Çözüm:** `git init` komutunu çalıştırın.

### Hata: "remote origin already exists"
**Çözüm:** 
```powershell
git remote remove origin
git remote add origin https://github.com/KULLANICIADI/REPOSITORY-ADI.git
```

### Hata: "Authentication failed"
**Çözüm:** Personal Access Token kullanın (yukarıdaki Adım 4'e bakın).

### Hata: "failed to push some refs"
**Çözüm:**
```powershell
git pull origin main --allow-unrelated-histories
git push -u origin main
```

---

## Sonraki Adımlar

1. ✅ Repository'yi oluşturdunuz
2. ✅ Dosyaları yüklediniz
3. ✅ README.md'yi güncelleyin
4. ✅ Repository linkini raporunuza ekleyin
5. ⭐ İsterseniz repository'yi yıldızlayın (star)

---

## İpuçları

- **Commit mesajları:** Anlamlı commit mesajları yazın (örn: "Hatırlatıcı modülü eklendi")
- **Branch kullanımı:** Büyük değişiklikler için yeni branch oluşturun
- **.gitignore:** Hassas bilgileri (API key'ler, şifreler) commit etmeyin
- **License:** Projeye uygun bir lisans ekleyebilirsiniz (MIT, Apache 2.0, vb.)

---

**Başarılar! 🚀**

