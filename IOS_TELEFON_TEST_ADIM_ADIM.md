# 📱 iOS Telefon ile Test - Adım Adım Rehber

## ⚠️ ÖNEMLİ: Gereksinimler

iOS telefonunuza uygulama yüklemek için **Mac bilgisayar** gereklidir. Windows bilgisayarda iOS uygulaması geliştirilemez.

**Gereksinimler:**
- ✅ **Mac bilgisayar** (macOS)
- ✅ **Xcode** (App Store'dan ücretsiz)
- ✅ **Apple ID** (ücretsiz hesap yeterli)
- ✅ **Lightning veya USB-C kablosu**

---

## 📋 ADIM 1: Mac Bilgisayar Hazırlığı

### 1.1. Xcode Kurulumu

1. **App Store**'u aç (Mac'te)
2. **Xcode** ara
3. **Yükle** butonuna tıkla (yaklaşık 12-15 GB)
4. Kurulum tamamlanana kadar bekle (30-60 dakika sürebilir)

### 1.2. Xcode Command Line Tools

Terminal'de şu komutu çalıştır:
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

### 1.3. Xcode Lisans Sözleşmesi

Terminal'de:
```bash
sudo xcodebuild -license
```
- **Agree** yaz ve Enter'a bas

---

## 📋 ADIM 2: Apple ID ve Sertifika Ayarları

### 2.1. Xcode'da Apple ID Ekleme

1. **Xcode**'u aç
2. **Xcode** > **Preferences** (veya **Settings**)
3. **Accounts** sekmesine tıkla
4. Sol alttaki **+** butonuna tıkla
5. **Apple ID** seç
6. Apple ID'nizi ve şifrenizi gir
7. **Add** butonuna tıkla

### 2.2. Sertifika Oluşturma

1. Xcode'da **Accounts** sekmesinde Apple ID'nizi seç
2. **Manage Certificates...** butonuna tıkla
3. Sol alttaki **+** butonuna tıkla
4. **Apple Development** seç
5. Sertifika otomatik oluşturulacak

---

## 📋 ADIM 3: iPhone'u Mac'e Bağlama

### 3.1. iPhone Ayarları

1. iPhone'unuzda **Ayarlar** > **Genel** > **VPN ve Cihaz Yönetimi** (veya **Profiller ve Cihaz Yönetimi**)
2. Henüz bir şey yoksa normal (ilk bağlantıda görünecek)

### 3.2. iPhone'u Mac'e Bağlama

1. **Lightning kablosu** ile iPhone'u Mac'e bağla
2. iPhone'da **"Bu bilgisayara güven"** mesajı çıkacak
3. **Güven** butonuna tıkla
4. Şifre istenirse iPhone şifrenizi girin

### 3.3. Xcode'da Cihazı Kontrol Etme

1. Xcode'u aç
2. **Window** > **Devices and Simulators** (veya `Shift + Cmd + 2`)
3. Sol tarafta **Devices** sekmesine tıkla
4. iPhone'unuz listede görünmeli
5. İlk kez görünüyorsa **"Trust"** butonuna tıkla

---

## 📋 ADIM 4: Flutter Projesini Mac'e Aktarma

### 4.1. Projeyi Mac'e Kopyalama

**Seçenek 1: USB ile**
- Proje klasörünü USB belleğe kopyala
- Mac'e aktar

**Seçenek 2: Cloud (Google Drive, Dropbox, vb.)**
- Proje klasörünü cloud'a yükle
- Mac'ten indir

**Seçenek 3: Git (Önerilen)**
- Projeyi Git repository'ye push et
- Mac'ten clone et

### 4.2. Mac'te Terminal'de Projeye Gitme

```bash
cd /path/to/g211210055_labsystem
```

---

## 📋 ADIM 5: Flutter ve iOS Bağımlılıklarını Kontrol Etme

### 5.1. Flutter Doctor Kontrolü

```bash
flutter doctor
```

**Beklenen Çıktı:**
```
[✓] Flutter (Channel stable, ...)
[✓] Android toolchain
[✓] Xcode - develop for iOS and macOS
[✓] Chrome - develop for the web
[✓] Android Studio
[✓] VS Code
[✓] Connected device
```

### 5.2. iOS Bağımlılıklarını Yükleme

```bash
cd ios
pod install
cd ..
```

**Not:** İlk kez çalıştırıyorsanız CocoaPods kurulu olmalı:
```bash
sudo gem install cocoapods
```

---

## 📋 ADIM 6: Xcode'da Proje Ayarları

### 6.1. Xcode'da Projeyi Açma

```bash
# Terminal'den Xcode ile aç
open ios/Runner.xcworkspace
```

**VEYA**

1. Xcode'u aç
2. **File** > **Open**
3. `ios/Runner.xcworkspace` dosyasını seç

### 6.2. Signing & Capabilities Ayarları

