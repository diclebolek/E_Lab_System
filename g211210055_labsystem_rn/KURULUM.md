# Expo Projesi Kurulum ve Çalıştırma Rehberi

## 📱 Adım Adım Kurulum

### 1. Gereksinimler
- Node.js (v16 veya üzeri) - [İndir](https://nodejs.org/)
- npm veya yarn
- Expo Go uygulaması (telefonunuzda) - [iOS](https://apps.apple.com/app/expo-go/id982107779) | [Android](https://play.google.com/store/apps/details?id=host.exp.exponent)

### 2. Proje Klasörüne Gitme

VS Code Terminal'de:
```bash
cd g211210055_labsystem_rn
```

### 3. Bağımlılıkları Yükleme

```bash
npm install
```

Bu işlem birkaç dakika sürebilir. Tüm paketler yüklenecek.

### 4. Projeyi Başlatma

```bash
npm start
```

veya

```bash
npx expo start
```

### 5. Expo Go ile Bağlanma

#### Seçenek 1: QR Kod ile (Önerilen)
1. Terminal'de bir QR kod görünecek
2. Telefonunuzda Expo Go uygulamasını açın
3. QR kodu tarayın
4. Uygulama otomatik olarak yüklenecek

#### Seçenek 2: Manuel Bağlantı
1. Terminal'de görünen bağlantı linkini kopyalayın (örn: `exp://192.168.1.100:8081`)
2. Expo Go'da "Enter URL manually" seçeneğini kullanın
3. Linki yapıştırın

### 6. Geliştirme Modları

#### Android Emulator ile:
```bash
npm run android
```
(Android Studio ve emulator kurulu olmalı)

#### iOS Simulator ile (sadece Mac):
```bash
npm run ios
```
(Xcode kurulu olmalı)

#### Web Tarayıcıda:
```bash
npm run web
```

## 🔧 Sorun Giderme

### Port Zaten Kullanılıyor
```bash
npx expo start --port 8081
```

### Cache Temizleme
```bash
npx expo start -c
```

### Node Modules Sorunlu
```bash
rm -rf node_modules
npm install
```

### Expo CLI Güncelleme
```bash
npm install -g expo-cli@latest
```

### Metro Bundler Hatası
```bash
npx expo start --clear
```

## 📝 Önemli Notlar

1. **Aynı Wi-Fi Ağı**: Telefon ve bilgisayar aynı Wi-Fi ağında olmalı
2. **Firewall**: Windows Firewall Expo'ya izin vermeli
3. **Backend API**: Uygulama çalışması için backend API servisi gerekli (README.md'ye bakın)

## 🚀 Hızlı Başlangıç

```bash
# 1. Klasöre git
cd g211210055_labsystem_rn

# 2. Paketleri yükle
npm install

# 3. Başlat
npm start

# 4. QR kodu Expo Go ile tara
```

## 📱 Expo Go İndirme

- **iOS**: App Store'da "Expo Go" arayın
- **Android**: Google Play Store'da "Expo Go" arayın

## ⚠️ Backend API Gereksinimi

Bu uygulama çalışması için bir backend API servisi gerektirir. Detaylar için `README.md` dosyasına bakın.

`src/config/databaseConfig.ts` dosyasında API URL'ini ayarlayın:
```typescript
static readonly apiBaseUrl = 'http://YOUR_API_URL/api';
```

**Not:** Expo Go kullanırken, localhost yerine bilgisayarınızın IP adresini kullanın (örn: `http://192.168.1.100:3000/api`).

