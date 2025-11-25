import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:provider/provider.dart';
import '../../services/firebase_service.dart';
import '../../services/pdf_service.dart';
import '../../widgets/admin_bottom_nav_bar.dart';
import '../../providers/theme_provider.dart';
import 'tahlil_ekle_screen.dart';
import 'tahlil_list_screen.dart';
import 'kilavuz_screen.dart';
import 'kilavuz_list_screen.dart';
import 'admin_profile_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _fullNameController = TextEditingController();
  final _tcController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _serumControllers = <String, TextEditingController>{};
  String _gender = '';
  int _age = 0;
  List<Map<String, dynamic>> _guides = [];
  List<Map<String, dynamic>> _evaluationResults = [];
  int _selectedNavIndex = 0; // NavigationRail için seçili index

  final _serumTypes = ['IgG', 'IgG1', 'IgG2', 'IgG3', 'IgG4', 'IgA', 'IgA1', 'IgA2', 'IgM'];
  bool _isLoadingPdf = false;
  int _textFieldKey = 0; // TextField'ı force rebuild etmek için

  @override
  void initState() {
    super.initState();
    for (var type in _serumTypes) {
      _serumControllers[type] = TextEditingController();
    }
    _loadGuides();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _tcController.dispose();
    _birthDateController.dispose();
    for (var controller in _serumControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadGuides() async {
    try {
      // Tüm kılavuzları yükle
      final guidesList = <Map<String, dynamic>>[];
      await for (var guide in FirebaseService.getGuides()) {
        guidesList.add(guide as Map<String, dynamic>);
      }

      final guides = <Map<String, dynamic>>[];

      for (var guide in guidesList) {
        final guideName = guide['name'] as String?;
        if (guideName != null) {
          final guideData = await FirebaseService.getGuide(guideName);
          if (guideData != null) {
            guides.add({'guideName': guideName, 'data': guideData['rows'] ?? []});
          }
        }
      }

      // Eğer hiç kılavuz yoksa varsayılan kılavuzları ekle
      if (guides.isEmpty) {
        guides.addAll(_getDefaultGuides());
      }

      setState(() {
        _guides = guides;
      });
    } catch (e) {
      // Hata durumunda varsayılan kılavuzları kullan
      setState(() {
        _guides = _getDefaultGuides();
      });
    }
  }

  List<Map<String, dynamic>> _getDefaultGuides() {
    return [
      {
        'guideName': 'Standart İmmünoglobulin Kılavuzu',
        'data': [
          // 0-2 yaş
          {
            'ageRange': '0-2 ay',
            'serumType': 'IgG',
            'min': 200.0,
            'max': 800.0,
            'geoMeanMin': 300.0,
            'geoMeanMax': 600.0,
          },
          {'ageRange': '0-2 ay', 'serumType': 'IgA', 'min': 5.0, 'max': 60.0, 'geoMeanMin': 10.0, 'geoMeanMax': 40.0},
          {'ageRange': '0-2 ay', 'serumType': 'IgM', 'min': 20.0, 'max': 100.0, 'geoMeanMin': 30.0, 'geoMeanMax': 70.0},
          {
            'ageRange': '0-2 ay',
            'serumType': 'IgG1',
            'min': 100.0,
            'max': 600.0,
            'geoMeanMin': 200.0,
            'geoMeanMax': 450.0,
          },
          {
            'ageRange': '0-2 ay',
            'serumType': 'IgG2',
            'min': 20.0,
            'max': 200.0,
            'geoMeanMin': 50.0,
            'geoMeanMax': 150.0,
          },
          {'ageRange': '0-2 ay', 'serumType': 'IgG3', 'min': 5.0, 'max': 80.0, 'geoMeanMin': 15.0, 'geoMeanMax': 60.0},
          {'ageRange': '0-2 ay', 'serumType': 'IgG4', 'min': 1.0, 'max': 50.0, 'geoMeanMin': 5.0, 'geoMeanMax': 35.0},
          {'ageRange': '0-2 ay', 'serumType': 'IgA1', 'min': 3.0, 'max': 45.0, 'geoMeanMin': 8.0, 'geoMeanMax': 30.0},
          {'ageRange': '0-2 ay', 'serumType': 'IgA2', 'min': 1.0, 'max': 20.0, 'geoMeanMin': 3.0, 'geoMeanMax': 15.0},
          // 2-6 yaş
          {
            'ageRange': '2-6 yıl',
            'serumType': 'IgG',
            'min': 400.0,
            'max': 1200.0,
            'geoMeanMin': 600.0,
            'geoMeanMax': 1000.0,
          },
          {
            'ageRange': '2-6 yıl',
            'serumType': 'IgA',
            'min': 20.0,
            'max': 100.0,
            'geoMeanMin': 40.0,
            'geoMeanMax': 80.0,
          },
          {
            'ageRange': '2-6 yıl',
            'serumType': 'IgM',
            'min': 30.0,
            'max': 150.0,
            'geoMeanMin': 50.0,
            'geoMeanMax': 120.0,
          },
          {
            'ageRange': '2-6 yıl',
            'serumType': 'IgG1',
            'min': 300.0,
            'max': 900.0,
            'geoMeanMin': 450.0,
            'geoMeanMax': 750.0,
          },
          {
            'ageRange': '2-6 yıl',
            'serumType': 'IgG2',
            'min': 80.0,
            'max': 350.0,
            'geoMeanMin': 150.0,
            'geoMeanMax': 280.0,
          },
          {
            'ageRange': '2-6 yıl',
            'serumType': 'IgG3',
            'min': 15.0,
            'max': 120.0,
            'geoMeanMin': 30.0,
            'geoMeanMax': 90.0,
          },
          {'ageRange': '2-6 yıl', 'serumType': 'IgG4', 'min': 5.0, 'max': 80.0, 'geoMeanMin': 15.0, 'geoMeanMax': 60.0},
          {
            'ageRange': '2-6 yıl',
            'serumType': 'IgA1',
            'min': 15.0,
            'max': 80.0,
            'geoMeanMin': 30.0,
            'geoMeanMax': 65.0,
          },
          {'ageRange': '2-6 yıl', 'serumType': 'IgA2', 'min': 5.0, 'max': 40.0, 'geoMeanMin': 10.0, 'geoMeanMax': 30.0},
          // 6-12 yaş
          {
            'ageRange': '6-12 yıl',
            'serumType': 'IgG',
            'min': 600.0,
            'max': 1500.0,
            'geoMeanMin': 800.0,
            'geoMeanMax': 1300.0,
          },
          {
            'ageRange': '6-12 yıl',
            'serumType': 'IgA',
            'min': 40.0,
            'max': 200.0,
            'geoMeanMin': 70.0,
            'geoMeanMax': 150.0,
          },
          {
            'ageRange': '6-12 yıl',
            'serumType': 'IgM',
            'min': 40.0,
            'max': 200.0,
            'geoMeanMin': 60.0,
            'geoMeanMax': 150.0,
          },
          {
            'ageRange': '6-12 yıl',
            'serumType': 'IgG1',
            'min': 450.0,
            'max': 1100.0,
            'geoMeanMin': 600.0,
            'geoMeanMax': 950.0,
          },
          {
            'ageRange': '6-12 yıl',
            'serumType': 'IgG2',
            'min': 120.0,
            'max': 450.0,
            'geoMeanMin': 200.0,
            'geoMeanMax': 380.0,
          },
          {
            'ageRange': '6-12 yıl',
            'serumType': 'IgG3',
            'min': 25.0,
            'max': 150.0,
            'geoMeanMin': 45.0,
            'geoMeanMax': 120.0,
          },
          {
            'ageRange': '6-12 yıl',
            'serumType': 'IgG4',
            'min': 10.0,
            'max': 100.0,
            'geoMeanMin': 25.0,
            'geoMeanMax': 80.0,
          },
          {
            'ageRange': '6-12 yıl',
            'serumType': 'IgA1',
            'min': 30.0,
            'max': 150.0,
            'geoMeanMin': 60.0,
            'geoMeanMax': 120.0,
          },
          {
            'ageRange': '6-12 yıl',
            'serumType': 'IgA2',
            'min': 10.0,
            'max': 60.0,
            'geoMeanMin': 20.0,
            'geoMeanMax': 50.0,
          },
          // 12-18 yaş
          {
            'ageRange': '12-18 yıl',
            'serumType': 'IgG',
            'min': 700.0,
            'max': 1600.0,
            'geoMeanMin': 900.0,
            'geoMeanMax': 1400.0,
          },
          {
            'ageRange': '12-18 yıl',
            'serumType': 'IgA',
            'min': 60.0,
            'max': 250.0,
            'geoMeanMin': 100.0,
            'geoMeanMax': 200.0,
          },
          {
            'ageRange': '12-18 yıl',
            'serumType': 'IgM',
            'min': 50.0,
            'max': 250.0,
            'geoMeanMin': 70.0,
            'geoMeanMax': 180.0,
          },
          {
            'ageRange': '12-18 yıl',
            'serumType': 'IgG1',
            'min': 500.0,
            'max': 1200.0,
            'geoMeanMin': 650.0,
            'geoMeanMax': 1050.0,
          },
          {
            'ageRange': '12-18 yıl',
            'serumType': 'IgG2',
            'min': 150.0,
            'max': 500.0,
            'geoMeanMin': 250.0,
            'geoMeanMax': 420.0,
          },
          {
            'ageRange': '12-18 yıl',
            'serumType': 'IgG3',
            'min': 30.0,
            'max': 180.0,
            'geoMeanMin': 55.0,
            'geoMeanMax': 140.0,
          },
          {
            'ageRange': '12-18 yıl',
            'serumType': 'IgG4',
            'min': 15.0,
            'max': 120.0,
            'geoMeanMin': 35.0,
            'geoMeanMax': 100.0,
          },
          {
            'ageRange': '12-18 yıl',
            'serumType': 'IgA1',
            'min': 50.0,
            'max': 200.0,
            'geoMeanMin': 90.0,
            'geoMeanMax': 170.0,
          },
          {
            'ageRange': '12-18 yıl',
            'serumType': 'IgA2',
            'min': 15.0,
            'max': 80.0,
            'geoMeanMin': 30.0,
            'geoMeanMax': 65.0,
          },
          // 18+ yaş
          {
            'ageRange': '18+ yıl',
            'serumType': 'IgG',
            'min': 700.0,
            'max': 1600.0,
            'geoMeanMin': 900.0,
            'geoMeanMax': 1400.0,
          },
          {
            'ageRange': '18+ yıl',
            'serumType': 'IgA',
            'min': 70.0,
            'max': 300.0,
            'geoMeanMin': 120.0,
            'geoMeanMax': 250.0,
          },
          {
            'ageRange': '18+ yıl',
            'serumType': 'IgM',
            'min': 40.0,
            'max': 230.0,
            'geoMeanMin': 60.0,
            'geoMeanMax': 180.0,
          },
          {
            'ageRange': '18+ yıl',
            'serumType': 'IgG1',
            'min': 500.0,
            'max': 1200.0,
            'geoMeanMin': 650.0,
            'geoMeanMax': 1050.0,
          },
          {
            'ageRange': '18+ yıl',
            'serumType': 'IgG2',
            'min': 150.0,
            'max': 550.0,
            'geoMeanMin': 280.0,
            'geoMeanMax': 450.0,
          },
          {
            'ageRange': '18+ yıl',
            'serumType': 'IgG3',
            'min': 35.0,
            'max': 200.0,
            'geoMeanMin': 65.0,
            'geoMeanMax': 150.0,
          },
          {
            'ageRange': '18+ yıl',
            'serumType': 'IgG4',
            'min': 20.0,
            'max': 140.0,
            'geoMeanMin': 45.0,
            'geoMeanMax': 110.0,
          },
          {
            'ageRange': '18+ yıl',
            'serumType': 'IgA1',
            'min': 60.0,
            'max': 250.0,
            'geoMeanMin': 110.0,
            'geoMeanMax': 210.0,
          },
          {
            'ageRange': '18+ yıl',
            'serumType': 'IgA2',
            'min': 20.0,
            'max': 100.0,
            'geoMeanMin': 40.0,
            'geoMeanMax': 80.0,
          },
        ],
      },
    ];
  }

  int _calculateAgeInYears(String birthDateStr) {
    try {
      final parts = birthDateStr.split('/');
      if (parts.length != 3) return 0;
      final birthDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      final currentDate = DateTime.now();
      int age = currentDate.year - birthDate.year;
      if (currentDate.month < birthDate.month ||
          (currentDate.month == birthDate.month && currentDate.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }

  // Galeriden fotoğraf seçip tahlil okuma ve hızlı değerlendirme alanlarını doldurma
  Future<void> _scanTahlilFromGalleryForEvaluation() async {
    setState(() => _isLoadingPdf = true);

    try {
      // Galeriden fotoğraf seç ve OCR ile metin çıkar
      final parsedData = await PdfService.scanTahlilFromGallery();
      if (parsedData == null || parsedData.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Fotoğraftan metin çıkarılamadı. Lütfen tekrar deneyin.')));
        }
        setState(() => _isLoadingPdf = false);
        return;
      }

      // Doğum tarihini doldur (setState dışında controller'ı güncelle)
      String? formattedDate;
      if (parsedData['birthDate'] != null) {
        final birthDate = parsedData['birthDate'] as DateTime;
        formattedDate =
            '${birthDate.day.toString().padLeft(2, '0')}/${birthDate.month.toString().padLeft(2, '0')}/${birthDate.year}';
      }

      // setState içinde tüm değişiklikleri yap
      setState(() {
        // Hasta bilgilerini doldur
        if (parsedData['fullName'] != null) {
          _fullNameController.text = parsedData['fullName'] as String;
        }
        if (parsedData['tcNumber'] != null) {
          _tcController.text = parsedData['tcNumber'] as String;
        }
        if (parsedData['gender'] != null) {
          _gender = parsedData['gender'] as String;
        }

        // Doğum tarihini doldur
        if (formattedDate != null) {
          _birthDateController.text = formattedDate;
          // TextField'ı force rebuild etmek için key'i değiştir
          _textFieldKey++;
          // onChanged callback'ini manuel tetikle
          if (formattedDate.length == 10) {
            _age = _calculateAgeInYears(formattedDate);
          }
        } else if (parsedData['age'] != null) {
          _age = parsedData['age'] as int;
        }

        // Serum değerlerini doldur
        if (parsedData['serumTypes'] != null) {
          final serumList = parsedData['serumTypes'] as List<Map<String, String>>;
          int filledCount = 0;
          for (var serum in serumList) {
            final type = serum['type'] ?? '';
            final value = serum['value'] ?? '';
            if (_serumControllers.containsKey(type) && value.isNotEmpty) {
              _serumControllers[type]!.text = value;
              filledCount++;
            }
          }
          // Serum TextField'larını force rebuild etmek için key'i değiştir
          if (filledCount > 0) {
            _textFieldKey++;
          }
        }
      });

      if (mounted) {
        final filledCount = parsedData.containsKey('birthDate') || parsedData.containsKey('age') ? 1 : 0;
        final serumCount = parsedData['serumTypes'] != null ? (parsedData['serumTypes'] as List).length : 0;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              serumCount > 0 || filledCount > 0
                  ? 'Fotoğraf okundu! Doğum tarihi: ${filledCount > 0 ? "✓" : "✗"}, Serum değerleri: $serumCount adet'
                  : 'Fotoğraf okundu ancak bilgi bulunamadı. Lütfen tekrar deneyin.',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Fotoğraf okunurken hata oluştu.';

        if (e.toString().contains('Kamera açılamadı') ||
            e.toString().contains('camera') ||
            e.toString().contains('permission')) {
          errorMessage =
              'Galeriden fotoğraf seçilemedi. Lütfen:\n'
              '1. Tarayıcı ayarlarından dosya erişim iznini kontrol edin\n'
              '2. Fotoğraf dosyasının geçerli bir formatta olduğundan emin olun';
        } else if (e.toString().contains('metin çıkarılamadı')) {
          errorMessage = 'Fotoğraftan metin çıkarılamadı. Lütfen fotoğrafın net ve okunabilir olduğundan emin olun.';
        } else {
          errorMessage = 'Hata: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red, duration: const Duration(seconds: 5)),
        );
      }
    } finally {
      setState(() => _isLoadingPdf = false);
    }
  }

  // Kamera ile tahlil okuma ve hızlı değerlendirme alanlarını doldurma
  Future<void> _scanTahlilForEvaluation() async {
    setState(() => _isLoadingPdf = true);

    try {
      // Kameradan fotoğraf çek ve OCR ile metin çıkar
      final parsedData = await PdfService.scanTahlilFromCamera();
      if (parsedData == null || parsedData.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Fotoğraftan metin çıkarılamadı. Lütfen tekrar deneyin.')));
        }
        setState(() => _isLoadingPdf = false);
        return;
      }

      // Doğum tarihini doldur (setState dışında controller'ı güncelle)
      String? formattedDate;
      if (parsedData['birthDate'] != null) {
        final birthDate = parsedData['birthDate'] as DateTime;
        formattedDate =
            '${birthDate.day.toString().padLeft(2, '0')}/${birthDate.month.toString().padLeft(2, '0')}/${birthDate.year}';
      }

      // setState içinde tüm değişiklikleri yap
      setState(() {
        // Hasta bilgilerini doldur
        if (parsedData['fullName'] != null) {
          _fullNameController.text = parsedData['fullName'] as String;
        }
        if (parsedData['tcNumber'] != null) {
          _tcController.text = parsedData['tcNumber'] as String;
        }
        if (parsedData['gender'] != null) {
          _gender = parsedData['gender'] as String;
        }

        // Doğum tarihini doldur
        if (formattedDate != null) {
          _birthDateController.text = formattedDate;
          // TextField'ı force rebuild etmek için key'i değiştir
          _textFieldKey++;
          // onChanged callback'ini manuel tetikle
          if (formattedDate.length == 10) {
            _age = _calculateAgeInYears(formattedDate);
          }
        } else if (parsedData['age'] != null) {
          _age = parsedData['age'] as int;
        }

        // Serum değerlerini doldur
        if (parsedData['serumTypes'] != null) {
          final serumList = parsedData['serumTypes'] as List<Map<String, String>>;
          int filledCount = 0;
          for (var serum in serumList) {
            final type = serum['type'] ?? '';
            final value = serum['value'] ?? '';
            if (_serumControllers.containsKey(type) && value.isNotEmpty) {
              _serumControllers[type]!.text = value;
              filledCount++;
            }
          }
          // Serum TextField'larını force rebuild etmek için key'i değiştir
          if (filledCount > 0) {
            _textFieldKey++;
          }
        }
      });

      if (mounted) {
        final filledCount = parsedData.containsKey('birthDate') || parsedData.containsKey('age') ? 1 : 0;
        final serumCount = parsedData['serumTypes'] != null ? (parsedData['serumTypes'] as List).length : 0;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              serumCount > 0 || filledCount > 0
                  ? 'Fotoğraf okundu! Doğum tarihi: ${filledCount > 0 ? "✓" : "✗"}, Serum değerleri: $serumCount adet'
                  : 'Fotoğraf okundu ancak bilgi bulunamadı. Lütfen tekrar deneyin.',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Fotoğraf okunurken hata oluştu.';

        // Daha anlaşılır hata mesajları
        if (e.toString().contains('Kamera açılamadı') ||
            e.toString().contains('camera') ||
            e.toString().contains('permission')) {
          errorMessage =
              'Kamera açılamadı. Lütfen:\n'
              '1. Tarayıcı ayarlarından kamera iznini kontrol edin\n'
              '2. HTTPS kullanıyorsanız (localhost hariç) emin olun\n'
              '3. Başka bir uygulama kamerayı kullanıyor olabilir';
        } else if (e.toString().contains('metin çıkarılamadı')) {
          errorMessage = 'Fotoğraftan metin çıkarılamadı. Lütfen fotoğrafın net ve okunabilir olduğundan emin olun.';
        } else {
          errorMessage = 'Hata: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red, duration: const Duration(seconds: 5)),
        );
      }
    } finally {
      setState(() => _isLoadingPdf = false);
    }
  }

  String _evaluateSerumValue(double serumValue, double min, double max) {
    if (serumValue < min) return '↓';
    if (serumValue > max) return '↑';
    return '↔';
  }

  String _getStatusText(String arrow) {
    switch (arrow) {
      case '↓':
        return 'Düşük';
      case '↑':
        return 'Yüksek';
      case '↔':
        return 'Normal';
      default:
        return '';
    }
  }

  IconData _getStatusIcon(String arrow) {
    switch (arrow) {
      case '↓':
        return Icons.arrow_downward;
      case '↑':
        return Icons.arrow_upward;
      case '↔':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  // Güvenli sayı dönüştürme - String, int veya double olabilir
  double? _safeToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }

  // Yaş aralığını parse et (ay veya yıl)
  bool _isAgeInRange(String ageRange, int age) {
    try {
      final isPlus = ageRange.contains('+');
      if (isPlus) {
        final minAgeStr = ageRange.replaceAll('+', '').trim();
        final minAge = int.tryParse(minAgeStr.replaceAll(RegExp(r'[^0-9]'), ''));
        if (minAge != null) {
          // Eğer ay ise yıla çevir
          if (ageRange.contains('ay')) {
            return age >= (minAge ~/ 12);
          }
          return age >= minAge;
        }
      } else if (ageRange.contains('-')) {
        final parts = ageRange.split('-');
        final minAgeStr = parts[0].trim();
        final maxAgeStr = parts.length > 1 ? parts[1].trim() : '';

        final minAge = int.tryParse(minAgeStr.replaceAll(RegExp(r'[^0-9]'), ''));
        final maxAge = maxAgeStr.isNotEmpty ? int.tryParse(maxAgeStr.replaceAll(RegExp(r'[^0-9]'), '')) : null;

        // Ay veya yıl kontrolü
        final isMonth = ageRange.contains('ay');

        if (minAge != null && maxAge != null) {
          if (isMonth) {
            // Ay aralığını yıla çevir (yaklaşık)
            final minYear = minAge ~/ 12;
            final maxYear = (maxAge / 12).ceil();
            return age >= minYear && age <= maxYear;
          }
          return age >= minAge && age <= maxAge;
        } else if (minAge != null) {
          if (isMonth) {
            return age >= (minAge ~/ 12);
          }
          return age >= minAge;
        } else if (maxAge != null) {
          if (isMonth) {
            return age <= (maxAge / 12).ceil();
          }
          return age <= maxAge;
        }
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  // Belirli bir serum tipi için yaş aralığına göre değerlendirme al
  Map<String, dynamic>? _getSerumEvaluation(String serumType, double value) {
    if (_age == 0 || _guides.isEmpty) return null;

    for (var guide in _guides) {
      final guideData = guide['data'] as List;
      final filteredRows = guideData.where((row) {
        final ageRange = row['ageRange'] as String? ?? '';
        return _isAgeInRange(ageRange, _age);
      }).toList();

      for (var row in filteredRows) {
        if (row['serumType'] == serumType) {
          // Öncelik sırası: min/max > geoMean > arithMean > mean > interval
          final minValue = _safeToDouble(row['min']);
          final maxValue = _safeToDouble(row['max']);
          if (minValue != null && maxValue != null) {
            final arrow = _evaluateSerumValue(value, minValue, maxValue);
            return {
              'arrow': arrow,
              'range': '${row['min']}-${row['max']}',
              'rangeType': 'Normal Sınırlar',
              'guideName': guide['guideName'],
            };
          }
          final geoMeanMin = _safeToDouble(row['geoMeanMin']);
          final geoMeanMax = _safeToDouble(row['geoMeanMax']);
          if (geoMeanMin != null && geoMeanMax != null) {
            final arrow = _evaluateSerumValue(value, geoMeanMin, geoMeanMax);
            return {
              'arrow': arrow,
              'range': '${row['geoMeanMin']}-${row['geoMeanMax']}',
              'rangeType': 'GeoMean',
              'guideName': guide['guideName'],
            };
          }
        }
      }
    }
    return null;
  }

  void _handleEvaluate() {
    if (_birthDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen doğum tarihini girin!')));
      return;
    }

    final serumValues = <String, double>{};
    for (var entry in _serumControllers.entries) {
      final value = entry.value.text.trim();
      if (value.isNotEmpty) {
        serumValues[entry.key] = double.tryParse(value) ?? 0;
      }
    }

    if (serumValues.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen en az bir serum değeri girin!')));
      return;
    }

    final results = <Map<String, dynamic>>[];

    for (var guide in _guides) {
      final guideData = guide['data'] as List;
      final filteredRows = guideData.where((row) {
        final ageRange = row['ageRange'] as String? ?? '';
        return _isAgeInRange(ageRange, _age);
      }).toList();

      final evaluations = <Map<String, dynamic>>[];

      for (var row in filteredRows) {
        final serumType = row['serumType'] as String;
        if (serumValues.containsKey(serumType)) {
          final value = serumValues[serumType]!;
          final evaluation = <String, dynamic>{'serumType': serumType};

          // Öncelik sırası: min/max (Normal Alt/Üst Sınır) > geoMean > arithMean > mean > interval
          final minValue = _safeToDouble(row['min']);
          final maxValue = _safeToDouble(row['max']);
          if (minValue != null && maxValue != null) {
            final arrow = _evaluateSerumValue(value, minValue, maxValue);
            evaluation['normalRange'] = '${row['min']}-${row['max']}';
            evaluation['normalArrow'] = arrow;
            evaluation['rangeType'] = 'Normal Sınırlar';
          }
          final geoMeanMin = _safeToDouble(row['geoMeanMin']);
          final geoMeanMax = _safeToDouble(row['geoMeanMax']);
          if (geoMeanMin != null && geoMeanMax != null) {
            final arrow = _evaluateSerumValue(value, geoMeanMin, geoMeanMax);
            evaluation['geoMean'] = '${row['geoMeanMin']}-${row['geoMeanMax']}';
            evaluation['geoMeanArrow'] = arrow;
          }
          final arithMeanMin = _safeToDouble(row['arithMeanMin']);
          final arithMeanMax = _safeToDouble(row['arithMeanMax']);
          if (arithMeanMin != null && arithMeanMax != null) {
            final arrow = _evaluateSerumValue(value, arithMeanMin, arithMeanMax);
            evaluation['arithMean'] = '${row['arithMeanMin']}-${row['arithMeanMax']}';
            evaluation['arithMeanArrow'] = arrow;
          }
          final meanMin = _safeToDouble(row['meanMin']);
          final meanMax = _safeToDouble(row['meanMax']);
          if (meanMin != null && meanMax != null) {
            final arrow = _evaluateSerumValue(value, meanMin, meanMax);
            evaluation['mean'] = '${row['meanMin']}-${row['meanMax']}';
            evaluation['meanArrow'] = arrow;
          }
          final intervalMin = _safeToDouble(row['intervalMin']);
          final intervalMax = _safeToDouble(row['intervalMax']);
          if (intervalMin != null && intervalMax != null) {
            final arrow = _evaluateSerumValue(value, intervalMin, intervalMax);
            evaluation['interval'] = '${row['intervalMin']}-${row['intervalMax']}';
            evaluation['intervalArrow'] = arrow;
          }

          if (evaluation.length > 1) {
            evaluations.add(evaluation);
          }
        }
      }

      if (evaluations.isNotEmpty) {
        results.add({
          'guideName': guide['guideName'],
          'ageRange': filteredRows.isNotEmpty ? filteredRows[0]['ageRange'] : '-',
          'evaluations': evaluations,
        });
      }
    }

    setState(() {
      _evaluationResults = results;
    });
  }

  Color _getArrowColor(String arrow) {
    switch (arrow) {
      case '↓':
        return Colors.red;
      case '↑':
        return Colors.blue;
      case '↔':
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Scaffold(
      appBar: AppBar(
        title: isMobile
            ? const Align(alignment: Alignment.centerLeft, child: Text('Doktor Rapor Yönetim Paneli'))
            : const Text('Doktor Rapor Yönetim Paneli'),
        automaticallyImplyLeading: false, // Geri butonunu gizle
        toolbarHeight: 56,
        elevation: 0,
        centerTitle: !isMobile,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0058A3), Color(0xFF00A8E8)],
            ),
          ),
        ),
        actions: [
          if (isMobile)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
                tooltip: 'Menü',
              ),
            ),
        ],
      ),
      endDrawer: isMobile
          ? Drawer(
              child: ListView(
                children: [
                  DrawerHeader(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0058A3), Color(0xFF00A8E8)],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.local_hospital, color: Colors.white, size: 48),
                        const SizedBox(height: 8),
                        const Text(
                          'Doktor Paneli',
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.dashboard),
                    title: const Text('Ana Sayfa'),
                    selected: true,
                    selectedTileColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    onTap: () => Navigator.pop(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.add_circle),
                    title: const Text('Kılavuz Oluştur'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const KilavuzScreen()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.list),
                    title: const Text('Kılavuz Listesi'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const KilavuzListScreen()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('Tahlil Ekle'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const TahlilEkleScreen()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.assignment),
                    title: const Text('Tahlil Listesi'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const TahlilListScreen()));
                    },
                  ),
                  const Divider(),
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) {
                      return ListTile(
                        leading: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
                        title: Text(themeProvider.isDarkMode ? 'Açık Mod' : 'Koyu Mod'),
                        onTap: () {
                          themeProvider.toggleTheme();
                        },
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Profil Ayarları'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminProfileScreen()));
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
                    onTap: () async {
                      Navigator.pop(context);
                      await FirebaseService.signOut();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/');
                      }
                    },
                  ),
                ],
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile)
            NavigationRail(
              selectedIndex: _selectedNavIndex,
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
              selectedLabelTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              unselectedIconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
              unselectedLabelTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Ana Sayfa'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.add_circle),
                  selectedIcon: Icon(Icons.add_circle),
                  label: Text('Kılavuz Oluştur'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.list),
                  selectedIcon: Icon(Icons.list),
                  label: Text('Kılavuz Listesi'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.add),
                  selectedIcon: Icon(Icons.add),
                  label: Text('Tahlil Ekle'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.assignment),
                  selectedIcon: Icon(Icons.assignment),
                  label: Text('Tahlil Listesi'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Ayarlar'),
                ),
              ],
              onDestinationSelected: (index) {
                setState(() {
                  _selectedNavIndex = index;
                });
                switch (index) {
                  case 1:
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const KilavuzScreen()));
                    break;
                  case 2:
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const KilavuzListScreen()));
                    break;
                  case 3:
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const TahlilEkleScreen()));
                    break;
                  case 4:
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const TahlilListScreen()));
                    break;
                  case 5:
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminProfileScreen()));
                    break;
                }
              },
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 24,
                isMobile ? 16 : 16,
                isMobile ? 16 : 24,
                isMobile ? 16 : 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Başlık ve Kamera Butonu
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF0058A3), Color(0xFF00A8E8)]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Hızlı Değerlendirme',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                      SizedBox(width: isMobile ? 8 : 12),
                      Flexible(
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFF0058A3), Color(0xFF00A8E8)]),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0058A3).withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  onPressed: _isLoadingPdf ? null : _scanTahlilForEvaluation,
                                  icon: _isLoadingPdf
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Icon(Icons.camera_alt, color: Colors.white, size: 24),
                                  tooltip: 'Kamera ile Otomatik Doldur',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFF00A8E8), Color(0xFF0058A3)]),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00A8E8).withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  onPressed: _isLoadingPdf ? null : _scanTahlilFromGalleryForEvaluation,
                                  icon: _isLoadingPdf
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Icon(Icons.photo_library, color: Colors.white, size: 24),
                                  tooltip: 'Galeri ile Otomatik Doldur',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0058A3).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFF0058A3), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Kameradan çekerek veya galeriden seçerek tahlil belgesini okutabilirsiniz. Web\'de galeri seçeneği daha güvenilir çalışır.',
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Hasta Bilgileri
                  const Text('Hasta Bilgileri:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(labelText: 'Ad Soyad', prefixIcon: Icon(Icons.person)),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _tcController,
                    decoration: const InputDecoration(labelText: 'TC Kimlik No', prefixIcon: Icon(Icons.badge)),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _gender.isEmpty ? null : _gender,
                    decoration: const InputDecoration(labelText: 'Cinsiyet', prefixIcon: Icon(Icons.wc)),
                    items: const [
                      DropdownMenuItem(value: 'Erkek', child: Text('Erkek')),
                      DropdownMenuItem(value: 'Kadın', child: Text('Kadın')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _gender = value ?? '';
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    key: ValueKey('birthDate_$_textFieldKey'), // UI güncellemesi için key
                    controller: _birthDateController,
                    decoration: const InputDecoration(
                      labelText: 'Doğum Tarihi (GG/AA/YYYY)',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    onChanged: (value) {
                      if (value.length == 10) {
                        setState(() {
                          _age = _calculateAgeInYears(value);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0058A3).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFF0058A3), size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Yaş (Yıl): $_age',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0058A3)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Serum Değerleri:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _serumTypes.map((type) {
                      final value = double.tryParse(_serumControllers[type]!.text.trim());
                      final evaluation = value != null && _age > 0 ? _getSerumEvaluation(type, value) : null;
                      final statusColor = evaluation != null ? _getArrowColor(evaluation['arrow']) : Colors.grey;
                      final statusIcon = evaluation != null ? _getStatusIcon(evaluation['arrow']) : Icons.help_outline;

                      return SizedBox(
                        width: isMobile ? double.infinity : 200,
                        child: TextField(
                          key: ValueKey('serum_${type}_$_textFieldKey'), // UI güncellemesi için key
                          controller: _serumControllers[type],
                          decoration: InputDecoration(
                            labelText: type,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: statusColor.withValues(alpha: 0.5), width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: statusColor.withValues(alpha: 0.5), width: 2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: statusColor, width: 2),
                            ),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(color: statusColor, width: 2),
                              ),
                              child: Icon(statusIcon, color: statusColor, size: 20),
                            ),
                            suffixIcon: evaluation != null
                                ? Container(
                                    margin: const EdgeInsets.all(8),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: statusColor, width: 1),
                                    ),
                                    child: Center(
                                      child: Text(
                                        evaluation['arrow'],
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: statusColor),
                                      ),
                                    ),
                                  )
                                : null,
                            helperText: evaluation != null
                                ? '${evaluation['rangeType']}: ${evaluation['range']} mg/dl'
                                : _age > 0
                                ? 'Değer girin'
                                : 'Önce yaş bilgisini girin',
                            helperMaxLines: 2,
                            filled: true,
                            fillColor: statusColor.withValues(alpha: 0.03),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              // Değerlendirmeyi güncellemek için state'i tetikle
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleEvaluate,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('Değerlendir'),
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (_evaluationResults.isNotEmpty) ...[
                    const Text(
                      'Kılavuzlara Göre Değerlendirmeler',
                      style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: Color(0xFF0058A3)),
                    ),
                    const SizedBox(height: 20),
                    ..._evaluationResults.map((result) {
                      // Serum değerlerini al
                      final serumValues = <String, double>{};
                      for (var entry in _serumControllers.entries) {
                        final value = entry.value.text.trim();
                        if (value.isNotEmpty) {
                          serumValues[entry.key] = double.tryParse(value) ?? 0;
                        }
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 20),
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          result['guideName'],
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0058A3),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Yaş Aralığı: ${result['ageRange']}',
                                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0058A3).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Uygun Kılavuz',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0058A3),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 16),
                              ...(result['evaluations'] as List).map((eval) {
                                final serumType = eval['serumType'] as String;
                                final currentValue = serumValues[serumType] ?? 0.0;
                                final arrow =
                                    eval['normalArrow'] ??
                                    eval['geoMeanArrow'] ??
                                    eval['arithMeanArrow'] ??
                                    eval['meanArrow'] ??
                                    eval['intervalArrow'] ??
                                    '';
                                final range =
                                    eval['normalRange'] ??
                                    eval['geoMean'] ??
                                    eval['arithMean'] ??
                                    eval['mean'] ??
                                    eval['interval'] ??
                                    '';
                                final statusText = _getStatusText(arrow);
                                final statusColor = _getArrowColor(arrow);

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  color: statusColor.withValues(alpha: 0.05),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(color: statusColor.withValues(alpha: 0.3), width: 1),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        // Durum ikonu
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: statusColor, width: 2),
                                          ),
                                          child: Center(
                                            child: Text(
                                              arrow,
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: statusColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Bilgiler
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                serumType,
                                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Değer: $currentValue mg/dl',
                                                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                              ),
                                              if (range.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Normal Aralık: $range mg/dl',
                                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        // Durum metni
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            statusText,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: statusColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isMobile
          ? AdminBottomNavBar(
              currentIndex: 2,
              onTap: (index) {
                switch (index) {
                  case 0:
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const KilavuzScreen()));
                    break;
                  case 1:
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const KilavuzListScreen()));
                    break;
                  case 2:
                    // Zaten ana sayfadayız
                    break;
                  case 3:
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const TahlilEkleScreen()));
                    break;
                  case 4:
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const TahlilListScreen()));
                    break;
                }
              },
            )
          : null,
    );
  }
}
