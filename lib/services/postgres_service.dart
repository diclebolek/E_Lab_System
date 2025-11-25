import 'dart:convert';
import 'package:postgres/postgres.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/database_config.dart';

// PostgreSQL servisi
class PostgresService {
  static Connection? _connection;
  static int? _currentUserId;
  static int? _currentAdminId;

  // Veritabanı bağlantısı
  static Future<Connection> _getConnection() async {
    // Web platformunda PostgreSQL bağlantısı desteklenmiyor
    if (kIsWeb) {
      throw UnsupportedError(
        'Web platformunda PostgreSQL bağlantısı desteklenmiyor. '
        'Lütfen mobil uygulama veya desktop uygulaması kullanın, '
        'veya backend API kullanarak web uygulaması geliştirin.',
      );
    }

    if (_connection != null && _connection!.isOpen) {
      return _connection!;
    }

    final endpoint = Endpoint(
      host: DatabaseConfig.host,
      port: DatabaseConfig.port,
      database: DatabaseConfig.database,
      username: DatabaseConfig.username,
      password: DatabaseConfig.password,
    );

    // SSL'yi devre dışı bırak (local PostgreSQL genelde SSL gerektirmez)
    final settings = ConnectionSettings(sslMode: SslMode.disable);

    _connection = await Connection.open(endpoint, settings: settings);
    return _connection!;
  }

  // Bağlantıyı kapat
  static Future<void> closeConnection() async {
    if (_connection != null && _connection!.isOpen) {
      await _connection!.close();
      _connection = null;
    }
  }

  // Şifre hash'leme (SHA256) - Kullanıcı kaydı için hala kullanılıyor
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Kullanıcı girişi (TC ile)
  static Future<Map<String, dynamic>?> signInWithTC(String tc, String password) async {
    try {
      final conn = await _getConnection();

      // TC ve şifreyi trim yap
      final tcTrimmed = tc.trim();
      final passwordTrimmed = password.trim();

      print('🔍 Kullanıcı Giriş Denemesi:');
      print('   TC (trimmed): "$tcTrimmed"');
      print('   Şifre (trimmed): "$passwordTrimmed"');

      final result = await conn.execute(
        Sql.named(
          'SELECT id, tc_number, password_hash, full_name FROM users '
          'WHERE tc_number = @tc AND is_deleted = FALSE',
        ),
        parameters: {'tc': tcTrimmed},
      );

      print('   Sorgu sonucu: ${result.length} kayıt bulundu');

      if (result.isEmpty) {
        print('   ❌ TC bulunamadı veya is_deleted = TRUE');
        return null;
      }

      final row = result.first;
      final storedPassword = (row[2] as String?)?.trim() ?? '';

      print('   Veritabanındaki şifre hash: "${storedPassword.substring(0, storedPassword.length > 20 ? 20 : storedPassword.length)}..."');
      print('   Şifre hash uzunluğu: ${storedPassword.length}');

      // Şifreyi hash'le
      final passwordHash = _hashPassword(passwordTrimmed);
      print('   Giriş şifresi hash: "${passwordHash.substring(0, 20)}..."');

      // Hash'li şifre ile karşılaştır (yeni kayıtlar için)
      // Eğer hash eşleşmezse, düz metin ile karşılaştır (eski kayıtlar için geriye dönük uyumluluk)
      final isPasswordValid = passwordHash == storedPassword || passwordTrimmed == storedPassword;

      print('   Hash eşleşmesi: ${passwordHash == storedPassword}');
      print('   Düz metin eşleşmesi: ${passwordTrimmed == storedPassword}');
      print('   Şifre geçerli: $isPasswordValid');

      if (!isPasswordValid) {
        print('   ❌ Şifre eşleşmedi!');
        return null;
      }

      _currentUserId = row[0] as int;
      print('   ✅ Giriş başarılı! Kullanıcı ID: $_currentUserId');

      return {'id': row[0], 'tc_number': row[1], 'full_name': row[3]};
    } catch (e) {
      print('   ❌ HATA: $e');
      return null;
    }
  }

