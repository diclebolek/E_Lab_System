# E-Laboratuvar Sistemi

Bu proje, laboratuvar tahlillerini yönetmek için geliştirilmiş modern bir Flutter uygulamasıdır.

## Özellikler

### Kullanıcı (Hasta) Tarafı
- TC kimlik numarası ile giriş/kayıt
- Geçmiş tahlilleri listeleme
- Tahlil detaylarını görüntüleme
- Profil yönetimi (şifre değiştirme, hesap silme)

### Yönetici (Doktor) Tarafı
- E-posta/şifre ile admin girişi
- Kılavuz oluşturma ve yönetme
- Tahlil ekleme
- Tahlil listeleme ve arama
- Hızlı değerlendirme (doğum tarihi ve serum değerleri ile)

## Kurulum

1. Flutter SDK'nın yüklü olduğundan emin olun
2. Proje klasörüne gidin:
   ```bash
   cd g211210055_labsystem
   ```
3. Bağımlılıkları yükleyin:
   ```bash
   flutter pub get
   ```
4. PostgreSQL Veritabanı Kurulumu:
   - PostgreSQL'in yüklü olduğundan emin olun
   - `database/schema.sql` dosyasını kullanarak veritabanını oluşturun
   - Detaylı kurulum için `database/README.md` dosyasına bakın
   - Veritabanı bağlantı bilgilerini environment variables olarak ayarlayın

## Çalıştırma

### Komut Satırı ile Çalıştırma

#### Emülatör Başlatma

Önce mevcut emülatörleri listeleyin:
```bash
flutter emulators
```

Belirli bir emülatörü başlatın (örnek: Pixel_7):
```bash
flutter emulators --launch Pixel_7
```

#### Uygulamayı Çalıştırma

Tüm cihazlarda çalıştırmak için:
```bash
flutter run
```

Belirli bir emülatörde çalıştırmak için:
```bash
flutter run -d emulator-5554
```

Web için:
```bash
flutter run -d chrome
```

**Not:** Emülatör ID'sini öğrenmek için `flutter devices` komutunu kullanabilirsiniz.

### Android Studio ile Çalıştırma

1. **Android Studio'yu Açın**
   - Android Studio'yu başlatın
   - "Open" veya "File > Open" seçeneğini kullanarak proje klasörünü (`g211210055_labsystem`) açın

2. **Flutter Plugin Kontrolü**
   - Android Studio, Flutter projesini algıladığında Flutter ve Dart plugin'lerinin yüklü olduğundan emin olun
   - Eğer yüklü değilse, "File > Settings > Plugins" menüsünden Flutter ve Dart plugin'lerini yükleyin

3. **Bağımlılıkları Yükleyin**
   - Terminal sekmesinde veya Android Studio'nun alt kısmındaki terminal'de şu komutu çalıştırın:
     ```bash
     flutter pub get
     ```
   - Eğer web platformu için ek bağımlılıklar gerekiyorsa:
     ```bash
     npm install expo-document-picker
     ```

4. **Emülatör Kurulumu ve Başlatma**
   - Mevcut emülatörleri listelemek için:
     ```bash
     flutter emulators
     ```
   - Belirli bir emülatörü başlatmak için (örnek: Pixel_7):
     ```bash
     flutter emulators --launch Pixel_7
     ```
   - Emülatör başladıktan sonra cihaz ID'sini öğrenmek için:
     ```bash
     flutter devices
     ```
   - Belirli bir emülatörde çalıştırmak için (örnek: emulator-5554):
     ```bash
     flutter run -d emulator-5554
     ```

5. **Cihaz/Emülatör Seçimi (Android Studio GUI)**
   - Üst menüden cihaz seçiciyi açın (telefon simgesi)
   - Bağlı bir Android cihaz veya çalışan bir emülatör seçin
   - Eğer cihaz yoksa, "Device Manager" üzerinden yeni bir Android emülatör oluşturun

6. **Uygulamayı Çalıştırın**
   - Yeşil "Run" butonuna (▶️) tıklayın veya `Shift + F10` tuşlarına basın
   - Alternatif olarak "Run > Run 'main.dart'" menüsünü kullanabilirsiniz

7. **Debug Modu**
   - Debug modunda çalıştırmak için yeşil böcek simgesine (🐛) tıklayın veya `Shift + F9` tuşlarına basın
   - Bu modda breakpoint'ler kullanarak kodunuzu debug edebilirsiniz

