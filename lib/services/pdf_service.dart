import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:typed_data';

class PdfService {
  // OCR'dan çıkarılan metinden bilgileri parse etme
  static Map<String, dynamic> parseTahlilData(String extractedText) {
    final data = <String, dynamic>{};

    // TC Kimlik Numarası (11 haneli sayı)
    final tcRegex = RegExp(r'\b\d{11}\b');
    final tcMatch = tcRegex.firstMatch(extractedText);
    if (tcMatch != null) {
      data['tcNumber'] = tcMatch.group(0);
    }

    // Ad Soyad - Daha esnek pattern'ler
    // Örnekler: "Ad Soyad: Ahmet Yılmaz", "Hasta Adı: Mehmet Demir", "İsim: Ali Veli"
    final namePatterns = [
      RegExp(
        r'(?:Ad\s+Soyad|Hasta\s+Adı|İsim|Adı\s+Soyadı|Hasta\s+Adı\s+Soyadı)[:\s]*([A-ZÇĞİÖŞÜ][a-zçğıöşü]+(?:\s+[A-ZÇĞİÖŞÜ][a-zçğıöşü]+)+)',
        caseSensitive: false,
      ),
      // Direkt isim formatı (büyük harfle başlayan kelimeler)
      RegExp(r'([A-ZÇĞİÖŞÜ][a-zçğıöşü]+\s+[A-ZÇĞİÖŞÜ][a-zçğıöşü]+(?:\s+[A-ZÇĞİÖŞÜ][a-zçğıöşü]+)?)'),
    ];

    for (var pattern in namePatterns) {
      final matches = pattern.allMatches(extractedText);
      for (var match in matches) {
        final name = match.group(1)?.trim() ?? '';
        // TC numarası veya tarih gibi sayısal değerler değilse
        if (name.isNotEmpty && !RegExp(r'^\d+$').hasMatch(name) && name.length > 3 && name.length < 50) {
          data['fullName'] = name;
          break;
        }
      }
      if (data['fullName'] != null) break;
    }

    // Doğum Tarihi - Daha esnek pattern'ler
    // Farklı formatlar: "01/01/2000", "01.01.2000", "01-01-2000", "1/1/2000", "Doğum Tarihi: 01/01/2000"
    final datePatterns = [
      // "Doğum Tarihi: 01/01/2000" formatı
      RegExp(r'(?:Doğum|Doğum\s+Tarihi|Doğum\s+Tarih)[:\s]*(\d{1,2})[./-](\d{1,2})[./-](\d{4})', caseSensitive: false),
      // "01/01/2000" formatı (genel)
      RegExp(r'\b(\d{1,2})[./-](\d{1,2})[./-](\d{4})\b'),
      // "2000/01/01" formatı (ters)
      RegExp(r'\b(\d{4})[./-](\d{1,2})[./-](\d{1,2})\b'),
    ];

    DateTime? foundDate;
    for (var pattern in datePatterns) {
      final matches = pattern.allMatches(extractedText);
      for (var match in matches) {
        int? day, month, year;

        // İlk pattern'de (Doğum Tarihi: ...) format normal
        if (pattern == datePatterns[0]) {
          day = int.tryParse(match.group(1) ?? '');
          month = int.tryParse(match.group(2) ?? '');
          year = int.tryParse(match.group(3) ?? '');
        }
        // İkinci pattern'de (GG/AA/YYYY) format normal
        else if (pattern == datePatterns[1]) {
          day = int.tryParse(match.group(1) ?? '');
          month = int.tryParse(match.group(2) ?? '');
          year = int.tryParse(match.group(3) ?? '');
        }
        // Üçüncü pattern'de (YYYY/AA/GG) format ters
        else if (pattern == datePatterns[2]) {
          year = int.tryParse(match.group(1) ?? '');
          month = int.tryParse(match.group(2) ?? '');
          day = int.tryParse(match.group(3) ?? '');
        }

        if (day != null && month != null && year != null) {
          // Tarih geçerliliğini kontrol et
          if (day >= 1 && day <= 31 && month >= 1 && month <= 12 && year >= 1900 && year <= 2100) {
            try {
              final testDate = DateTime(year, month, day);
              // Geçerli bir tarih mi kontrol et
              if (testDate.year == year && testDate.month == month && testDate.day == day) {
                foundDate = testDate;
                break;
              }
            } catch (e) {
              // Tarih geçersizse devam et
            }
          }
        }
      }
      if (foundDate != null) break;
    }

    if (foundDate != null) {
      data['birthDate'] = foundDate;
    }

    // Yaş (Ay cinsinden)
    final ageRegex = RegExp(r'Yaş[:\s]*(\d+)\s*(ay|Ay|AY)', caseSensitive: false);
    final ageMatch = ageRegex.firstMatch(extractedText);
    if (ageMatch != null) {
      data['age'] = int.tryParse(ageMatch.group(1) ?? '') ?? 0;
    }

    // Cinsiyet - Daha esnek ve kapsamlı pattern'ler
    // Örnekler: "Cinsiyet: Erkek", "Cinsiyet: Kadın", "Erkek", "Kadın", "M", "F", "Male", "Female"
    final genderPatterns = [
      // "Cinsiyet: Erkek" formatı
      RegExp(r'(?:Cinsiyet|Cinsiyeti|Gender|Cinsiyet\s*:)[:\s]*([A-ZÇĞİÖŞÜa-zçğıöşü]+)', caseSensitive: false),
      // Tek başına cinsiyet kelimeleri
      RegExp(r'\b(Erkek|ERKEK|erkek|E|e|Bay|BAY|bay|Male|MALE|male|M|m)\b'),
      RegExp(r'\b(Kadın|KADIN|kadın|K|k|Bayan|BAYAN|bayan|Kız|KIZ|kız|Female|FEMALE|female|F|f)\b'),
      // Tablo formatında olabilir (Cinsiyet sütunu)
      RegExp(r'Cinsiyet\s+[:\|]\s*([A-ZÇĞİÖŞÜa-zçğıöşü]+)'),
    ];

    for (var pattern in genderPatterns) {
      final matches = pattern.allMatches(extractedText);
      for (var match in matches) {
        final genderText = (match.group(1) ?? '').toLowerCase().trim();
        if (genderText.isEmpty) continue;

        // Erkek kontrolü
        if (genderText.contains('erkek') ||
            genderText.contains('bay') ||
            genderText == 'e' ||
            genderText == 'm' ||
            genderText.contains('male')) {
          data['gender'] = 'Erkek';
          break;
        }
        // Kadın kontrolü
        else if (genderText.contains('kadın') ||
            genderText.contains('bayan') ||
            genderText.contains('kız') ||
            genderText == 'k' ||
            genderText == 'f' ||
            genderText.contains('female')) {
          data['gender'] = 'Kadın';
          break;
        }
      }
      if (data['gender'] != null) break;
    }

    // Hastalık Tanısı - OCR'dan hastalık tanısını çıkar
    // Önce "Hastalık Tanısı", "Tanı", "Diagnoz" gibi anahtar kelimeleri ara
    final diagnosisPatterns = [
      RegExp(
        r'(?:Hastalık\s+Tanısı|Tanı|Diagnoz|Diagnosis)[:\s]*([A-Za-zÇĞİÖŞÜçğıöşü\s,\.\-]+?)(?:\n|$|Numune|Rapor|Tarih|Tahlil)',
        caseSensitive: false,
      ),
    ];

    bool diagnosisFound = false;
    for (var pattern in diagnosisPatterns) {
      final match = pattern.firstMatch(extractedText);
      if (match != null) {
        final diagnosisText = match.group(1)?.trim() ?? '';
        if (diagnosisText.isNotEmpty && diagnosisText.length < 200) {
          data['patientType'] = diagnosisText;
          diagnosisFound = true;
          break;
        }
      }
    }

    // Eğer tanı bulunamazsa, eski mantıkla "Yatan Hasta" veya "Ayakta Hasta" kontrolü yap
    if (!diagnosisFound) {
      if (RegExp(r'\b(Yatan|YATAN|yatan)\b').hasMatch(extractedText)) {
        data['patientType'] = 'Yatan Hasta';
      } else if (RegExp(r'\b(Ayakta|AYAKTA|ayakta)\b').hasMatch(extractedText)) {
        data['patientType'] = 'Ayakta Hasta';
      }
    }

    // Numune Türü - Daha esnek pattern'ler
    // Örnekler: "Numune Türü: Serum", "Numune: Kan", "Örnek: Serum"
    final samplePatterns = [
      RegExp(
        r'(?:Numune\s+Türü|Numune|Örnek\s+Türü|Örnek)[:\s]*([A-Za-zÇĞİÖŞÜçğıöşü\s]+?)(?:\n|$|Rapor|Tarih|Tahlil)',
        caseSensitive: false,
      ),
      RegExp(r'(?:Serum|Kan|İdrar|Doku|Biyopsi)', caseSensitive: false),
    ];

    for (var pattern in samplePatterns) {
      final match = pattern.firstMatch(extractedText);
      if (match != null) {
        final sampleText = match.group(1)?.trim() ?? match.group(0) ?? '';
        if (sampleText.isNotEmpty && sampleText.length < 50) {
          data['sampleType'] = sampleText;
          break;
        }
      }
    }

    // Numune Alım Tarihi
    final sampleDatePatterns = [
      RegExp(
        r'(?:Numune\s+Alım\s+Tarihi|Numune\s+Tarihi|Örnek\s+Alım\s+Tarihi|Örnek\s+Tarihi)[:\s]*(\d{1,2})[./-](\d{1,2})[./-](\d{4})',
        caseSensitive: false,
      ),
      RegExp(r'(?:Alım\s+Tarihi|Alım\s+Tarih)[:\s]*(\d{1,2})[./-](\d{1,2})[./-](\d{4})', caseSensitive: false),
    ];

    DateTime? foundSampleDate;
    for (var pattern in sampleDatePatterns) {
      final matches = pattern.allMatches(extractedText);
      for (var match in matches) {
        final day = int.tryParse(match.group(1) ?? '');
        final month = int.tryParse(match.group(2) ?? '');
        final year = int.tryParse(match.group(3) ?? '');

        if (day != null &&
            month != null &&
            year != null &&
            day >= 1 &&
            day <= 31 &&
            month >= 1 &&
            month <= 12 &&
            year >= 1900 &&
            year <= 2100) {
          try {
            final testDate = DateTime(year, month, day);
            if (testDate.year == year && testDate.month == month && testDate.day == day) {
              foundSampleDate = testDate;
              break;
            }
          } catch (e) {
            // Tarih geçersizse devam et
          }
        }
      }
      if (foundSampleDate != null) break;
    }

    if (foundSampleDate != null) {
      data['sampleDate'] = foundSampleDate;
    }

    // Serum Değerleri (IgG, IgA, IgM vb.)
    final serumTypes = <Map<String, String>>[];
    final serumTypeOptions = ['IgG', 'IgG1', 'IgG2', 'IgG3', 'IgG4', 'IgA', 'IgA1', 'IgA2', 'IgM'];

    for (var serumType in serumTypeOptions) {
      // Daha esnek pattern: çeşitli formatları yakala
      // Örnekler: "IgG: 123.45", "IgG 123.45", "IgG\t123.45", "IgG:123.45 mg/dl", "IgG123.45"
      final patterns = [
        // Format: "IgG: 123.45" veya "IgG:123.45" (iki nokta ile)
        RegExp('$serumType[\\s:]+([\\d]+[.,]?\\d*)', caseSensitive: false),
        // Format: "IgG 123.45" (boşluk ile)
        RegExp('$serumType\\s+([\\d]+[.,]?\\d*)', caseSensitive: false),
        // Format: "IgG\t123.45" (tab ile)
        RegExp('$serumType\\t+([\\d]+[.,]?\\d*)', caseSensitive: false),
        // Format: "IgG123.45" (arada boşluk yok, direkt sayı)
        RegExp('$serumType([\\d]+[.,]?\\d*)', caseSensitive: false),
        // Format: Tablo formatında (satır sonunda değer)
        RegExp('$serumType[\\s\\S]{0,50}?([\\d]+[.,]?\\d*)\\s*(?:mg/dl|mg|g/L|g/l|µg/ml|µg/mL)?', caseSensitive: false),
      ];

      bool found = false;
      for (var pattern in patterns) {
        final matches = pattern.allMatches(extractedText);
        for (var match in matches) {
          var value = match.group(1)?.replaceAll(',', '.').trim() ?? '';
          // Eğer değer çok uzunsa (muhtemelen yanlış eşleşme), atla
          if (value.length > 10) continue;

          if (value.isNotEmpty) {
            // Sayısal değer kontrolü
            final numValue = double.tryParse(value);
            if (numValue != null && numValue > 0 && numValue < 100000) {
              serumTypes.add({'type': serumType, 'value': value});
              found = true;
              break;
            }
          }
        }
        if (found) break;
      }
    }

    data['serumTypes'] = serumTypes;

    // Rapor Tarihi - OCR'dan çıkar
    final reportDatePatterns = [
      RegExp(r'(?:Rapor\s+Tarihi|Rapor\s+Tarih|Tarih)[:\s]*(\d{1,2})[./-](\d{1,2})[./-](\d{4})', caseSensitive: false),
    ];

    DateTime? foundReportDate;
    for (var pattern in reportDatePatterns) {
      final matches = pattern.allMatches(extractedText);
      for (var match in matches) {
        final day = int.tryParse(match.group(1) ?? '');
        final month = int.tryParse(match.group(2) ?? '');
        final year = int.tryParse(match.group(3) ?? '');

        if (day != null &&
            month != null &&
            year != null &&
            day >= 1 &&
            day <= 31 &&
            month >= 1 &&
            month <= 12 &&
            year >= 1900 &&
            year <= 2100) {
          try {
            final testDate = DateTime(year, month, day);
            if (testDate.year == year && testDate.month == month && testDate.day == day) {
              foundReportDate = testDate;
              break;
            }
          } catch (e) {
            // Tarih geçersizse devam et
          }
        }
      }
      if (foundReportDate != null) break;
    }

    if (foundReportDate != null) {
      data['reportDate'] =
          '${foundReportDate.day.toString().padLeft(2, '0')}/${foundReportDate.month.toString().padLeft(2, '0')}/${foundReportDate.year}';
    }

    return data;
  }