  // Kullanıcı kaydı
  static Future<Map<String, dynamic>?> signUpWithTC(
    String tc,
    String password, {
    String? fullName,
    String? gender,
    int? age,
    DateTime? birthDate,
    String? bloodType,
    String? emergencyContact,
  }) async {
    try {
      final conn = await _getConnection();

      // TC numarası kontrolü
      final checkResult = await conn.execute(
        Sql.named('SELECT id FROM users WHERE tc_number = @tc'),
        parameters: {'tc': tc},
      );

      if (checkResult.isNotEmpty) {
        throw Exception('Bu TC kimlik numarası zaten kayıtlı');
      }

      // Yeni kullanıcı ekle
      final passwordHash = _hashPassword(password);
      final result = await conn.execute(
        Sql.named(
          'INSERT INTO users (tc_number, password_hash, full_name, gender, age, birth_date, blood_type, emergency_contact) '
          'VALUES (@tc, @password, @fullName, @gender, @age, @birthDate, @bloodType, @emergencyContact) '
          'RETURNING id, tc_number',
        ),
        parameters: {
          'tc': tc,
          'password': passwordHash,
          'fullName': fullName,
          'gender': gender,
          'age': age,
          'birthDate': birthDate?.toIso8601String().split('T')[0],
          'bloodType': bloodType,
          'emergencyContact': emergencyContact,
        },
      );

      if (result.isEmpty) {
        return null;
      }

      final row = result.first;
      _currentUserId = row[0] as int;

      return {'id': row[0], 'tc_number': row[1]};
    } catch (e) {
      return null;
    }
  }

  // Admin girişi (TC ile)
  static Future<bool> signInAsAdmin(String tc, String password) async {
    try {
      final conn = await _getConnection();

      // TC ve şifreyi trim yap
      final tcTrimmed = tc.trim();
      final passwordTrimmed = password.trim();

      print('🔍 Admin Giriş Denemesi:');
      print('   TC (trimmed): "$tcTrimmed"');
      print('   Şifre (trimmed): "$passwordTrimmed"');

      final result = await conn.execute(
        Sql.named(
          'SELECT id, password_hash FROM admins '
          'WHERE tc_number = @tc AND is_active = TRUE',
        ),
        parameters: {'tc': tcTrimmed},
      );

      print('   Sorgu sonucu: ${result.length} kayıt bulundu');

      if (result.isEmpty) {
        print('   ❌ TC bulunamadı veya is_active = FALSE');
        return false;
      }

      final row = result.first;
      final storedPassword = (row[1] as String?)?.trim() ?? '';

      print('   Veritabanındaki şifre hash: "${storedPassword.substring(0, storedPassword.length > 20 ? 20 : storedPassword.length)}..."');
      print('   Şifre hash uzunluğu: ${storedPassword.length}');

      // Şifreyi hash'le
      final passwordHash = _hashPassword(passwordTrimmed);
      print('   Giriş şifresi hash: "${passwordHash.substring(0, 20)}..."');

      // Hash'li şifre ile karşılaştır (yeni kayıtlar için)
      // Eğer hash eşleşmezse, düz metin ile karşılaştır (eski kayıtlar için geriye dönük uyumluluk)
      final isPasswordValid = passwordHash == storedPassword || passwordTrimmed == storedPassword;

      print('   Hash eşleşmesi: ${passwordHash == storedPassword}');
      print('   Düz metin eşleşmesi: ${passwordTrimmed == storedPassword}');
      print('   Şifre geçerli: $isPasswordValid');

      if (!isPasswordValid) {
        print('   ❌ Şifre eşleşmedi!');
        return false;
      }

      _currentAdminId = row[0] as int;
      print('   ✅ Giriş başarılı! Admin ID: $_currentAdminId');
      return true;
    } catch (e) {
      print('   ❌ HATA: $e');
      return false;
    }
  }

