# OCR Test Rehberi - Android/iOS

## ✅ Yapılan Değişiklikler

1. **Android Kamera İzinleri Eklendi** (`AndroidManifest.xml`)
   - `CAMERA` izni
   - `READ_EXTERNAL_STORAGE` izni
   - `WRITE_EXTERNAL_STORAGE` izni (Android 12 ve altı için)

2. **iOS Kamera İzinleri Eklendi** (`Info.plist`)
   - `NSCameraUsageDescription` - Kamera erişimi açıklaması
   - `NSPhotoLibraryUsageDescription` - Galeri erişimi açıklaması

3. **Debug Logları Eklendi**
   - OCR işleminin her adımı konsola yazdırılıyor
   - Hata durumlarında detaylı bilgi gösteriliyor

## 📱 Test Adımları

### Android Test

1. **Emülatör veya Gerçek Cihaz Hazırlama**
   ```bash
   # Bağlı cihazları kontrol et
   flutter devices
   
   # Android emülatör başlat (Android Studio'dan)
   # veya gerçek cihaz bağla
   ```

2. **Uygulamayı Çalıştır**
   ```bash
   # Debug modda çalıştır (logları görmek için)
   flutter run
   
   # Veya belirli bir cihaz seç
   flutter run -d <device-id>
   ```

3. **Test Senaryoları**
   - **Kamera ile Test:**
     - Admin Dashboard veya Tahlil Ekle ekranına git
     - "Kamera ile Tara" butonuna tıkla
     - Kamera izni isteğini onayla
     - Bir tahlil raporu fotoğrafı çek
     - Konsol loglarını kontrol et
   
   - **Galeri ile Test:**
     - "Galeriden Seç" butonuna tıkla
     - Galeri izni isteğini onayla
     - Önceden çekilmiş bir tahlil raporu fotoğrafı seç
     - Konsol loglarını kontrol et

4. **Konsol Loglarını İzle**
   ```
   📷 Kameradan fotoğraf çekiliyor...
   ✅ Fotoğraf çekildi: /path/to/image
   🔍 OCR işlemi başlatılıyor...
   📸 OCR başlatılıyor... Platform: Android/iOS
   📁 Görüntü yolu: /path/to/image
   🔍 Android/iOS platformunda Google ML Kit kullanılıyor...
   📷 InputImage oluşturuldu: /path/to/image
   🔤 TextRecognizer başlatıldı
   📝 OCR işlemi tamamlandı. Blok sayısı: X
   ✅ OCR tamamlandı. Metin uzunluğu: XXX
   📄 Çıkarılan metin (ilk 200 karakter): ...
   🔍 Metin parse ediliyor...
   ✅ Parse tamamlandı. Bulunan alanlar: [...]
   ```

### iOS Test

1. **Simülatör veya Gerçek Cihaz Hazırlama**
   ```bash
   # iOS simülatör listesi
   flutter devices
   
   # Xcode'dan simülatör başlat
   # veya gerçek iPhone/iPad bağla
   ```

2. **Uygulamayı Çalıştır**
   ```bash
   # iOS için çalıştır
   flutter run -d <ios-device-id>
   ```

3. **Test Senaryoları** (Android ile aynı)

4. **Konsol Loglarını İzle** (Android ile aynı format)

## 🔍 Nasıl Çalıştığını Anlama

### Başarılı OCR İşlemi
- ✅ Loglar sırayla görünür
- ✅ "OCR tamamlandı" mesajı görünür
- ✅ Metin uzunluğu > 0
- ✅ Form alanları otomatik dolar

### Hata Durumları

1. **Kamera İzni Hatası**
   ```
   ❌ Kamera hatası: Permission denied
   ```
   **Çözüm:** Cihaz ayarlarından uygulamaya kamera izni verin

2. **OCR Hatası**
   ```
   ❌ OCR hatası: ...
   ```
   **Çözüm:** 
   - Fotoğrafın net olduğundan emin olun
   - Yeterli ışık olduğundan emin olun
   - Metin okunabilir olduğundan emin olun

3. **Metin Çıkarılamadı**
   ```
   ❌ OCR: Metin çıkarılamadı
   ```
   **Çözüm:**
   - Fotoğraf kalitesini artırın
   - Daha iyi ışıklandırma kullanın
   - Metni daha net görecek şekilde yakınlaştırın

## 📊 Test Kontrol Listesi

- [ ] Android emülatör/cihazda uygulama çalışıyor
- [ ] iOS simülatör/cihazda uygulama çalışıyor
- [ ] Kamera izni isteği görünüyor ve onaylanıyor
- [ ] Galeri izni isteği görünüyor ve onaylanıyor
- [ ] Kamera açılıyor ve fotoğraf çekilebiliyor
- [ ] Galeriden fotoğraf seçilebiliyor
- [ ] OCR işlemi başarıyla tamamlanıyor (konsol logları)
- [ ] Çıkarılan metin görünüyor (konsol logları)
- [ ] Form alanları otomatik doluyor (Ad Soyad, TC, Tarih vb.)

## 🐛 Debug İpuçları

1. **Logları Görmek İçin:**
   ```bash
   flutter run
   # Terminal'de loglar görünecek
   ```

2. **Detaylı Loglar:**
   - Tüm loglar `print()` ile konsola yazdırılıyor
   - Her adım için emoji'li loglar var (📷, 🔍, ✅, ❌)

3. **Hata Ayıklama:**
   - Stack trace'ler loglarda görünüyor
   - Hata mesajları Türkçe ve açıklayıcı

## 📝 Notlar

- Google ML Kit Text Recognition Android ve iOS'ta çevrimdışı çalışır
- İlk kullanımda model indirilebilir (internet gerekebilir)
- OCR doğruluğu fotoğraf kalitesine bağlıdır
- Türkçe karakterler desteklenir

