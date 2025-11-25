# E-Laboratuvar Sistemi - Flutter

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

```bash
flutter run
```

Web için:
```bash
flutter run -d chrome
```

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