1. Xcode'da sol tarafta **Runner** projesini seç
2. **TARGETS** altında **Runner**'ı seç
3. **Signing & Capabilities** sekmesine tıkla
4. **Automatically manage signing** kutusunu işaretle
5. **Team** dropdown'ından Apple ID'nizi seç
6. **Bundle Identifier** otomatik oluşturulacak (örnek: `com.example.g211210055Labsystem`)

**Hata alırsanız:**
- Bundle Identifier'ı değiştir (benzersiz olmalı)
- Örnek: `com.sizinadi.g211210055Labsystem`

---

## 📋 ADIM 7: iPhone'u Flutter'da Tanıma

### 7.1. Bağlı Cihazları Kontrol Etme

Terminal'de (Mac'te):
```bash
flutter devices
```

**Beklenen Çıktı:**
```
3 connected devices:

iPhone 14 Pro (mobile) • 00008030-00123456789ABC • ios • com.apple.CoreSimulator.SimRuntime.iOS-16-0 (simulator)
iPhone (mobile)        • ABC123XYZ...            • ios • iOS 17.0
macOS (desktop)        • macos                    • darwin-arm64 • macOS 14.0
```

iPhone'unuz listede görünmeli!

### 7.2. Sorun Varsa

**iPhone görünmüyorsa:**
1. iPhone'un açık olduğundan emin ol
2. Kabloyu çıkarıp tekrar tak
3. iPhone'da **Ayarlar** > **Genel** > **VPN ve Cihaz Yönetimi** > Developer uygulamaya güven
4. Xcode'da **Window** > **Devices and Simulators** > iPhone'u seç > **Use for Development**

---

## 📋 ADIM 8: Uygulamayı iPhone'a Yükleme

### 8.1. Flutter Run Komutu

Terminal'de (Mac'te, proje klasöründe):
```bash
flutter run
```

**VEYA belirli cihaz seç:**
```bash
flutter run -d <iphone-device-id>
```

### 8.2. İlk Yüklemede

1. **Xcode** otomatik açılabilir
2. **Build** işlemi başlayacak (5-10 dakika sürebilir)
3. Terminal'de ilerleme görünecek:
   ```
   Running "flutter pub get"...
   Launching lib/main.dart on iPhone in debug mode...
   Building iOS app...
   ```

### 8.3. iPhone'da İlk Açılış

1. Uygulama iPhone'a yüklenecek
2. İlk açılışta **"Untrusted Developer"** uyarısı çıkabilir
3. **Ayarlar** > **Genel** > **VPN ve Cihaz Yönetimi** (veya **Profiller ve Cihaz Yönetimi**)
4. Developer uygulamanızı bul (örnek: "Apple Development: your@email.com")
5. **Güven** butonuna tıkla
6. **Güven** onayını ver
7. Uygulamayı tekrar aç

---

## 📋 ADIM 9: OCR Testi

### 9.1. Uygulamayı Açma

1. iPhone'da uygulamayı aç
2. Giriş yap (Admin veya Kullanıcı)

### 9.2. Kamera İzni

1. **"Kamera ile Tara"** butonuna tıkla
2. **"Kameraya Erişim İzni"** isteği çıkacak
3. **İzin Ver** butonuna tıkla

**İzin vermediyseniz:**
- **Ayarlar** > **Gizlilik ve Güvenlik** > **Kamera**
- Uygulamanızı bul ve **AÇ**

### 9.3. Galeri İzni

1. **"Galeriden Seç"** butonuna tıkla
2. **"Fotoğraflara Erişim İzni"** isteği çıkacak
3. **Tüm Fotoğraflara İzin Ver** veya **Seçili Fotoğraflar** seç

### 9.4. OCR Test Senaryosu

**Test 1: Galeri ile (Önerilen - Daha Kolay)**
1. Önce iPhone'da bir tahlil raporu fotoğrafı kaydet (Fotos uygulamasına)
2. Uygulamada **"Galeriden Seç"** butonuna tıkla
3. Fotoğrafı seç
4. OCR işlemi başlayacak
5. Terminal'de logları kontrol et:
   ```
   📷 Galeriden fotoğraf seçiliyor...
   ✅ Fotoğraf seçildi: /var/mobile/.../image_picker_xxx.jpg
   🔍 OCR işlemi başlatılıyor...
   📸 OCR başlatılıyor... Platform: Android/iOS
   🔍 Android/iOS platformunda Google ML Kit kullanılıyor...
   ✅ OCR tamamlandı. Metin uzunluğu: XXX
   ```

**Test 2: Kamera ile**
1. Uygulamada **"Kamera ile Tara"** butonuna tıkla
2. Tahlil raporunu kameraya göster veya fotoğraf çek
3. OCR işlemi başlayacak
4. Terminal'de logları kontrol et

### 9.5. Başarı Kontrolü