  // Kameradan fotoğraf çekme
  static Future<XFile?> pickImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      return image;
    } catch (e) {
      print('❌ Kamera hatası: $e');
      rethrow; // Hatayı yukarı fırlat ki detaylı mesaj gösterilebilsin
    }
  }

  // Galeriden fotoğraf seçme
  static Future<XFile?> pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      return image;
    } catch (e) {
      return null;
    }
  }

  // OCR ile görüntüden metin çıkarma (Android/iOS ve Web uyumlu)
  static Future<String> extractTextFromImage(XFile imageFile) async {
    try {
      print('📸 OCR başlatılıyor... Platform: ${kIsWeb ? "Web" : "Android/iOS"}');
      print('📁 Görüntü yolu: ${imageFile.path}');
      
      // Web platformunda Google ML Kit kullan
      if (kIsWeb) {
        print('🔍 Web platformunda Google ML Kit kullanılıyor...');
        final Uint8List imageBytes = await imageFile.readAsBytes();
        final inputImage = InputImage.fromBytes(
          bytes: imageBytes,
          metadata: InputImageMetadata(
            size: const Size(0, 0), // Web'de size gerekli değil
            rotation: InputImageRotation.rotation0deg,
            format: InputImageFormat.nv21,
            bytesPerRow: 0,
          ),
        );

        final TextRecognizer textRecognizer = TextRecognizer();
        final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

        String extractedText = '';
        for (TextBlock block in recognizedText.blocks) {
          for (TextLine line in block.lines) {
            extractedText += '${line.text}\n';
          }
        }

        await textRecognizer.close();
        print('✅ OCR tamamlandı. Metin uzunluğu: ${extractedText.length}');
        return extractedText;
      }

      // Android/iOS platformlarında Google ML Kit kullan
      print('🔍 Android/iOS platformunda Google ML Kit kullanılıyor...');
      final inputImage = InputImage.fromFilePath(imageFile.path);
      print('📷 InputImage oluşturuldu: ${imageFile.path}');
      
      final TextRecognizer textRecognizer = TextRecognizer();
      print('🔤 TextRecognizer başlatıldı');
      
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      print('📝 OCR işlemi tamamlandı. Blok sayısı: ${recognizedText.blocks.length}');

      String extractedText = '';
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          extractedText += '${line.text}\n';
        }
      }

      await textRecognizer.close();
      print('✅ OCR tamamlandı. Metin uzunluğu: ${extractedText.length}');
      if (extractedText.isNotEmpty) {
        print('📄 Çıkarılan metin (ilk 200 karakter): ${extractedText.substring(0, extractedText.length > 200 ? 200 : extractedText.length)}...');
      }
      return extractedText;
    } catch (e, stackTrace) {
      print('❌ OCR hatası: $e');
      print('📚 Stack trace: $stackTrace');
      return '';
    }
  }

  // Kameradan fotoğraf çekip OCR ile metin çıkarma ve parse etme
  static Future<Map<String, dynamic>?> scanTahlilFromCamera() async {
    try {
      print('📷 Kameradan fotoğraf çekiliyor...');
      // Kameradan fotoğraf çek
      final XFile? image = await pickImageFromCamera();
      if (image == null) {
        print('❌ Kamera: Fotoğraf alınamadı');
        throw Exception('Kamera açılamadı veya fotoğraf çekilmedi. Lütfen kamera iznini kontrol edin.');
      }
      print('✅ Fotoğraf çekildi: ${image.path}');

      // OCR ile metin çıkar
      print('🔍 OCR işlemi başlatılıyor...');
      final extractedText = await extractTextFromImage(image);
      if (extractedText.isEmpty) {
        print('❌ OCR: Metin çıkarılamadı');
        throw Exception('Fotoğraftan metin çıkarılamadı. Lütfen fotoğrafın net ve okunabilir olduğundan emin olun.');
      }
      print('✅ OCR başarılı. Çıkarılan metin uzunluğu: ${extractedText.length}');

      // Metni parse et
      print('🔍 Metin parse ediliyor...');
      final parsedData = parseTahlilData(extractedText);
      print('✅ Parse tamamlandı. Bulunan alanlar: ${parsedData.keys.toList()}');

      return parsedData;
    } catch (e, stackTrace) {
      print('❌ scanTahlilFromCamera hatası: $e');
      print('📚 Stack trace: $stackTrace');
      rethrow; // Hatayı yukarı fırlat ki detaylı mesaj gösterilebilsin
    }
  }

  // Galeriden fotoğraf seçip OCR ile metin çıkarma ve parse etme
  static Future<Map<String, dynamic>?> scanTahlilFromGallery() async {
    try {
      // Galeriden fotoğraf seç
      final XFile? image = await pickImageFromGallery();
      if (image == null) {
        return null;
      }

      // OCR ile metin çıkar
      final extractedText = await extractTextFromImage(image);
      if (extractedText.isEmpty) {
        return null;
      }

      // Metni parse et
      final parsedData = parseTahlilData(extractedText);

      return parsedData;
    } catch (e) {
      return null;
    }
  }
}
