// Veritabanı bağlantı ayarları
export class DatabaseConfig {
  // PostgreSQL bağlantı bilgileri
  // Bu bilgileri kendi veritabanınıza göre güncelleyin
  static readonly host = 'localhost';
  static readonly port = 5432;
  static readonly database = 'elab_system';
  static readonly username = 'postgres';
  static readonly password = 'Kenan21.'; // Kendi şifrenizi girin

  // API Base URL (Backend API servisi için)
  // Not: React Native'de direkt PostgreSQL bağlantısı yapamayız, bu yüzden bir backend API servisi gerekir
  // Bu URL'yi kendi backend API servisinize göre güncelleyin
  static readonly apiBaseUrl = 'http://localhost:3000/api'; // Örnek backend API URL
}