8. **Hot Reload**
   - Kod değişikliklerini anında görmek için `Ctrl + \` (Windows/Linux) veya `Cmd + \` (Mac) tuşlarına basın
   - Hot restart için `Ctrl + Shift + \` (Windows/Linux) veya `Cmd + Shift + \` (Mac) tuşlarını kullanın

## Teknolojiler

- **Flutter**: UI framework
- **PostgreSQL**: İlişkisel veritabanı
- **Responsive Framework**: Mobil ve web uyumlu tasarım

## Proje Yapısı

```
lib/
├── main.dart                 # Ana uygulama dosyası
├── config/                   # Konfigürasyon dosyaları
├── models/                   # Veri modelleri
├── services/                 # Servisler (PostgreSQL, PDF)
├── screens/
│   ├── home/                 # Ana ekran
│   ├── login/                # Giriş ekranları
│   ├── user/                 # Kullanıcı ekranları
│   └── admin/                # Admin ekranları
└── widgets/                  # Özel widget'lar
```

## Proje Sayfaları

### Ana Sayfalar

#### 1. **Home Screen** (`screens/home/home_screen.dart`)
- Uygulamanın giriş sayfasıdır
- Kullanıcı ve yönetici giriş seçenekleri sunar
- Modern ve responsive tasarıma sahiptir
- Tab yapısı ile iki farklı giriş seçeneği gösterir

### Giriş Sayfaları

#### 2. **User Login Screen** (`screens/login/user_login_screen.dart`)
- Hasta/kullanıcı giriş sayfası
- TC kimlik numarası ile giriş yapılır
- İlk girişte otomatik kayıt oluşturulur
- Şifre belirleme ve giriş işlemleri yapılır

#### 3. **Admin Login Screen** (`screens/login/admin_login_screen.dart`)
- Yönetici/doktor giriş sayfası
- E-posta ve şifre ile giriş yapılır
- Admin yetkisi kontrolü yapılır

### Kullanıcı Sayfaları

#### 4. **User Tahlil List Screen** (`screens/user/user_tahlil_list_screen.dart`)
- Kullanıcının geçmiş tahlillerini listeler
- Tarih, tahlil türü gibi filtreleme seçenekleri sunar
- Her tahlil için detay sayfasına geçiş yapılabilir
- Alt navigasyon bar ile diğer sayfalara erişim sağlar

#### 5. **User Tahlil Detail Screen** (`screens/user/user_tahlil_detail_screen.dart`)
- Seçilen tahlilin detaylı bilgilerini gösterir
- Serum değerleri, referans aralıkları ve sonuçlar görüntülenir
- PDF olarak indirme özelliği bulunur
- Kullanıcı dostu ve anlaşılır bir arayüz sunar

#### 6. **User Profile Screen** (`screens/user/user_profile_screen.dart`)
- Kullanıcı profil bilgilerini gösterir
- Şifre değiştirme özelliği
- Hesap silme işlemi
- Kişisel bilgilerin görüntülenmesi

### Yönetici Sayfaları

#### 7. **Admin Dashboard Screen** (`screens/admin/admin_dashboard_screen.dart`)
- Yönetici ana kontrol paneli
- Hızlı tahlil değerlendirme özelliği
- Doğum tarihi ve serum değerleri ile otomatik değerlendirme
- Kılavuz bazlı sonuç analizi
- Tahlil ekleme, listeleme ve kılavuz yönetimi için hızlı erişim

#### 8. **Tahlil Ekle Screen** (`screens/admin/tahlil_ekle_screen.dart`)
- Yeni tahlil kaydı oluşturma sayfası
- Hasta bilgileri girişi (TC, ad-soyad, doğum tarihi)
- Serum değerleri girişi (IgG, IgG1, IgG2, IgG3, IgG4, IgA, IgA1, IgA2, IgM)
- Tahlil sonuçlarını veritabanına kaydetme

#### 9. **Tahlil List Screen** (`screens/admin/tahlil_list_screen.dart`)
- Tüm tahlillerin listelendiği sayfa
- Arama ve filtreleme özellikleri
- Tahlil detaylarına erişim
- Hasta bazlı tahlil geçmişi görüntüleme

#### 10. **Tahlil Detail Screen** (`screens/admin/tahlil_detail_screen.dart`)
- Yönetici için tahlil detay sayfası
- Tüm tahlil bilgilerinin görüntülenmesi
- Düzenleme ve silme işlemleri
- PDF oluşturma ve indirme

#### 11. **Kilavuz Screen** (`screens/admin/kilavuz_screen.dart`)
- Yeni kılavuz oluşturma sayfası
- Kılavuz adı ve açıklama girişi
- Yaş grupları ve serum değerleri için referans aralıkları tanımlama
- Kılavuz satırları ekleme, düzenleme ve silme

#### 12. **Kilavuz List Screen** (`screens/admin/kilavuz_list_screen.dart`)
- Mevcut kılavuzların listelendiği sayfa
- Kılavuz düzenleme ve silme işlemleri
- Kılavuz detaylarını görüntüleme

#### 13. **Admin Profile Screen** (`screens/admin/admin_profile_screen.dart`)
- Yönetici profil yönetim sayfası
- Profil bilgilerini görüntüleme ve düzenleme
- Şifre değiştirme
- Çıkış yapma işlemi

#### 14. **Patient Tahlil History Screen** (`screens/admin/patient_tahlil_history_screen.dart`)
- Belirli bir hastanın tüm tahlil geçmişini gösterir
- Hasta bazlı tahlil analizi
- Tarihsel veri görüntüleme

## Veritabanı

Bu proje PostgreSQL veritabanı kullanmaktadır. Veritabanı şeması `database/schema.sql` dosyasında tanımlanmıştır.

### Veritabanı Tabloları

- **users**: Kullanıcı (hasta) bilgileri
- **admins**: Yönetici (doktor) bilgileri
- **tahliller**: Tahlil kayıtları
- **serum_types**: Tahlil serum değerleri
- **kilavuzlar**: Kılavuz tanımları
- **kilavuz_rows**: Kılavuz satır verileri

Detaylı kurulum ve kullanım için `database/README.md` dosyasına bakın.

## Notlar

- PostgreSQL veritabanı kullanılmaktadır
- Flutter uygulaması doğrudan PostgreSQL'e bağlanır (backend API gerekmez)
- Mobil ve desktop platformlarında çalışır (web platformunda postgres paketi çalışmaz)
- Responsive tasarım ile tüm ekran boyutlarına uyumludur
