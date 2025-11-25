# PostgreSQL Veritabanı Kurulumu

Bu dizin, E-Laboratuvar Sistemi için PostgreSQL veritabanı şemasını içerir.

## Kurulum Adımları

### 1. PostgreSQL Kurulumu

PostgreSQL'in yüklü olduğundan emin olun. Eğer yüklü değilse:
- Windows: https://www.postgresql.org/download/windows/
- macOS: `brew install postgresql`
- Linux: `sudo apt-get install postgresql`

### 2. Veritabanı Oluşturma

PostgreSQL'e bağlanın ve yeni bir veritabanı oluşturun:

```bash
# PostgreSQL'e bağlan
psql -U postgres

# Veritabanı oluştur
CREATE DATABASE elab_system;

# Veritabanına bağlan
\c elab_system
```

### 3. Şema Oluşturma

Şema dosyasını çalıştırın:

```bash
psql -U postgres -d elab_system -f schema.sql
```

veya psql içinde:

```sql
\i schema.sql
```

### 4. Bağlantı Bilgileri

Flutter uygulamanızda PostgreSQL'e bağlanmak için aşağıdaki bilgilere ihtiyacınız olacak:

- **Host**: localhost (veya sunucu IP adresi)
- **Port**: 5432 (varsayılan)
- **Database**: elab_system
- **Username**: postgres (veya kendi kullanıcı adınız)
- **Password**: PostgreSQL şifreniz

## Tablo Yapısı

### users
Hastaların bilgilerini saklar (TC kimlik ile giriş).

### admins
Yöneticilerin (doktorlar) bilgilerini saklar (email/şifre ile giriş).

### tahliller
Tahlil kayıtlarını saklar. Her tahlil bir kullanıcıya (user_id) ve bir yöneticiye (created_by) bağlıdır.

### serum_types
Tahlil içindeki serum değerlerini saklar. Her serum değeri bir tahlile (tahlil_id) bağlıdır.

### kilavuzlar
Kılavuzları saklar. Her kılavuz bir yönetici tarafından oluşturulur.

### kilavuz_rows
Kılavuz satırlarını saklar. Her satır bir kılavuza (kilavuz_id) bağlıdır.

## Flutter Bağlantısı

Flutter uygulamanızda PostgreSQL'e doğrudan bağlanmak için `postgres` paketini kullanılmaktadır:

```yaml
dependencies:
  postgres: ^3.0.0
```

**Not:** `postgres` paketi sadece mobil (Android/iOS) ve desktop (Windows/Mac/Linux) platformlarında çalışır. Web platformunda çalışmaz.

## Güvenlik Notları

- Şifreleri asla düz metin olarak saklamayın. `bcrypt` veya benzeri bir hash algoritması kullanın.
- Veritabanı bağlantı bilgilerini environment variables olarak saklayın.
- Production ortamında SSL bağlantısı kullanın.

