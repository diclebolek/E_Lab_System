// Veritabanı bağlantı ayarları
class DatabaseConfig {
  // PostgreSQL bağlantı bilgileri
  // Bu bilgileri kendi veritabanınıza göre güncelleyin
  static const String host = 'localhost';
  static const int port = 5432;
  static const String database = 'elab_system';
  static const String username = 'postgres';
  static const String password = 'Kenan21.'; // Kendi şifrenizi girin

  // Bağlantı string'i
  static String get connectionString =>
      'postgresql://$username:$password@$host:$port/$database';
}
