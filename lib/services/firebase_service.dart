// FirebaseService artık PostgreSQL servisine yönlendiriyor
// Geriye dönük uyumluluk için bu sınıf korunuyor
import 'postgres_service.dart';

class FirebaseService {
  // Kullanıcı girişi (TC ile)
  static Future<dynamic> signInWithTC(String tc, String password) async {
    return await PostgresService.signInWithTC(tc, password);
  }

  // Kullanıcı kaydı
  static Future<dynamic> signUpWithTC(
    String tc,
    String password, {
    String? fullName,
    String? gender,
    int? age,
    DateTime? birthDate,
    String? bloodType,
    String? emergencyContact,
  }) async {
    return await PostgresService.signUpWithTC(
      tc,
      password,
      fullName: fullName,
      gender: gender,
      age: age,
      birthDate: birthDate,
      bloodType: bloodType,
      emergencyContact: emergencyContact,
    );
  }

  // Admin girişi (TC ile)
  static Future<bool> signInAsAdmin(String tc, String password) async {
    return await PostgresService.signInAsAdmin(tc, password);
  }

  // Tahlil ekleme
  static Future<bool> addTahlil(Map<String, dynamic> tahlilData) async {
    return await PostgresService.addTahlil(tahlilData);
  }

  // Tahlilleri getir (TC'ye göre) - Stream yerine Future döndürüyor
  // Not: Stream kullanan yerler için dönüşüm gerekebilir
  static Stream<dynamic> getTahlillerByTC(String tc) async* {
    final result = await PostgresService.getTahlillerByTC(tc);
    for (final item in result) {
      yield item;
    }
  }

  // Tahlil detayı
  static Future<Map<String, dynamic>?> getTahlilById(String id) async {
    return await PostgresService.getTahlilById(id);
  }

  // Tahlil güncelleme
  static Future<bool> updateTahlil(String id, Map<String, dynamic> updates) async {
    return await PostgresService.updateTahlil(id, updates);
  }

  // Tahlil silme
  static Future<bool> deleteTahlil(String id) async {
    return await PostgresService.deleteTahlil(id);
  }

  // Kılavuz ekleme
  static Future<bool> addGuide(String guideName, List<Map<String, dynamic>> data) async {
    return await PostgresService.addGuide(guideName, data);
  }

  // Kılavuz güncelleme
  static Future<bool> updateGuide(
    String guideName,
    List<Map<String, dynamic>> data, {
    String? newGuideName,
  }) async {
    return await PostgresService.updateGuide(guideName, data, newGuideName: newGuideName);
  }

  // Kılavuzları getir - Stream yerine Future döndürüyor
  static Stream<dynamic> getGuides() async* {
    final result = await PostgresService.getGuides();
    for (final item in result) {
      yield item;
    }
  }

  // Kılavuz getir
  static Future<Map<String, dynamic>?> getGuide(String guideName) async {
    return await PostgresService.getGuide(guideName);
  }

  // Kılavuz sil
  static Future<bool> deleteGuide(String guideName) async {
    return await PostgresService.deleteGuide(guideName);
  }

  // Şifre güncelleme
  static Future<bool> updatePassword(String newPassword) async {
    return await PostgresService.updatePassword(newPassword);
  }

  // Şifre değiştirme (mevcut şifre doğrulamalı)
  static Future<bool> changePassword(String currentPassword, String newPassword) async {
    return await PostgresService.changePassword(currentPassword, newPassword);
  }

  // Hesap silme
  static Future<bool> deleteAccount() async {
    return await PostgresService.deleteAccount();
  }

  // Çıkış yap
  static Future<void> signOut() async {
    await PostgresService.signOut();
  }

  // Admin bilgilerini getir
  static Future<Map<String, dynamic>?> getAdminInfo() async {
    return await PostgresService.getAdminInfo();
  }

  // Admin bilgilerini güncelle
  static Future<bool> updateAdminInfo({
    String? email,
    String? fullName,
    String? tcNumber,
  }) async {
    return await PostgresService.updateAdminInfo(
      email: email,
      fullName: fullName,
      tcNumber: tcNumber,
    );
  }

  // Admin şifresini güncelle
  static Future<bool> updateAdminPassword(String newPassword) async {
    return await PostgresService.updateAdminPassword(newPassword);
  }

  // Kullanıcı bilgilerini getir
  static Future<Map<String, dynamic>?> getUserInfo() async {
    return await PostgresService.getUserInfo();
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
    return await PostgresService.updateUserInfo(
      fullName: fullName,
      birthDate: birthDate,
      age: age,
      gender: gender,
      bloodType: bloodType,
      emergencyContact: emergencyContact,
    );
  }
}

