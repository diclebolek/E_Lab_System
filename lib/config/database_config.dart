import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

// Veritabanı bağlantı ayarları
class DatabaseConfig {
  // PostgreSQL bağlantı bilgileri
  // Bu bilgileri kendi veritabanınıza göre güncelleyin
  static int get port => 5432;
  static String get database => 'elab_system';
  static String get username => 'postgres';
  static String get password => 'Kenan21.'; // Kendi şifrenizi girin

  // Host adresi - Android emülatörü için özel IP
  static String get host {
    // Web platformunda PostgreSQL bağlantısı desteklenmiyor
    if (kIsWeb) {
      return 'localhost';
    }

    // Android emülatörü için özel IP adresi
    // Android emülatöründe localhost yerine 10.0.2.2 kullanılmalı
    // Bu IP adresi, emülatörün host makinesine (Windows) erişmesini sağlar
    if (Platform.isAndroid) {
      return '10.0.2.2';
    }

    // iOS simülatörü ve desktop için localhost
    return 'localhost';
  }

  // Bağlantı string'i
  static String get connectionString =>
      'postgresql://$username:$password@$host:$port/$database';
}
