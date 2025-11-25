import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/firebase_service.dart';
import '../../services/pdf_service.dart';
import '../../models/tahlil_model.dart';
import '../../widgets/admin_bottom_nav_bar.dart';
import '../../providers/theme_provider.dart';
import 'admin_dashboard_screen.dart';
import 'admin_profile_screen.dart';
import 'kilavuz_screen.dart';
import 'kilavuz_list_screen.dart';
import 'tahlil_list_screen.dart';

class TahlilEkleScreen extends StatefulWidget {
  const TahlilEkleScreen({super.key});

  @override
  State<TahlilEkleScreen> createState() => _TahlilEkleScreenState();
}

class _TahlilEkleScreenState extends State<TahlilEkleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _tcController = TextEditingController();
  final _sampleTypeController = TextEditingController();

  DateTime? _birthDate;
  DateTime? _sampleDate;
  int _age = 0;
  String _gender = '';
  String _patientType = '';
  String _selectedSerumType = '';
  final _serumValueController = TextEditingController();
  final List<SerumType> _serumTypes = [];
  bool _isLoadingPdf = false;
  int _selectedNavIndex = 3; // NavigationRail için seçili index

  final _serumTypeOptions = ['IgG', 'IgG1', 'IgG2', 'IgG3', 'IgG4', 'IgA', 'IgA1', 'IgA2', 'IgM'];

  @override
  void dispose() {
    _fullNameController.dispose();
    _tcController.dispose();
    _sampleTypeController.dispose();
    _serumValueController.dispose();
    super.dispose();
  }

  int _calculateAgeInYears(DateTime birthDate) {
    final currentDate = DateTime.now();
    int age = currentDate.year - birthDate.year;
    if (currentDate.month < birthDate.month ||
        (currentDate.month == birthDate.month && currentDate.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // Galeriden fotoğraf seçip tahlil okuma ve otomatik doldurma
  Future<void> _scanTahlilFromGallery() async {
    setState(() => _isLoadingPdf = true);

    try {
      // Galeriden fotoğraf seç ve OCR ile metin çıkar
      final parsedData = await PdfService.scanTahlilFromGallery();
      if (parsedData == null || parsedData.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Fotoğraftan metin çıkarılamadı. Lütfen fotoğrafın net ve okunabilir olduğundan emin olun.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => _isLoadingPdf = false);
        return;
      }

      // Form alanlarını doldur
      setState(() {
        if (parsedData['fullName'] != null) {
          _fullNameController.text = parsedData['fullName'] as String;
        }
        if (parsedData['tcNumber'] != null) {
          _tcController.text = parsedData['tcNumber'] as String;
        }
        if (parsedData['birthDate'] != null) {
          _birthDate = parsedData['birthDate'] as DateTime;
          _age = _calculateAgeInYears(_birthDate!);
        } else if (parsedData['age'] != null) {
          _age = parsedData['age'] as int;
        }
        if (parsedData['gender'] != null) {
          _gender = parsedData['gender'] as String;
        }
        if (parsedData['patientType'] != null) {
          _patientType = parsedData['patientType'] as String;
        }
        if (parsedData['sampleType'] != null) {
          _sampleTypeController.text = parsedData['sampleType'] as String;
        }
        if (parsedData['sampleDate'] != null) {
          _sampleDate = parsedData['sampleDate'] as DateTime;
        }
        if (parsedData['serumTypes'] != null) {
          final serumList = parsedData['serumTypes'] as List<Map<String, String>>;
          _serumTypes.clear();
          for (var serum in serumList) {
            _serumTypes.add(SerumType(type: serum['type'] ?? '', value: serum['value'] ?? ''));
          }
        }
      });

      // Kameradan okunan verilerle otomatik kaydet
      if (mounted && _birthDate != null && _serumTypes.isNotEmpty && _fullNameController.text.trim().isNotEmpty) {
        // Minimum gerekli alanlar dolu, otomatik kaydet
        final reportDate = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

        final tahlilData = {
          'fullName': _fullNameController.text.trim(),
          'tcNumber': _tcController.text.trim(),
          'birthDate': _birthDate,
          'age': _age,
          'gender': _gender,
          'patientType': _patientType,
          'sampleType': _sampleTypeController.text.trim(),
          'sampleDate': _sampleDate,
          'serumTypes': _serumTypes.map((s) => s.toMap()).toList(),
          'reportDate': reportDate,
        };

        final success = await FirebaseService.addTahlil(tahlilData);

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fotoğraf okundu ve tahlil otomatik olarak kaydedildi!'),
                backgroundColor: Colors.green,
              ),
            );
            _resetForm();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Fotoğraf okundu ancak tahlil kaydedilirken bir hata oluştu. Lütfen manuel olarak kaydedin.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fotoğraf başarıyla okundu ve form dolduruldu! Lütfen eksik bilgileri tamamlayıp kaydedin.'),
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

  // Kamera ile tahlil okuma ve otomatik doldurma
  Future<void> _scanTahlilFromCamera() async {
    setState(() => _isLoadingPdf = true);

    try {
      // Kameradan fotoğraf çek ve OCR ile metin çıkar
      final parsedData = await PdfService.scanTahlilFromCamera();
      if (parsedData == null || parsedData.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Fotoğraftan metin çıkarılamadı. Lütfen fotoğrafın net ve okunabilir olduğundan emin olun.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => _isLoadingPdf = false);
        return;
      }

      // Form alanlarını doldur
      setState(() {
        if (parsedData['fullName'] != null) {
          _fullNameController.text = parsedData['fullName'] as String;
        }
        if (parsedData['tcNumber'] != null) {
          _tcController.text = parsedData['tcNumber'] as String;
        }
        if (parsedData['birthDate'] != null) {
          _birthDate = parsedData['birthDate'] as DateTime;
          _age = _calculateAgeInYears(_birthDate!);
        } else if (parsedData['age'] != null) {
          _age = parsedData['age'] as int;
        }
        if (parsedData['gender'] != null) {
          _gender = parsedData['gender'] as String;
        }
        if (parsedData['patientType'] != null) {
          _patientType = parsedData['patientType'] as String;
        }
        if (parsedData['sampleType'] != null) {
          _sampleTypeController.text = parsedData['sampleType'] as String;
        }
        if (parsedData['sampleDate'] != null) {
          _sampleDate = parsedData['sampleDate'] as DateTime;
        }
        if (parsedData['serumTypes'] != null) {
          final serumList = parsedData['serumTypes'] as List<Map<String, String>>;
          _serumTypes.clear();
          for (var serum in serumList) {
            _serumTypes.add(SerumType(type: serum['type'] ?? '', value: serum['value'] ?? ''));
          }
        }
      });

      // Kameradan okunan verilerle otomatik kaydet
      if (mounted && _birthDate != null && _serumTypes.isNotEmpty && _fullNameController.text.trim().isNotEmpty) {
        // Minimum gerekli alanlar dolu, otomatik kaydet
        final reportDate = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

        final tahlilData = {
          'fullName': _fullNameController.text.trim(),
          'tcNumber': _tcController.text.trim(),
          'birthDate': _birthDate,
          'age': _age,
          'gender': _gender,
          'patientType': _patientType,
          'sampleType': _sampleTypeController.text.trim(),
          'sampleDate': _sampleDate,
          'serumTypes': _serumTypes.map((s) => s.toMap()).toList(),
          'reportDate': reportDate,
        };

        final success = await FirebaseService.addTahlil(tahlilData);

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fotoğraf okundu ve tahlil otomatik olarak kaydedildi!'),
                backgroundColor: Colors.green,
              ),
            );
            _resetForm();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Fotoğraf okundu ancak tahlil kaydedilirken bir hata oluştu. Lütfen manuel olarak kaydedin.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fotoğraf başarıyla okundu ve form dolduruldu! Lütfen eksik bilgileri tamamlayıp kaydedin.'),
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

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _age = _calculateAgeInYears(picked);
      });
    }
  }

  void _addSerumValue() {
    if (_selectedSerumType.isEmpty || _serumValueController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen serum tipi ve değeri girin!')));
      return;
    }

    setState(() {
      _serumTypes.add(SerumType(type: _selectedSerumType, value: _serumValueController.text));
      _selectedSerumType = '';
      _serumValueController.clear();
    });
  }

  Future<void> _saveTahlil() async {
    if (!_formKey.currentState!.validate()) return;

    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen doğum tarihini seçin!')));
      return;
    }

    if (_serumTypes.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lütfen en az bir serum değeri ekleyin!')));
      return;
    }

    // Rapor tarihi - şimdiki zamanı kullan (kameradan okunsa bile form kaydedilirken güncel tarih kullanılır)
    final reportDate = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    final tahlilData = {
      'fullName': _fullNameController.text.trim(),
      'tcNumber': _tcController.text.trim(),
      'birthDate': _birthDate,
      'age': _age,
      'gender': _gender,
      'patientType': _patientType,
      'sampleType': _sampleTypeController.text.trim(),
      'sampleDate': _sampleDate,
      'serumTypes': _serumTypes.map((s) => s.toMap()).toList(),
      'reportDate': reportDate,
    };

    final success = await FirebaseService.addTahlil(tahlilData);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tahlil başarıyla kaydedildi!')));
      _resetForm();
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tahlil kaydedilirken bir hata oluştu!')));
    }
  }

  void _resetForm() {
    _fullNameController.clear();
    _tcController.clear();
    _sampleTypeController.clear();
    _serumValueController.clear();
    setState(() {
      _birthDate = null;
      _sampleDate = null;
      _age = 0;
      _gender = '';
      _patientType = '';
      _selectedSerumType = '';
      _serumTypes.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Scaffold(
      appBar: AppBar(
        title: isMobile
            ? const Align(alignment: Alignment.centerLeft, child: Text('Tahlil Ekle'))
            : const Text('Tahlil Ekle'),
        automaticallyImplyLeading: false, // Geri butonunu gizle
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
      endDrawer: isMobile ? _buildAdminDrawer(context, isMobile) : null,
      body: Row(
        children: [
          if (!isMobile) _buildNavigationRail(context),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kamera ile Okutma Butonu - Modern tasarım
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF0058A3).withValues(alpha: 0.1),
                            const Color(0xFF00A8E8).withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF0058A3).withValues(alpha: 0.2)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Color(0xFF0058A3), Color(0xFF00A8E8)]),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 24),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Kamera ile Otomatik Doldur',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0058A3),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Kameradan çekerek veya galeriden seçerek tahlil belgesini okutabilirsiniz. Web\'de galeri seçeneği daha güvenilir çalışır.',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            Row(
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
                                    child: ElevatedButton.icon(
                                      onPressed: _isLoadingPdf ? null : _scanTahlilFromCamera,
                                      icon: _isLoadingPdf
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : const Icon(Icons.camera_alt),
                                      label: Text(_isLoadingPdf ? 'İşleniyor...' : 'Kamera'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
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
                                    child: ElevatedButton.icon(
                                      onPressed: _isLoadingPdf ? null : _scanTahlilFromGallery,
                                      icon: _isLoadingPdf
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : const Icon(Icons.photo_library),
                                      label: Text(_isLoadingPdf ? 'İşleniyor...' : 'Galeri'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF0058A3), Color(0xFF00A8E8)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Hasta Bilgileri',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(labelText: 'Adı Soyadı', prefixIcon: Icon(Icons.person)),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Adı soyadı giriniz';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _tcController,
                      decoration: const InputDecoration(labelText: 'T.C. Kimlik No', prefixIcon: Icon(Icons.badge)),
                      keyboardType: TextInputType.number,
                      maxLength: 11,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'TC kimlik numarası giriniz';
                        }
                        if (value.length != 11) {
                          return 'TC kimlik numarası 11 haneli olmalıdır';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Doğum Tarihi',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _birthDate != null ? DateFormat('dd/MM/yyyy').format(_birthDate!) : 'Doğum Tarihi Seçin',
                        ),
                      ),
                    ),
                    Text('Yaş (Yıl): $_age'),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _sampleDate ?? DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _sampleDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Numune Alım Tarihi',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _sampleDate != null
                              ? DateFormat('dd/MM/yyyy').format(_sampleDate!)
                              : 'Numune Alım Tarihi Seçin (Opsiyonel)',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _gender.isEmpty ? null : _gender,
                      decoration: const InputDecoration(labelText: 'Cinsiyet', prefixIcon: Icon(Icons.wc)),
                      items: const [
                        DropdownMenuItem(value: 'Erkek', child: Text('Erkek')),
                        DropdownMenuItem(value: 'Kadın', child: Text('Kadın')),
                      ],
                      onChanged: (value) => setState(() => _gender = value ?? ''),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _patientType,
                      decoration: const InputDecoration(
                        labelText: 'Hastalık Tanısı',
                        prefixIcon: Icon(Icons.local_hospital),
                        hintText: 'Hastalık tanısını girin',
                      ),
                      onChanged: (value) => setState(() => _patientType = value),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _sampleTypeController,
                      decoration: const InputDecoration(labelText: 'Numune Türü', prefixIcon: Icon(Icons.science)),
                    ),
                    const SizedBox(height: 24),
                    const Text('Tetkik Adı (mg/dl)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSerumType.isEmpty ? null : _selectedSerumType,
                      decoration: const InputDecoration(labelText: 'Serum Tipi Seçin'),
                      items: _serumTypeOptions.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedSerumType = value ?? ''),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _serumValueController,
                      decoration: const InputDecoration(labelText: 'Serum Değeri'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(onPressed: _addSerumValue, child: const Text('Serum Değeri Ekle')),
                    if (_serumTypes.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text('Eklenen Serum Değerleri:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ..._serumTypes.map(
                        (serum) => Card(
                          child: ListTile(
                            title: Text('${serum.type}: ${serum.value}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                setState(() {
                                  _serumTypes.remove(serum);
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveTahlil,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('Kaydet'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isMobile
          ? AdminBottomNavBar(
              currentIndex: 3,
              onTap: (index) {
                switch (index) {
                  case 0:
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const KilavuzScreen()));
                    break;
                  case 1:
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const KilavuzListScreen()),
                    );
                    break;
                  case 2:
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                    );
                    break;
                  case 3:
                    // Zaten bu sayfadayız
                    break;
                  case 4:
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const TahlilListScreen()),
                    );
                    break;
                }
              },
            )
          : null,
    );
  }

  Widget _buildNavigationRail(BuildContext context) {
    return NavigationRail(
      selectedIndex: _selectedNavIndex,
      labelType: NavigationRailLabelType.all,
      selectedIconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
      selectedLabelTextStyle: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
      unselectedIconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
      unselectedLabelTextStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
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
        NavigationRailDestination(icon: Icon(Icons.add), selectedIcon: Icon(Icons.add), label: Text('Tahlil Ekle')),
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
          case 0:
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminDashboardScreen()));
            break;
          case 1:
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const KilavuzScreen()));
            break;
          case 2:
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const KilavuzListScreen()));
            break;
          case 3:
            // Zaten bu sayfadayız
            break;
          case 4:
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TahlilListScreen()));
            break;
          case 5:
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminProfileScreen()));
            break;
        }
      },
    );
  }

  Widget _buildAdminDrawer(BuildContext context, bool isMobile) {
    return Drawer(
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
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminDashboardScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_circle),
            title: const Text('Kılavuz Oluştur'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const KilavuzScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.list),
            title: const Text('Kılavuz Listesi'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const KilavuzListScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Tahlil Ekle'),
            selected: true,
            selectedTileColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('Tahlil Listesi'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TahlilListScreen()));
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
    );
  }
}
