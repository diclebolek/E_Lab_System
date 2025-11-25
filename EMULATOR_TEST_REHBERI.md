# Android/iOS Emülatör Test Rehberi

## ⚠️ Önemli Not: Emülatörlerde Kamera

**Android Emülatörlerde:**
- ✅ Kamera **webcam** üzerinden çalışabilir (ayarlanırsa)
- ✅ **Galeri testi** her zaman çalışır (dosya seçimi)
- ⚠️ Kamera kalitesi gerçek cihaza göre düşük olabilir

**iOS Simülatörlerde:**
- ✅ Kamera **Mac'in webcam'i** üzerinden çalışır
- ✅ **Galeri testi** çalışır
- ⚠️ Bazı özellikler sınırlı olabilir

## 📱 Android Emülatör Test Adımları

### 1. Emülatör Başlatma

```bash
# Emülatör listesini gör
flutter emulators

# Bir emülatör başlat (örnek: Pixel 7)
flutter emulators --launch Pixel_7

# Veya Android Studio'dan başlat
# Android Studio > Tools > Device Manager > Play butonu
```

### 2. Emülatörde Kamera Ayarlama

**Android Emülatörde Kamera:**
1. Emülatör başladıktan sonra
2. Emülatör menüsünden (üç nokta) > **Settings** > **Camera**
3. **Front Camera** ve **Back Camera** için **Webcam0** seç
4. Artık kamera çalışacak

**Alternatif: Emülatör başlatırken kamera ayarı**
```bash
# Emülatörü kamera ile başlat (Android Studio'dan)
# AVD Manager > Edit > Show Advanced Settings > Camera > Webcam0
```

### 3. Uygulamayı Çalıştırma

```bash
# Emülatör başladıktan sonra
flutter devices  # Emülatörün bağlı olduğunu kontrol et

# Uygulamayı emülatöre yükle
flutter run

# Veya belirli emülatör seç
flutter run -d Pixel_7
```

### 4. Test Senaryoları

#### Senaryo 1: Galeri Testi (Önerilen - Her Zaman Çalışır)
1. Uygulamada "Galeriden Seç" butonuna tıkla
2. Emülatörde bir görüntü dosyası seç
3. OCR işlemi başlayacak
4. Konsol loglarını kontrol et

**Test Görüntüsü Hazırlama:**
- Bilgisayarınızdan bir tahlil raporu fotoğrafını emülatöre aktarın
- Veya emülatörde web tarayıcıdan bir görüntü indirin

#### Senaryo 2: Kamera Testi
1. Emülatörde kamera ayarını yap (yukarıdaki adımlar)
2. Uygulamada "Kamera ile Tara" butonuna tıkla
3. Webcam üzerinden fotoğraf çek
4. OCR işlemi başlayacak

### 5. Konsol Loglarını İzleme

Terminal'de şu logları göreceksiniz:

```
📷 Kameradan fotoğraf çekiliyor...
✅ Fotoğraf çekildi: /data/user/0/.../cache/image_picker_xxx.jpg
🔍 OCR işlemi başlatılıyor...
📸 OCR başlatılıyor... Platform: Android/iOS
📁 Görüntü yolu: /data/user/0/.../cache/image_picker_xxx.jpg
🔍 Android/iOS platformunda Google ML Kit kullanılıyor...
📷 InputImage oluşturuldu: /data/user/0/.../cache/image_picker_xxx.jpg
🔤 TextRecognizer başlatıldı
📝 OCR işlemi tamamlandı. Blok sayısı: 5
✅ OCR tamamlandı. Metin uzunluğu: 234
📄 Çıkarılan metin (ilk 200 karakter): Ad Soyad: Ahmet Yılmaz...
🔍 Metin parse ediliyor...
✅ Parse tamamlandı. Bulunan alanlar: [fullName, tcNumber, birthDate, ...]
```

## 🍎 iOS Simülatör Test (Mac Gerekli)

### 1. Simülatör Başlatma

```bash
# Xcode'dan simülatör başlat
open -a Simulator

# Veya Xcode > Window > Devices and Simulators > Simulators > + > iPhone seç
```

### 2. Uygulamayı Çalıştırma

```bash
# iOS simülatörü seç
flutter devices  # Simülatörü gör

# Uygulamayı çalıştır
flutter run -d <ios-device-id>
```

### 3. iOS'ta Kamera
- iOS simülatörü Mac'in webcam'ini kullanır
- Otomatik olarak çalışır (ayar gerekmez)

## 🔧 Sorun Giderme

### Emülatörde Kamera Açılmıyor

**Çözüm 1: Galeri Testi Kullan**
- Emülatörde kamera sorunlu olabilir
- Galeri testi her zaman çalışır
- Önce galeri ile test edin

**Çözüm 2: Kamera Ayarlarını Kontrol Et**
- Emülatör menüsü > Settings > Camera
- Webcam0 seçili olduğundan emin olun

**Çözüm 3: Gerçek Cihaz Kullan**
- En güvenilir test yöntemi
- USB ile bağlayın: `flutter devices`
- `flutter run` ile çalıştırın

### OCR Çalışmıyor

**Kontrol Listesi:**
- [ ] İzinler verildi mi? (Ayarlar > Uygulamalar > İzinler)
- [ ] Fotoğraf net mi? (Blur yok mu?)
- [ ] Yeterli ışık var mı?
- [ ] Metin okunabilir mi?
- [ ] Konsol loglarında hata var mı?

### Loglar Görünmüyor

```bash
# Detaylı loglar için
flutter run --verbose

# Veya Android Studio'da Logcat kullan
# View > Tool Windows > Logcat
```

## 📊 Test Öncelik Sırası

1. **Galeri Testi** (En Kolay)
   - Emülatörde her zaman çalışır
   - Kamera ayarı gerekmez
   - Hızlı test için ideal

2. **Emülatör Kamera Testi**
   - Webcam ayarı gerekir
   - Kalite düşük olabilir
   - OCR testi için yeterli

3. **Gerçek Cihaz Testi** (En İyi)
   - En güvenilir sonuç
   - Gerçek kullanım senaryosu
   - Production öncesi zorunlu

## 💡 İpuçları

1. **İlk Test için Galeri Kullan**
   - Daha hızlı ve güvenilir
   - Kamera ayarı gerekmez

2. **Test Görüntüsü Hazırla**
   - Net bir tahlil raporu fotoğrafı
   - Bilgisayardan emülatöre aktar
   - Galeri testinde kullan

3. **Logları Takip Et**
   - Her adım loglanıyor
   - Hata durumunda stack trace var
   - Debug için çok faydalı

4. **Gerçek Cihazda Final Test**
   - Emülatör testi başarılı olsa bile
   - Production öncesi gerçek cihazda test et

