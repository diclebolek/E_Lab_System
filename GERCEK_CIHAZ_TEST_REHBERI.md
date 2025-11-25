# Gerçek Cihaz (Telefon) ile Test Rehberi

## 📱 Android Telefon ile Test

### 1. Geliştirici Seçeneklerini Aktifleştirme

1. **Telefon Ayarları** > **Telefon Hakkında** (About Phone)
2. **Yapı Numarası** (Build Number) seçeneğine **7 kez** tıkla
3. "Geliştirici oldunuz!" mesajı görünecek

### 2. USB Hata Ayıklamayı Açma

1. **Ayarlar** > **Geliştirici Seçenekleri** (Developer Options)
2. **USB Hata Ayıklama** (USB Debugging) seçeneğini **AÇ**
3. Onay penceresinde **Tamam** de

### 3. Telefonu Bilgisayara Bağlama

1. USB kablosu ile telefonu bilgisayara bağla
2. Telefonda **"Bu bilgisayara güven"** onayını ver
3. USB bağlantı modunu **Dosya Aktarımı** (File Transfer) olarak ayarla

### 4. Bağlantıyı Kontrol Etme

```bash
# Bağlı cihazları kontrol et
flutter devices

# Android Debug Bridge (ADB) ile kontrol
adb devices
```

**Beklenen Çıktı:**
```
List of devices attached
ABC123XYZ    device
```

### 5. Uygulamayı Telefona Yükleme

```bash
# Telefona uygulamayı yükle ve çalıştır
flutter run

# Veya belirli cihaz seç
flutter run -d <device-id>
```

### 6. İlk Çalıştırmada

- Telefonda **"Bu uygulamaya güven"** onayı istenebilir
- **Yükle** veya **Kur** de
- Uygulama telefona yüklenecek ve otomatik açılacak

---

## 🍎 iOS Telefon (iPhone/iPad) ile Test

### 1. Gereksinimler

- **Mac bilgisayar** (Xcode gerekli)
- **Apple Developer hesabı** (ücretsiz)
- **Lightning/USB-C kablosu**

### 2. Xcode Ayarları

1. **Xcode** aç
2. **Preferences** > **Accounts**
3. Apple ID ekle (ücretsiz hesap yeterli)
4. **Manage Certificates** > **+** > **Apple Development**

### 3. Telefonu Mac'e Bağlama

1. iPhone/iPad'i Mac'e bağla
2. Telefonda **"Bu bilgisayara güven"** onayını ver
3. Xcode'da **Window** > **Devices and Simulators**
4. Cihazınız listede görünmeli

### 4. Uygulamayı Çalıştırma

```bash
# iOS cihazını kontrol et
flutter devices

# Uygulamayı çalıştır
flutter run -d <ios-device-id>
```

### 5. İlk Çalıştırmada

- Xcode'da **Signing & Capabilities** ayarları yapılmalı
- **Trust Developer** onayı telefonda istenebilir
- **Ayarlar** > **Genel** > **VPN ve Cihaz Yönetimi** > Developer uygulamaya güven

---

## 🔧 Sorun Giderme

### Android: "No devices found"

**Çözüm 1: USB Sürücüleri**
```bash
# Android Studio'dan SDK Manager > SDK Tools > Google USB Driver yükle
```

**Çözüm 2: ADB Yeniden Başlat**
```bash
adb kill-server
adb start-server
adb devices
```

**Çözüm 3: USB Bağlantı Modu**
- Telefonda bildirim alanından **USB bağlantı modunu** kontrol et
- **Dosya Aktarımı** (MTP) veya **PTP** seç

**Çözüm 4: Kabloyu Değiştir**
- Veri aktarımı yapabilen bir USB kablosu kullan
- Sadece şarj kablosu çalışmaz

### iOS: "No devices found"

**Çözüm 1: Xcode Command Line Tools**
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

**Çözüm 2: Trust Developer**
- Telefonda: **Ayarlar** > **Genel** > **VPN ve Cihaz Yönetimi**
- Developer uygulamaya güven

**Çözüm 3: Provisioning Profile**
- Xcode'da projeyi aç
- Signing & Capabilities'de otomatik signing aktif et

### Kamera İzni Sorunu

**Android:**
1. **Ayarlar** > **Uygulamalar** > **g211210055_labsystem**
2. **İzinler** > **Kamera** > **İzin Ver**

**iOS:**
1. **Ayarlar** > **Gizlilik** > **Kamera**
2. Uygulamanızı bul ve **AÇ**

---

## 📊 Test Senaryoları

### Senaryo 1: Kamera ile OCR Testi

1. Uygulamada **"Kamera ile Tara"** butonuna tıkla
2. Kamera izni isteğini **İzin Ver**
3. Tahlil raporunu kameraya göster veya fotoğraf çek
4. Konsol loglarını kontrol et:
   ```
   📷 Kameradan fotoğraf çekiliyor...
   ✅ Fotoğraf çekildi
   🔍 OCR işlemi başlatılıyor...
   ✅ OCR tamamlandı
   ```

### Senaryo 2: Galeri ile OCR Testi

1. Önce telefonda bir tahlil raporu fotoğrafı kaydet
2. Uygulamada **"Galeriden Seç"** butonuna tıkla
3. Fotoğrafı seç
4. OCR işlemi başlayacak

### Senaryo 3: Form Otomatik Doldurma

1. OCR başarılı olduktan sonra
2. Form alanlarının otomatik dolduğunu kontrol et:
   - Ad Soyad
   - TC Kimlik No
   - Doğum Tarihi
   - Cinsiyet
   - vb.

---

## 💡 İpuçları

1. **İlk Test için Galeri Kullan**
   - Daha hızlı ve kolay
   - Kamera izni gerekmez (sadece galeri izni)

2. **Konsol Loglarını Takip Et**
   - Her adım loglanıyor
   - Hata durumunda detaylı bilgi var

3. **Hot Reload Kullan**
   - Kod değişikliği yaptığında `r` tuşuna bas
   - Uygulama yeniden başlatılmadan güncellenir

4. **Release Mode Test**
   - Final test için:
   ```bash
   flutter run --release
   ```

5. **APK Oluştur (Android)**
   ```bash
   flutter build apk
   # APK dosyası: build/app/outputs/flutter-apk/app-release.apk
   ```

---

## 🚀 Hızlı Başlangıç

### Android için:
```bash
# 1. Telefonu bağla ve USB hata ayıklamayı aç
# 2. Bağlantıyı kontrol et
flutter devices

# 3. Uygulamayı çalıştır
flutter run
```

### iOS için (Mac gerekli):
```bash
# 1. iPhone'u Mac'e bağla
# 2. Xcode'da trust et
# 3. Uygulamayı çalıştır
flutter run
```

---

## ✅ Başarı Kontrolü

Test başarılı ise:
- ✅ Kamera açılıyor
- ✅ Fotoğraf çekilebiliyor
- ✅ OCR işlemi tamamlanıyor
- ✅ Konsol loglarında başarı mesajları var
- ✅ Form alanları otomatik doluyor

Test başarısız ise:
- ❌ Konsol loglarında hata mesajları var
- ❌ İzinler verilmemiş olabilir
- ❌ USB bağlantısı sorunlu olabilir