  // Tahlil ekleme
  static Future<bool> addTahlil(Map<String, dynamic> tahlilData) async {
    try {
      final conn = await _getConnection();

      // TC'ye göre kullanıcı ID'sini bul
      int? userId;
      final tcNumber = tahlilData['tcNumber']?.toString().trim() ?? '';
      if (tcNumber.isNotEmpty) {
        final userResult = await conn.execute(
          Sql.named('SELECT id FROM users WHERE tc_number = @tc AND is_deleted = FALSE'),
          parameters: {'tc': tcNumber},
        );

        if (userResult.isNotEmpty) {
          userId = userResult.first[0] as int;
        }
      }

      // Doğum tarihini parse et
      DateTime? birthDate;
      if (tahlilData['birthDate'] != null) {
        if (tahlilData['birthDate'] is DateTime) {
          birthDate = tahlilData['birthDate'] as DateTime;
        } else {
          birthDate = DateTime.tryParse(tahlilData['birthDate'].toString());
        }
      }

      // Tahlil ekle
      final tahlilResult = await conn.execute(
        Sql.named(
          'INSERT INTO tahliller ('
          'user_id, full_name, tc_number, birth_date, age, gender, '
          'patient_type, sample_type, report_date, created_by'
          ') VALUES ('
          '@user_id, @full_name, @tc_number, @birth_date, @age, @gender, '
          '@patient_type, @sample_type, @report_date, @created_by'
          ') RETURNING id',
        ),
        parameters: {
          'user_id': userId,
          'full_name': tahlilData['fullName'],
          'tc_number': tcNumber,
          'birth_date': birthDate,
          'age': tahlilData['age'],
          'gender': tahlilData['gender'],
          'patient_type': tahlilData['patientType'],
          'sample_type': tahlilData['sampleType'],
          'report_date': tahlilData['reportDate'],
          'created_by': _currentAdminId,
        },
      );

      if (tahlilResult.isEmpty) {
        return false;
      }

      final tahlilId = tahlilResult.first[0] as int;

      // Serum değerlerini ekle
      final serumTypes = tahlilData['serumTypes'] as List<dynamic>? ?? [];
      for (final serum in serumTypes) {
        await conn.execute(
          Sql.named(
            'INSERT INTO serum_types (tahlil_id, type, value) '
            'VALUES (@tahlil_id, @type, @value)',
          ),
          parameters: {'tahlil_id': tahlilId, 'type': serum['type'], 'value': serum['value']},
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Tahlilleri getir (TC'ye göre) - Stream yerine Future
  static Future<List<Map<String, dynamic>>> getTahlillerByTC(String tc) async {
    try {
      final conn = await _getConnection();
      final result = await conn.execute(
        Sql.named(
          'SELECT id, full_name, tc_number, birth_date, age, gender, '
          'patient_type, sample_type, report_date, created_at '
          'FROM tahliller '
          'WHERE tc_number = @tc '
          'ORDER BY created_at DESC',
        ),
        parameters: {'tc': tc},
      );

      return result.map((row) {
        return {
          'id': row[0].toString(),
          'fullName': row[1],
          'tcNumber': row[2],
          'birthDate': row[3]?.toString(),
          'age': row[4],
          'gender': row[5],
          'patientType': row[6],
          'sampleType': row[7],
          'reportDate': row[8],
          'created_at': row[9]?.toString(),
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Tahlil detayı
  static Future<Map<String, dynamic>?> getTahlilById(String id) async {
    try {
      final conn = await _getConnection();
      final tahlilResult = await conn.execute(
        Sql.named(
          'SELECT id, full_name, tc_number, birth_date, age, gender, '
          'patient_type, sample_type, report_date '
          'FROM tahliller WHERE id = @id',
        ),
        parameters: {'id': int.parse(id)},
      );

      if (tahlilResult.isEmpty) {
        return null;
      }

      final row = tahlilResult.first;
      final serumResult = await conn.execute(
        Sql.named('SELECT type, value FROM serum_types WHERE tahlil_id = @id'),
        parameters: {'id': int.parse(id)},
      );

      final serumTypes = serumResult.map((r) => {'type': r[0], 'value': r[1]}).toList();

      return {
        'id': row[0].toString(),
        'fullName': row[1],
        'tcNumber': row[2],
        'birthDate': row[3]?.toString(),
        'age': row[4],
        'gender': row[5],
        'patientType': row[6],
        'sampleType': row[7],
        'reportDate': row[8],
        'serumTypes': serumTypes,
      };
    } catch (e) {
      return null;
    }
  }

  // Tahlil güncelleme
  static Future<bool> updateTahlil(String id, Map<String, dynamic> updates) async {
    try {
      final conn = await _getConnection();

      // Güncellenecek alanları kontrol et
      final updateFields = <String>[];
      final parameters = <String, dynamic>{'id': int.parse(id)};

      if (updates.containsKey('patientType')) {
        updateFields.add('patient_type = @patient_type');
        parameters['patient_type'] = updates['patientType'];
      }

      if (updates.containsKey('sampleType')) {
        updateFields.add('sample_type = @sample_type');
        parameters['sample_type'] = updates['sampleType'];
      }

      if (updates.containsKey('fullName')) {
        updateFields.add('full_name = @full_name');
        parameters['full_name'] = updates['fullName'];
      }

      if (updates.containsKey('age')) {
        updateFields.add('age = @age');
        parameters['age'] = updates['age'];
      }

      if (updates.containsKey('gender')) {
        updateFields.add('gender = @gender');
        parameters['gender'] = updates['gender'];
      }

      if (updates.containsKey('tcNumber')) {
        updateFields.add('tc_number = @tc_number');
        parameters['tc_number'] = updates['tcNumber'];
      }

      if (updates.containsKey('birthDate')) {
        DateTime? birthDate;
        if (updates['birthDate'] != null) {
          if (updates['birthDate'] is DateTime) {
            birthDate = updates['birthDate'] as DateTime;
          } else {
            birthDate = DateTime.tryParse(updates['birthDate'].toString());
          }
        }
        updateFields.add('birth_date = @birth_date');
        parameters['birth_date'] = birthDate;
      }

      if (updateFields.isEmpty) {
        return true; // Güncellenecek bir şey yok
      }

      // UPDATE sorgusu
      final query = 'UPDATE tahliller SET ${updateFields.join(', ')}, updated_at = CURRENT_TIMESTAMP WHERE id = @id';
      await conn.execute(Sql.named(query), parameters: parameters);

      // Serum tiplerini güncelle (eğer varsa)
      if (updates.containsKey('serumTypes')) {
        // Önce mevcut serum tiplerini sil
        await conn.execute(
          Sql.named('DELETE FROM serum_types WHERE tahlil_id = @id'),
          parameters: {'id': int.parse(id)},
        );

        // Yeni serum tiplerini ekle
        final serumTypes = updates['serumTypes'] as List<dynamic>? ?? [];
        for (final serum in serumTypes) {
          await conn.execute(
            Sql.named('INSERT INTO serum_types (tahlil_id, type, value) VALUES (@tahlil_id, @type, @value)'),
            parameters: {'tahlil_id': int.parse(id), 'type': serum['type'] ?? '', 'value': serum['value'] ?? ''},
          );
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Tahlil silme
  static Future<bool> deleteTahlil(String id) async {
    try {
      final conn = await _getConnection();

      // Önce serum tiplerini sil (CASCADE ile otomatik silinir ama emin olmak için)
      await conn.execute(Sql.named('DELETE FROM serum_types WHERE tahlil_id = @id'), parameters: {'id': int.parse(id)});

      // Tahlili sil
      await conn.execute(Sql.named('DELETE FROM tahliller WHERE id = @id'), parameters: {'id': int.parse(id)});

      return true;
    } catch (e) {
      return false;
    }
  }

  // Kılavuz ekleme
  static Future<bool> addGuide(String guideName, List<Map<String, dynamic>> data) async {
    try {
      final conn = await _getConnection();

      // Kılavuz ekle
      final guideResult = await conn.execute(
        Sql.named(
          'INSERT INTO kilavuzlar (guide_name, created_by) '
          'VALUES (@name, @created_by) RETURNING id',
        ),
        parameters: {'name': guideName, 'created_by': _currentAdminId},
      );

      if (guideResult.isEmpty) {
        return false;
      }

      final guideId = guideResult.first[0] as int;

      // Kılavuz satırlarını ekle
      for (final row in data) {
        await conn.execute(
          Sql.named(
            'INSERT INTO kilavuz_rows ('
            'kilavuz_id, age_range, geo_mean_min, geo_mean_max, '
            'mean_min, mean_max, min_value, max_value, '
            'interval_min, interval_max, serum_type, '
            'arith_mean_min, arith_mean_max'
            ') VALUES ('
            '@kilavuz_id, @age_range, @geo_mean_min, @geo_mean_max, '
            '@mean_min, @mean_max, @min_value, @max_value, '
            '@interval_min, @interval_max, @serum_type, '
            '@arith_mean_min, @arith_mean_max'
            ')',
          ),
          parameters: {
            'kilavuz_id': guideId,
            'age_range': row['ageRange'],
            'geo_mean_min': row['geoMeanMin'],
            'geo_mean_max': row['geoMeanMax'],
            'mean_min': row['meanMin'],
            'mean_max': row['meanMax'],
            'min_value': row['min'],
            'max_value': row['max'],
            'interval_min': row['intervalMin'],
            'interval_max': row['intervalMax'],
            'serum_type': row['serumType'],
            'arith_mean_min': row['arithMeanMin'],
            'arith_mean_max': row['arithMeanMax'],
          },
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Kılavuzları getir - Stream yerine Future
  static Future<List<Map<String, dynamic>>> getGuides() async {
    try {
      final conn = await _getConnection();
      final result = await conn.execute(
        Sql.named(
          'SELECT id, guide_name, created_at FROM kilavuzlar '
          'ORDER BY created_at DESC',
        ),
      );

      return result.map((row) {
        return {'id': row[0].toString(), 'name': row[1], 'created_at': row[2]?.toString()};
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Kılavuz güncelle
  static Future<bool> updateGuide(String guideName, List<Map<String, dynamic>> data, {String? newGuideName}) async {
    try {
      final conn = await _getConnection();

      // Kılavuz ID'sini bul
      final guideResult = await conn.execute(
        Sql.named('SELECT id FROM kilavuzlar WHERE guide_name = @name'),
        parameters: {'name': guideName},
      );

      if (guideResult.isEmpty) {
        return false;
      }

      final guideId = guideResult.first[0] as int;

      // Kılavuz adını güncelle (eğer değiştirildiyse)
      if (newGuideName != null && newGuideName.trim().isNotEmpty && newGuideName != guideName) {
        await conn.execute(
          Sql.named(
            'UPDATE kilavuzlar SET guide_name = @new_name, updated_at = CURRENT_TIMESTAMP '
            'WHERE id = @id',
          ),
          parameters: {'id': guideId, 'new_name': newGuideName.trim()},
        );
      }

      // Mevcut satırları sil
      await conn.execute(Sql.named('DELETE FROM kilavuz_rows WHERE kilavuz_id = @id'), parameters: {'id': guideId});

      // Yeni satırları ekle
      for (final row in data) {
        await conn.execute(
          Sql.named(
            'INSERT INTO kilavuz_rows ('
            'kilavuz_id, age_range, geo_mean_min, geo_mean_max, '
            'mean_min, mean_max, min_value, max_value, '
            'interval_min, interval_max, serum_type, '
            'arith_mean_min, arith_mean_max'
            ') VALUES ('
            '@kilavuz_id, @age_range, @geo_mean_min, @geo_mean_max, '
            '@mean_min, @mean_max, @min_value, @max_value, '
            '@interval_min, @interval_max, @serum_type, '
            '@arith_mean_min, @arith_mean_max'
            ')',
          ),
          parameters: {
            'kilavuz_id': guideId,
            'age_range': row['ageRange'],
            'geo_mean_min': row['geoMeanMin'],
            'geo_mean_max': row['geoMeanMax'],
            'mean_min': row['meanMin'],
            'mean_max': row['meanMax'],
            'min_value': row['min'],
            'max_value': row['max'],
            'interval_min': row['intervalMin'],
            'interval_max': row['intervalMax'],
            'serum_type': row['serumType'],
            'arith_mean_min': row['arithMeanMin'],
            'arith_mean_max': row['arithMeanMax'],
          },
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Kılavuz getir
  static Future<Map<String, dynamic>?> getGuide(String guideName) async {
    try {
      final conn = await _getConnection();
      final guideResult = await conn.execute(
        Sql.named('SELECT id, guide_name FROM kilavuzlar WHERE guide_name = @name'),
        parameters: {'name': guideName},
      );

      if (guideResult.isEmpty) {
        return null;
      }

      final guideId = guideResult.first[0] as int;
      final rowsResult = await conn.execute(
        Sql.named(
          'SELECT age_range, geo_mean_min, geo_mean_max, mean_min, mean_max, '
          'min_value, max_value, interval_min, interval_max, serum_type, '
          'arith_mean_min, arith_mean_max '
          'FROM kilavuz_rows WHERE kilavuz_id = @id',
        ),
        parameters: {'id': guideId},
      );

      final rows = rowsResult.map((r) {
        return {
          'ageRange': r[0],
          'geoMeanMin': r[1],
          'geoMeanMax': r[2],
          'meanMin': r[3],
          'meanMax': r[4],
          'min': r[5],
          'max': r[6],
          'intervalMin': r[7],
          'intervalMax': r[8],
          'serumType': r[9],
          'arithMeanMin': r[10],
          'arithMeanMax': r[11],
        };
      }).toList();

      return {'id': guideId.toString(), 'name': guideResult.first[1], 'rows': rows};
    } catch (e) {
      return null;
    }
  }

  // Kılavuz sil
  static Future<bool> deleteGuide(String guideName) async {
    try {
      final conn = await _getConnection();

      // Kılavuz ID'sini bul
      final guideResult = await conn.execute(
        Sql.named('SELECT id FROM kilavuzlar WHERE guide_name = @name'),
        parameters: {'name': guideName},
      );

      if (guideResult.isEmpty) {
        return false;
      }

      final guideId = guideResult.first[0] as int;

      // Önce kılavuz satırlarını sil
      await conn.execute(Sql.named('DELETE FROM kilavuz_rows WHERE kilavuz_id = @id'), parameters: {'id': guideId});

      // Sonra kılavuzu sil
      await conn.execute(Sql.named('DELETE FROM kilavuzlar WHERE id = @id'), parameters: {'id': guideId});

      return true;
    } catch (e) {
      return false;
    }
  }

  // Şifre güncelleme
  static Future<bool> updatePassword(String newPassword) async {
    try {
      if (_currentUserId == null) {
        return false;
      }

      final conn = await _getConnection();
      // Geçici olarak düz metin saklama (hash'leme yapılmadığı için)
      await conn.execute(
        Sql.named(
          'UPDATE users SET password_hash = @password, updated_at = CURRENT_TIMESTAMP '
          'WHERE id = @id',
        ),
        parameters: {'id': _currentUserId, 'password': newPassword.trim()},
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  // Kullanıcı bilgilerini getir
  static Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      if (_currentUserId == null) {
        return null;
      }

      final conn = await _getConnection();
      final result = await conn.execute(
        Sql.named(
          'SELECT id, tc_number, full_name, gender, age, birth_date, blood_type, emergency_contact, created_at, updated_at, is_deleted '
          'FROM users WHERE id = @id',
        ),
        parameters: {'id': _currentUserId},
      );

      if (result.isEmpty) {
        return null;
      }

      final row = result.first;
      return {
        'id': row[0],
        'tcNumber': row[1],
        'fullName': row[2],
        'gender': row[3],
        'age': row[4],
        'birthDate': row[5]?.toString(),
        'bloodType': row[6],
        'emergencyContact': row[7],
        'created_at': row[8]?.toString(),
        'updated_at': row[9]?.toString(),
        'is_deleted': row[10],
      };
    } catch (e) {
      return null;
    }
  }

  // Kullanıcı bilgilerini güncelle
  static Future<bool> updateUserInfo({
    String? fullName,
    DateTime? birthDate,
    int? age,
    String? gender,
    String? bloodType,
    String? emergencyContact,
  }) async {
    try {
      if (_currentUserId == null) {
        return false;
      }

      final conn = await _getConnection();
      final updateFields = <String>[];
      final parameters = <String, dynamic>{'id': _currentUserId};

      if (fullName != null && fullName.trim().isNotEmpty) {
        updateFields.add('full_name = @full_name');
        parameters['full_name'] = fullName.trim();
      }

      if (birthDate != null) {
        updateFields.add('birth_date = @birth_date');
        parameters['birth_date'] = birthDate.toIso8601String().split('T')[0];
      }

      if (age != null) {
        updateFields.add('age = @age');
        parameters['age'] = age;
      }

      if (gender != null) {
        updateFields.add('gender = @gender');
        parameters['gender'] = gender;
      }

      if (bloodType != null) {
        updateFields.add('blood_type = @blood_type');
        parameters['blood_type'] = bloodType;
      }

      if (emergencyContact != null) {
        updateFields.add('emergency_contact = @emergency_contact');
        parameters['emergency_contact'] = emergencyContact;
      }

      if (updateFields.isEmpty) {
        return true; // Güncellenecek bir şey yok
      }

      updateFields.add('updated_at = CURRENT_TIMESTAMP');

      await conn.execute(
        Sql.named('UPDATE users SET ${updateFields.join(', ')} WHERE id = @id'),
        parameters: parameters,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  // Hesap silme (soft delete)
  static Future<bool> deleteAccount() async {
    try {
      if (_currentUserId == null) {
        return false;
      }

      final conn = await _getConnection();
      await conn.execute(
        Sql.named(
          'UPDATE users SET is_deleted = TRUE, updated_at = CURRENT_TIMESTAMP '
          'WHERE id = @id',
        ),
        parameters: {'id': _currentUserId},
      );

      _currentUserId = null;
      return true;
    } catch (e) {
      return false;
    }
  }

  // Çıkış yap
  static Future<void> signOut() async {
    _currentUserId = null;
    _currentAdminId = null;
    await closeConnection();
  }

  // Tüm tahlilleri getir (admin için)
  static Future<List<Map<String, dynamic>>> getAllTahliller() async {
    try {
      final conn = await _getConnection();
      final result = await conn.execute(
        Sql.named(
          'SELECT id, full_name, tc_number, birth_date, age, gender, '
          'patient_type, sample_type, report_date, created_at '
          'FROM tahliller '
          'ORDER BY created_at DESC',
        ),
      );

      return result.map((row) {
        return {
          'id': row[0].toString(),
          'fullName': row[1],
          'tcNumber': row[2],
          'birthDate': row[3]?.toString(),
          'age': row[4],
          'gender': row[5],
          'patientType': row[6],
          'sampleType': row[7],
          'reportDate': row[8],
          'created_at': row[9]?.toString(),
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Admin bilgilerini getir
  static Future<Map<String, dynamic>?> getAdminInfo() async {
    try {
      if (_currentAdminId == null) {
        return null;
      }

      final conn = await _getConnection();
      final result = await conn.execute(
        Sql.named(
          'SELECT id, email, full_name, tc_number, created_at, updated_at, is_active '
          'FROM admins WHERE id = @id',
        ),
        parameters: {'id': _currentAdminId},
      );

      if (result.isEmpty) {
        return null;
      }

      final row = result.first;
      return {
        'id': row[0],
        'email': row[1],
        'fullName': row[2],
        'tcNumber': row[3] ?? '',
        'created_at': row[4]?.toString(),
        'updated_at': row[5]?.toString(),
        'is_active': row[6],
      };
    } catch (e) {
      return null;
    }
  }

  // Admin bilgilerini güncelle
  static Future<bool> updateAdminInfo({String? email, String? fullName, String? tcNumber}) async {
    try {
      if (_currentAdminId == null) {
        return false;
      }

      final conn = await _getConnection();
      final updates = <String, dynamic>{};

      if (email != null && email.trim().isNotEmpty) {
        // Email kontrolü - başka bir admin tarafından kullanılıyor mu?
        final checkResult = await conn.execute(
          Sql.named('SELECT id FROM admins WHERE email = @email AND id != @id'),
          parameters: {'email': email.trim(), 'id': _currentAdminId},
        );

        if (checkResult.isNotEmpty) {
          throw Exception('Bu e-posta adresi başka bir doktor tarafından kullanılıyor');
        }

        updates['email'] = email.trim();
      }

      if (fullName != null && fullName.trim().isNotEmpty) {
        updates['full_name'] = fullName.trim();
      }

      if (tcNumber != null && tcNumber.trim().isNotEmpty) {
        // TC numarası kontrolü - başka bir admin tarafından kullanılıyor mu?
        final checkResult = await conn.execute(
          Sql.named('SELECT id FROM admins WHERE tc_number = @tc AND id != @id'),
          parameters: {'tc': tcNumber.trim(), 'id': _currentAdminId},
        );

        if (checkResult.isNotEmpty) {
          throw Exception('Bu TC kimlik numarası başka bir doktor tarafından kullanılıyor');
        }

        updates['tc_number'] = tcNumber.trim();
      }

      if (updates.isEmpty) {
        return true; // Güncellenecek bir şey yok
      }

      // Dinamik UPDATE sorgusu oluştur (column isimleri snake_case)
      final updateFields = updates.keys.map((key) => '$key = @$key').join(', ');
      final query = 'UPDATE admins SET $updateFields, updated_at = CURRENT_TIMESTAMP WHERE id = @id';

      final parameters = Map<String, dynamic>.from(updates);
      parameters['id'] = _currentAdminId;

      await conn.execute(Sql.named(query), parameters: parameters);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Admin şifresini güncelle
  static Future<bool> updateAdminPassword(String newPassword) async {
    try {
      if (_currentAdminId == null) {
        return false;
      }

      final conn = await _getConnection();
      // Geçici olarak düz metin saklama (hash'leme yapılmadığı için)
      await conn.execute(
        Sql.named(
          'UPDATE admins SET password_hash = @password, updated_at = CURRENT_TIMESTAMP '
          'WHERE id = @id',
        ),
        parameters: {'id': _currentAdminId, 'password': newPassword.trim()},
      );

      return true;
    } catch (e) {
      return false;
    }
  }
}
