# E-Laboratuvar Sistemi - React Native (Expo)

Bu proje, Flutter projesinin React Native (Expo) versiyonudur. Aynı UI ve işlevlere sahiptir.

## Özellikler

### Kullanıcı (Hasta) Tarafı
- TC kimlik numarası ile giriş/kayıt
- Geçmiş tahlilleri listeleme
- Tahlil detaylarını görüntüleme
- Profil yönetimi (şifre değiştirme, hesap silme)

### Yönetici (Doktor) Tarafı
- TC ile admin girişi
- Kılavuz oluşturma ve yönetme
- Tahlil ekleme
- Tahlil listeleme ve arama
- Hızlı değerlendirme (doğum tarihi ve serum değerleri ile)

## Kurulum

1. Node.js ve npm'in yüklü olduğundan emin olun
2. Expo CLI'yi global olarak yükleyin:
   ```bash
   npm install -g expo-cli
   ```
3. Proje klasörüne gidin:
   ```bash
   cd g211210055_labsystem_rn
   ```
4. Bağımlılıkları yükleyin:
   ```bash
   npm install
   ```

## Backend API Servisi Gereksinimi

**ÖNEMLİ:** React Native'de direkt PostgreSQL bağlantısı yapamayız. Bu yüzden bir backend API servisi gereklidir.

### Backend API Servisi Oluşturma

Projede `src/services/PostgresService.ts` dosyası, backend API'ye HTTP istekleri gönderir. Varsayılan olarak `http://localhost:3000/api` URL'sini kullanır.

Backend API servisi şu endpoint'leri sağlamalıdır:

#### Authentication Endpoints
- `POST /api/auth/signin` - Kullanıcı girişi
- `POST /api/auth/signup` - Kullanıcı kaydı
- `POST /api/auth/admin/signin` - Admin girişi
- `POST /api/auth/signout` - Çıkış

#### Tahlil Endpoints
- `GET /api/tahliller?tc={tc}` - TC'ye göre tahlilleri getir
- `GET /api/tahliller/{id}` - Tahlil detayı
- `POST /api/tahliller` - Tahlil ekle
- `PUT /api/tahliller/{id}` - Tahlil güncelle
- `DELETE /api/tahliller/{id}` - Tahlil sil
- `GET /api/admin/tahliller` - Tüm tahlilleri getir (admin)

#### Kılavuz Endpoints
- `GET /api/kilavuzlar` - Kılavuzları getir
- `GET /api/kilavuzlar/{name}` - Kılavuz detayı
- `POST /api/kilavuzlar` - Kılavuz ekle
- `PUT /api/kilavuzlar/{name}` - Kılavuz güncelle
- `DELETE /api/kilavuzlar/{name}` - Kılavuz sil

#### User Endpoints
- `GET /api/user/info` - Kullanıcı bilgilerini getir
- `PUT /api/user/info` - Kullanıcı bilgilerini güncelle
- `PUT /api/user/password` - Şifre güncelle
- `DELETE /api/user/account` - Hesap sil

#### Admin Endpoints
- `GET /api/admin/info` - Admin bilgilerini getir
- `PUT /api/admin/info` - Admin bilgilerini güncelle
- `PUT /api/admin/password` - Admin şifresini güncelle

### Backend API URL'ini Ayarlama

`src/config/databaseConfig.ts` dosyasında `apiBaseUrl` değerini kendi backend API URL'inize göre güncelleyin:

```typescript
static readonly apiBaseUrl = 'http://YOUR_API_URL/api';
```

**Not:** Expo Go kullanırken, localhost yerine bilgisayarınızın IP adresini kullanmanız gerekebilir (örn: `http://192.168.1.100:3000/api`).

## Çalıştırma

### Expo Go ile Çalıştırma

1. Expo Go uygulamasını telefonunuza yükleyin (iOS App Store veya Google Play Store'dan)
2. Projeyi başlatın:
   ```bash
   npm start
   ```
3. QR kodu Expo Go uygulaması ile tarayın

### Android Emulator ile Çalıştırma

```bash
npm run android
```

### iOS Simulator ile Çalıştırma (sadece macOS)

```bash
npm run ios
```

### Web ile Çalıştırma

```bash
npm run web
```

## Veritabanı Yapılandırması

Veritabanı bağlantı bilgileri `src/config/databaseConfig.ts` dosyasında bulunur. Ancak bu bilgiler sadece referans içindir - gerçek bağlantı backend API servisi üzerinden yapılır.

## Proje Yapısı

```
g211210055_labsystem_rn/
├── src/
│   ├── components/          # Özel component'ler
│   ├── config/               # Konfigürasyon dosyaları
│   ├── models/               # Veri modelleri
│   ├── providers/            # Context provider'lar
│   ├── screens/              # Ekranlar
│   │   ├── admin/           # Admin ekranları
│   │   ├── home/            # Ana ekran
│   │   ├── login/           # Giriş ekranları
│   │   └── user/            # Kullanıcı ekranları
│   ├── services/             # Servisler (API çağrıları)
│   └── utils/               # Yardımcı fonksiyonlar
├── App.tsx                   # Ana uygulama dosyası
├── package.json
└── README.md
```

## Teknolojiler

- **React Native**: Mobil uygulama framework'ü
- **Expo**: React Native geliştirme platformu
- **TypeScript**: Tip güvenli JavaScript
- **React Navigation**: Navigasyon kütüphanesi
- **Axios**: HTTP istekleri için
- **AsyncStorage**: Yerel veri saklama

## Notlar

- Bu proje Expo Go ile uyumludur
- Backend API servisi olmadan çalışmaz
- Flutter projesindeki tüm özellikler burada da mevcuttur
- UI/UX Flutter projesi ile aynıdır

## Geliştirme Durumu

- ✅ Temel yapı
- ✅ Kullanıcı ekranları (giriş, tahlil listesi, profil)
- ✅ Admin ekranları (temel yapı)
- ⚠️ Admin ekranları (detaylı geliştirme devam ediyor)
- ⚠️ OCR/PDF okuma özelliği (backend API'ye entegre edilecek)

## Destek

Sorularınız için lütfen proje sahibi ile iletişime geçin.