✅ **Başarılı ise:**
- Terminal'de başarı logları görünür
- Form alanları otomatik dolar (Ad Soyad, TC, Tarih vb.)
- Uygulamada bilgiler görünür

❌ **Başarısız ise:**
- Terminal'de hata logları görünür
- Form alanları boş kalır
- Hata mesajı gösterilir

---

## 🔧 Sorun Giderme

### Sorun 1: "No devices found"

**Çözüm:**
1. iPhone'un Mac'e bağlı olduğundan emin ol
2. Xcode'da **Window** > **Devices and Simulators** > iPhone görünüyor mu kontrol et
3. iPhone'da **Ayarlar** > **Genel** > **VPN ve Cihaz Yönetimi** > Developer uygulamaya güven
4. Terminal'de: `flutter devices` komutunu tekrar çalıştır

### Sorun 2: "Signing for Runner requires a development team"

**Çözüm:**
1. Xcode'da **Runner** > **Signing & Capabilities**
2. **Team** dropdown'ından Apple ID'nizi seç
3. **Automatically manage signing** işaretli olsun
4. Bundle Identifier benzersiz olsun

### Sorun 3: "Untrusted Developer"

**Çözüm:**
1. iPhone'da **Ayarlar** > **Genel** > **VPN ve Cihaz Yönetimi**
2. Developer uygulamanızı bul
3. **Güven** butonuna tıkla
4. Uygulamayı tekrar aç

### Sorun 4: Kamera İzni Verilmiyor

**Çözüm:**
1. iPhone'da **Ayarlar** > **Gizlilik ve Güvenlik** > **Kamera**
2. Uygulamanızı bul
3. **AÇ** konumuna getir

### Sorun 5: OCR Çalışmıyor

**Kontrol Listesi:**
- [ ] Fotoğraf net mi? (Blur yok mu?)
- [ ] Yeterli ışık var mı?
- [ ] Metin okunabilir mi?
- [ ] Terminal'de hata logları var mı?
- [ ] İnternet bağlantısı var mı? (İlk kullanımda model indirilebilir)

---

## 📊 Test Kontrol Listesi

- [ ] Mac bilgisayar hazır
- [ ] Xcode kurulu
- [ ] Apple ID Xcode'a ekli
- [ ] Sertifika oluşturuldu
- [ ] iPhone Mac'e bağlı
- [ ] iPhone Xcode'da görünüyor
- [ ] Flutter devices komutu iPhone'u görüyor
- [ ] Uygulama iPhone'a yüklendi
- [ ] Developer uygulamaya güvenildi
- [ ] Kamera izni verildi
- [ ] Galeri izni verildi
- [ ] OCR testi başarılı
- [ ] Form alanları otomatik doldu

---

## 💡 İpuçları

1. **İlk Test için Galeri Kullan**
   - Daha hızlı ve kolay
   - Kamera izni gerekmez (sadece galeri izni)

2. **Terminal Loglarını Takip Et**
   - Her adım loglanıyor
   - Hata durumunda detaylı bilgi var

3. **Hot Reload Kullan**
   - Kod değişikliği yaptığında Terminal'de `r` tuşuna bas
   - Uygulama yeniden başlatılmadan güncellenir

4. **Release Mode Test**
   - Final test için:
   ```bash
   flutter run --release
   ```

---

## 🚀 Hızlı Başlangıç (Özet)

```bash
# 1. Mac'te proje klasörüne git
cd /path/to/g211210055_labsystem

# 2. iOS bağımlılıklarını yükle
cd ios && pod install && cd ..

# 3. Xcode'da projeyi aç ve signing ayarla
open ios/Runner.xcworkspace

# 4. iPhone'u bağla ve kontrol et
flutter devices

# 5. Uygulamayı çalıştır
flutter run
```

---

## ❓ Sık Sorulan Sorular

**S: Windows bilgisayarda iOS test edebilir miyim?**
C: Hayır, iOS uygulaması geliştirmek için Mac gereklidir.

**S: Mac yok, ne yapabilirim?**
C: 
- Mac bilgisayar kullan (okul, iş, arkadaş)
- Cloud Mac servisleri (MacStadium, MacinCloud - ücretli)
- Hackintosh (önerilmez, yasal sorunlar olabilir)

**S: Ücretsiz Apple Developer hesabı yeterli mi?**
C: Evet, test için ücretsiz hesap yeterlidir. Uygulama 7 gün sonra sona erer, tekrar yüklemeniz gerekir.

**S: App Store'a yüklemek için ne gerekir?**
C: Ücretli Apple Developer Program üyeliği ($99/yıl) gereklidir.

---

## ✅ Başarı!

Tüm adımları tamamladıysanız:
- ✅ Uygulama iPhone'unuzda çalışıyor
- ✅ OCR özelliği test edilebilir
- ✅ Kamera ve galeri çalışıyor

**Test etmeye hazırsınız! 🎉**

