import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../services/firebase_service.dart';
import '../../widgets/admin_bottom_nav_bar.dart';
import '../../providers/theme_provider.dart';
import 'admin_dashboard_screen.dart';
import 'admin_profile_screen.dart';
import 'kilavuz_list_screen.dart';
import 'tahlil_ekle_screen.dart';
import 'tahlil_list_screen.dart';

class KilavuzScreen extends StatefulWidget {
  final String? guideNameToEdit; // Düzenlenecek kılavuz adı
  final Map<String, dynamic>? guideDataToEdit; // Düzenlenecek kılavuz verisi

  const KilavuzScreen({super.key, this.guideNameToEdit, this.guideDataToEdit});

  @override
  State<KilavuzScreen> createState() => _KilavuzScreenState();
}

class _KilavuzScreenState extends State<KilavuzScreen> {
  final _guideNameController = TextEditingController();
  final List<Map<String, dynamic>> _rows = [];
  String? _savedGuideName; // Kaydedilen başlık
  bool _isLoading = true;
  bool _isButtonHovered = false; // Buton hover durumu
  int _selectedNavIndex = 1; // NavigationRail için seçili index

  // Yeni yapı için değişkenler
  String _selectedAgeUnit = 'yıl'; // 'ay' veya 'yıl'
  String _selectedAgeRange = ''; // Seçilen yaş aralığı
  String? _selectedGender; // 'Erkek', 'Kadın' veya null (her ikisi için)
  final Map<String, Map<String, String>> _serumValues =
      {}; // serumType -> {min, max}
  final Map<String, TextEditingController> _serumMinControllers = {};
  final Map<String, TextEditingController> _serumMaxControllers = {};

  // Yaş aralığı için controller'lar
  final _ageRangeStartController = TextEditingController();
  final _ageRangeEndController = TextEditingController();

  final List<String> _serumTypes = [
    'IgG',
    'IgG1',
    'IgG2',
    'IgG3',
    'IgG4',
    'IgA',
    'IgA1',
    'IgA2',
    'IgM',
  ];

  // Yeni serum ekleme için controller'lar
  final _newSerumTypeController = TextEditingController();
  final _newSerumMinController = TextEditingController();
  final _newSerumMaxController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Serum controller'larını başlat
    for (var type in _serumTypes) {
      _serumMinControllers[type] = TextEditingController();
      _serumMaxControllers[type] = TextEditingController();
    }
    // Widget tree tam oluştuktan sonra yükleme işlemlerini yap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isEditMode) {
        _loadGuideForEdit();
      } else {
        _loadSavedGuideName();
      }
    });
  }

  @override
  void dispose() {
    _guideNameController.dispose();
    _ageRangeStartController.dispose();
    _ageRangeEndController.dispose();
    _newSerumTypeController.dispose();
    _newSerumMinController.dispose();
    _newSerumMaxController.dispose();
    for (var controller in _serumMinControllers.values) {
      controller.dispose();
    }
    for (var controller in _serumMaxControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // Yaş aralığını güncelle
  void _updateAgeRange() {
    final start = _ageRangeStartController.text.trim();
    if (start.isEmpty) {
      setState(() {
        _selectedAgeRange = '';
      });
      return;
    }

    String range = '';
    final end = _ageRangeEndController.text.trim();
    if (end.isNotEmpty) {
      range = '$start-$end $_selectedAgeUnit';
    } else {
      range = '$start $_selectedAgeUnit';
    }

    setState(() {
      _selectedAgeRange = range;
    });
  }

  // Önceden tanımlı yaş aralıklarını göster
  Future<void> _showPredefinedAgeRangePicker() async {
    final List<Map<String, String>> predefinedRanges = _selectedAgeUnit == 'ay'
        ? [
            {'start': '0', 'end': '3', 'label': '0-3 Ay'},
            {'start': '3', 'end': '6', 'label': '3-6 Ay'},
            {'start': '6', 'end': '12', 'label': '6-12 Ay'},
            {'start': '12', 'end': '24', 'label': '12-24 Ay'},
            {'start': '24', 'end': '36', 'label': '24-36 Ay'},
            {'start': '36', 'end': '48', 'label': '36-48 Ay'},
            {'start': '48', 'end': '60', 'label': '48-60 Ay'},
          ]
        : [
            {'start': '0', 'end': '1', 'label': '0-1 Yıl'},
            {'start': '1', 'end': '2', 'label': '1-2 Yıl'},
            {'start': '2', 'end': '5', 'label': '2-5 Yıl'},
            {'start': '5', 'end': '10', 'label': '5-10 Yıl'},
            {'start': '10', 'end': '15', 'label': '10-15 Yıl'},
            {'start': '15', 'end': '18', 'label': '15-18 Yıl'},
            {'start': '18', 'end': '25', 'label': '18-25 Yıl'},
            {'start': '25', 'end': '35', 'label': '25-35 Yıl'},
            {'start': '35', 'end': '50', 'label': '35-50 Yıl'},
            {'start': '50', 'end': '65', 'label': '50-65 Yıl'},
            {'start': '65', 'end': '', 'label': '65+ Yıl'},
          ];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Yaş Aralığı Seç (${_selectedAgeUnit == 'ay' ? 'Ay' : 'Yıl'})',
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: predefinedRanges.length,
            itemBuilder: (context, index) {
              final range = predefinedRanges[index];
              return ListTile(
                title: Text(range['label']!),
                onTap: () {
                  setState(() {
                    _ageRangeStartController.text = range['start']!;
                    _ageRangeEndController.text = range['end'] ?? '';
                    _updateAgeRange();
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  bool get _isEditMode =>
      widget.guideNameToEdit != null || widget.guideDataToEdit != null;

  // Düzenleme modu için kılavuz verilerini yükle
  Future<void> _loadGuideForEdit() async {
    setState(() => _isLoading = true);
    try {
      Map<String, dynamic>? guideData;

      if (widget.guideDataToEdit != null) {
        guideData = widget.guideDataToEdit;
      } else if (widget.guideNameToEdit != null) {
        guideData = await FirebaseService.getGuide(widget.guideNameToEdit!);
      }

      if (guideData != null && mounted) {
        final guideName = guideData['name'] as String? ?? '';
        final rows = guideData['rows'] as List<dynamic>? ?? [];

        setState(() {
          _guideNameController.text = guideName;
          _savedGuideName = guideName;

          // Satırları yükle
          _rows.clear();
          _serumValues.clear();
          String? firstAgeRange;

          for (var i = 0; i < rows.length; i++) {
            final row = rows[i] as Map<String, dynamic>;
            final ageRange = row['ageRange']?.toString() ?? '';
            final serumType = row['serumType']?.toString() ?? '';

            // İlk yaş aralığını genel yaş aralığı olarak kaydet
            if (firstAgeRange == null && ageRange.isNotEmpty) {
              firstAgeRange = ageRange;
              _selectedAgeRange = ageRange;
              if (ageRange.contains('ay')) {
                _selectedAgeUnit = 'ay';
              } else if (ageRange.contains('yıl')) {
                _selectedAgeUnit = 'yıl';
              }

              // Yaş aralığını parse et ve controller'lara yükle
              if (ageRange.contains('+')) {
                final minAgeStr = ageRange
                    .replaceAll('+', '')
                    .trim()
                    .replaceAll(RegExp(r'[^0-9]'), '');
                _ageRangeStartController.text = minAgeStr;
                _ageRangeEndController.clear();
              } else if (ageRange.contains('-')) {
                final parts = ageRange.split('-');
                if (parts.length == 2) {
                  final startStr = parts[0].trim().replaceAll(
                    RegExp(r'[^0-9]'),
                    '',
                  );
                  final endStr = parts[1]
                      .trim()
                      .split(' ')
                      .first
                      .replaceAll(RegExp(r'[^0-9]'), '');
                  _ageRangeStartController.text = startStr;
                  _ageRangeEndController.text = endStr;
                }
              }
            }

            // Aynı yaş aralığındaki serum değerlerini topla
            if (ageRange == firstAgeRange && serumType.isNotEmpty) {
              final minValue = row['min']?.toString() ?? '';
              final maxValue = row['max']?.toString() ?? '';
              _serumValues[serumType] = {'min': minValue, 'max': maxValue};
              // Controller'ları güncelle
              if (_serumMinControllers.containsKey(serumType)) {
                _serumMinControllers[serumType]!.text = minValue;
              }
              if (_serumMaxControllers.containsKey(serumType)) {
                _serumMaxControllers[serumType]!.text = maxValue;
              }
            }

            // Veritabanından gelen değerleri formata çevir (geriye dönük uyumluluk için)
            final geoMeanMin = row['geoMeanMin'] ?? 0;
            final geoMeanMax = row['geoMeanMax'] ?? 0;
            final geoMean = (geoMeanMin + geoMeanMax) / 2;
            final gSD = (geoMeanMax - geoMean) / 2;

            final meanMin = row['meanMin'] ?? 0;
            final meanMax = row['meanMax'] ?? 0;
            final mean = (meanMin + meanMax) / 2;
            final mSD = (meanMax - mean) / 2;

            final arithMeanMin = row['arithMeanMin'] ?? 0;
            final arithMeanMax = row['arithMeanMax'] ?? 0;
            final arithMean = (arithMeanMin + arithMeanMax) / 2;
            final arithSD = (arithMeanMax - arithMean) / 2;

            _rows.add({
              'id': i + 1,
              'ageRange': ageRange,
              'geoMean': geoMean.toString(),
              'gSD': gSD.toString(),
              'mean': mean.toString(),
              'mSD': mSD.toString(),
              'min': row['min']?.toString() ?? '',
              'max': row['max']?.toString() ?? '',
              'intervalMin': row['intervalMin']?.toString() ?? '',
              'intervalMax': row['intervalMax']?.toString() ?? '',
              'serumType': serumType,
              'arithMean': arithMean.toString(),
              'arithSD': arithSD.toString(),
            });
          }
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kılavuz yüklenirken bir hata oluştu!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Kaydedilmiş başlığı yükle
  Future<void> _loadSavedGuideName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString('last_saved_guide_name');
      if (savedName != null && savedName.isNotEmpty) {
        setState(() {
          _savedGuideName = savedName;
          _guideNameController.text = savedName;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Başlığı kalıcı olarak kaydet
  Future<void> _saveGuideNameToPrefs(String guideName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_saved_guide_name', guideName);
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  // Başlığı temizle
  Future<void> _clearSavedGuideName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_saved_guide_name');
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  void _addRow() {
    setState(() {
      _rows.add({
        'id': _rows.length + 1,
        'ageRange': '',
        'geoMean': '',
        'gSD': '',
        'mean': '',
        'mSD': '',
        'min': '',
        'max': '',
        'intervalMin': '',
        'intervalMax': '',
        'serumType': '',
        'arithMean': '',
        'arithSD': '',
      });
    });
  }

  void _deleteRow(int id) {
    setState(() {
      _rows.removeWhere((row) => row['id'] == id);
    });
  }

  void _updateRow(int index, String field, dynamic value) {
    setState(() {
      _rows[index][field] = value;
    });
  }

  // Yeni serum tipi ekle
  void _addNewSerumType() {
    final serumType = _newSerumTypeController.text.trim();
    if (serumType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen serum tipi adı girin!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_serumTypes.contains(serumType)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$serumType zaten mevcut!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final minValue = _newSerumMinController.text.trim();
    final maxValue = _newSerumMaxController.text.trim();

    if (minValue.isEmpty && maxValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen en az bir değer (Min veya Max) girin!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      // Yeni serum tipini listeye ekle
      _serumTypes.add(serumType);

      // Controller'ları oluştur
      _serumMinControllers[serumType] = TextEditingController(text: minValue);
      _serumMaxControllers[serumType] = TextEditingController(text: maxValue);

      // Değerleri kaydet
      _serumValues[serumType] = {'min': minValue, 'max': maxValue};

      // Form alanlarını temizle
      _newSerumTypeController.clear();
      _newSerumMinController.clear();
      _newSerumMaxController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$serumType başarıyla eklendi!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  double _formatNumber(double num, int precision) {
    final factor = 1 / (10 * precision);
    return (num * (1 / factor)).round() / (1 / factor);
  }

  // Güvenli sayı dönüştürme fonksiyonu
  double _safeParseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    if (value is num) {
      return value.toDouble();
    }
    return 0.0;
  }

  Future<void> _saveGuide() async {
    if (_guideNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir kılavuz adı girin!')),
      );
      return;
    }

    // Yeni yapı: Yaş aralığı ve serum değerlerinden satırlar oluştur
    if (_selectedAgeRange.isNotEmpty && _serumValues.isNotEmpty) {
      _rows.clear();
      for (var serumType in _serumTypes) {
        final values = _serumValues[serumType];
        if (values != null &&
            (values['min']?.isNotEmpty == true ||
                values['max']?.isNotEmpty == true)) {
          _rows.add({
            'id': _rows.length + 1,
            'ageRange': _selectedAgeRange,
            'serumType': serumType,
            'min': values['min'] ?? '',
            'max': values['max'] ?? '',
            'geoMean': '',
            'gSD': '',
            'mean': '',
            'mSD': '',
            'intervalMin': '',
            'intervalMax': '',
            'arithMean': '',
            'arithSD': '',
          });
        }
      }
    }

    if (_rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lütfen yaş aralığı seçin ve en az bir serum değeri girin!',
          ),
        ),
      );
      return;
    }

    final formattedRows = _rows.map((row) {
      final geoMean = _safeParseDouble(row['geoMean']);
      final gSD = _safeParseDouble(row['gSD']);
      final mean = _safeParseDouble(row['mean']);
      final mSD = _safeParseDouble(row['mSD']);
      final arithMean = _safeParseDouble(row['arithMean']);
      final arithSD = _safeParseDouble(row['arithSD']);

      return {
        'ageRange': row['ageRange']?.toString() ?? '',
        'geoMeanMin': _formatNumber(geoMean - gSD, 2),
        'geoMeanMax': _formatNumber(geoMean + gSD, 2),
        'meanMin': _formatNumber(mean - mSD, 2),
        'meanMax': _formatNumber(mean + mSD, 2),
        'min': _formatNumber(_safeParseDouble(row['min']), 2),
        'max': _formatNumber(_safeParseDouble(row['max']), 2),
        'intervalMin': _formatNumber(_safeParseDouble(row['intervalMin']), 2),
        'intervalMax': _formatNumber(_safeParseDouble(row['intervalMax']), 2),
        'serumType': row['serumType']?.toString() ?? '',
        'arithMeanMin': _formatNumber(arithMean - arithSD, 2),
        'arithMeanMax': _formatNumber(arithMean + arithSD, 2),
      };
    }).toList();

    // Kılavuz adına cinsiyet bilgisini ekle (opsiyonel)
    String guideName = _guideNameController.text.trim();
    if (_selectedGender != null) {
      guideName = '$guideName - $_selectedGender';
    }
    bool success;

    if (_isEditMode) {
      // Düzenleme modu
      final originalName =
          widget.guideNameToEdit ??
          widget.guideDataToEdit?['name'] as String? ??
          '';
      final newName = guideName != originalName ? guideName : null;

      success = await FirebaseService.updateGuide(
        originalName,
        formattedRows,
        newGuideName: newName,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kılavuz başarıyla güncellendi!'),
            backgroundColor: Colors.green,
          ),
        );
        // Kılavuz listesine yönlendir
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const KilavuzListScreen(),
              ),
            );
          }
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kılavuz güncellenirken bir hata oluştu!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Yeni kılavuz oluşturma modu
      success = await FirebaseService.addGuide(guideName, formattedRows);

      if (success && mounted) {
        // Başlığı kalıcı olarak kaydet
        await _saveGuideNameToPrefs(guideName);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kılavuz başarıyla oluşturuldu!'),
            backgroundColor: Colors.green,
          ),
        );
        // Başlık kayıtlı kalacak, sadece satırlar temizlenecek
        setState(() {
          _savedGuideName = guideName;
          _rows.clear();
        });
        // Kılavuz listesine yönlendir
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const KilavuzListScreen(),
              ),
            );
          }
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kılavuz oluşturulurken bir hata oluştu!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Modern yaş aralığı seçici dialog
  Future<void> _showAgeRangePicker(BuildContext context, int rowIndex) async {
    String? ageUnit = _selectedAgeUnit; // ay veya yıl
    int? minAge;
    int? maxAge;
    bool isPlus = false;

    // Mevcut değeri parse et
    final currentValue = rowIndex == -1
        ? _selectedAgeRange
        : (_rows.isNotEmpty && rowIndex >= 0 && rowIndex < _rows.length
              ? _rows[rowIndex]['ageRange']?.toString() ?? ''
              : '');

    if (currentValue.isNotEmpty) {
      if (currentValue.contains('+')) {
        isPlus = true;
        minAge = int.tryParse(
          currentValue
              .replaceAll('+', '')
              .trim()
              .replaceAll(RegExp(r'[^0-9]'), ''),
        );
      } else if (currentValue.contains('-')) {
        final parts = currentValue.split('-');
        if (parts.length == 2) {
          minAge = int.tryParse(
            parts[0].trim().replaceAll(RegExp(r'[^0-9]'), ''),
          );
          maxAge = int.tryParse(
            parts[1].trim().split(' ').first.replaceAll(RegExp(r'[^0-9]'), ''),
          );
          if (parts[1].contains('ay'))
            ageUnit = 'ay';
          else if (parts[1].contains('yıl'))
            ageUnit = 'yıl';
        }
      }
    }

    // Genel seçim için mevcut birimi kullan
    if (rowIndex == -1) {
      ageUnit = _selectedAgeUnit;
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.calendar_today, color: Color(0xFF0058A3)),
              SizedBox(width: 8),
              Text('Yaş Aralığı Seç'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Yaş birimi seçimi
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0058A3).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Birim: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Ay'),
                        selected: ageUnit == 'ay',
                        onSelected: (selected) {
                          setDialogState(() => ageUnit = 'ay');
                        },
                        selectedColor: const Color(0xFF0058A3),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Yıl'),
                        selected: ageUnit == 'yıl',
                        onSelected: (selected) {
                          setDialogState(() => ageUnit = 'yıl');
                        },
                        selectedColor: const Color(0xFF0058A3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Aralık veya + seçimi
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('Aralık (örn: 0-6)'),
                        value: !isPlus,
                        onChanged: (value) {
                          setDialogState(() {
                            isPlus = false;
                            if (value == true) maxAge = null;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('Üstü (örn: 18+)'),
                        value: isPlus,
                        onChanged: (value) {
                          setDialogState(() {
                            isPlus = true;
                            maxAge = null;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Minimum yaş
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Başlangıç',
                    hintText: 'Örn: 0, 1, 18',
                    prefixIcon: const Icon(Icons.numbers),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(
                    text: minAge?.toString() ?? '',
                  ),
                  onChanged: (value) {
                    minAge = int.tryParse(value);
                  },
                ),
                if (!isPlus) ...[
                  const SizedBox(height: 16),
                  // Maximum yaş
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Bitiş',
                      hintText: 'Örn: 6, 12, 18',
                      prefixIcon: const Icon(Icons.numbers),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(
                      text: maxAge?.toString() ?? '',
                    ),
                    onChanged: (value) {
                      maxAge = int.tryParse(value);
                    },
                  ),
                ],
                const SizedBox(height: 16),
                // Önizleme
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.preview, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        minAge != null
                            ? (isPlus
                                  ? 'Önizleme: $minAge+ $ageUnit'
                                  : maxAge != null
                                  ? 'Önizleme: $minAge-$maxAge $ageUnit'
                                  : 'Önizleme: $minAge $ageUnit')
                            : 'Önizleme:',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                String result = '';
                if (minAge != null) {
                  if (isPlus) {
                    result = '$minAge+ $ageUnit';
                  } else if (maxAge != null) {
                    result = '$minAge-$maxAge $ageUnit';
                  } else {
                    result = '$minAge $ageUnit';
                  }
                }
                _updateRow(rowIndex, 'ageRange', result);
                setState(() {
                  if (rowIndex == -1) {
                    // Genel yaş aralığı seçimi
                    _selectedAgeRange = result;
                    _selectedAgeUnit = ageUnit ?? 'yıl';
                  } else {
                    // Satır bazlı yaş aralığı seçimi
                    _updateRow(rowIndex, 'ageRange', result);
                  }
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0058A3),
                foregroundColor: Colors.white,
              ),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    final isTablet = ResponsiveBreakpoints.of(context).isTablet;
    final serumTypes = [
      'IgG',
      'IgG1',
      'IgG2',
      'IgG3',
      'IgG4',
      'IgA',
      'IgA1',
      'IgA2',
      'IgM',
    ];

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: isMobile
            ? Align(
                alignment: Alignment.centerLeft,
                child: Text(_isEditMode ? 'Kılavuz Düzenle' : 'Kılavuz Oluştur'),
              )
            : Text(_isEditMode ? 'Kılavuz Düzenle' : 'Kılavuz Oluştur'),
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.all(
                    isMobile
                        ? 12
                        : isTablet
                        ? 20
                        : 24,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isMobile ? double.infinity : 1200,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Kılavuz Bilgileri Başlığı
                          Container(
                            padding: EdgeInsets.all(isMobile ? 16 : 20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(
                                    0xFF0058A3,
                                  ).withValues(alpha: 0.1),
                                  const Color(
                                    0xFF00A8E8,
                                  ).withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(
                                  0xFF0058A3,
                                ).withValues(alpha: 0.2),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF0058A3),
                                        Color(0xFF00A8E8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.book,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Kılavuz Bilgileri',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0058A3),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.info_outline,
                                    color: Color(0xFF0058A3),
                                  ),
                                  tooltip: 'Kılavuz Oluşturma Adımları',
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              color: Color(0xFF0058A3),
                                            ),
                                            SizedBox(width: 8),
                                            Text('Kılavuz Oluşturma Adımları'),
                                          ],
                                        ),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildStepItem(
                                              '1',
                                              'Kılavuz başlığını girin',
                                            ),
                                            const SizedBox(height: 12),
                                            _buildStepItem(
                                              '2',
                                              'Her yaş aralığı için satır ekleyin',
                                            ),
                                            const SizedBox(height: 12),
                                            _buildStepItem(
                                              '3',
                                              'Serum tipi ve yaş aralığını belirleyin',
                                            ),
                                            const SizedBox(height: 12),
                                            _buildStepItem(
                                              '4',
                                              'Normal Alt/Üst Sınır değerlerini girin',
                                            ),
                                            const SizedBox(height: 12),
                                            _buildStepItem(
                                              '5',
                                              'Kılavuzu kaydedin',
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Tamam'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Kılavuz Başlığı (Container dışında)
                          if (_savedGuideName != null &&
                              _savedGuideName ==
                                  _guideNameController.text.trim())
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Bu başlık kaydedildi. Aynı başlıkta yeni satırlar ekleyebilirsiniz.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green[800],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          TextField(
                            controller: _guideNameController,
                            decoration: InputDecoration(
                              labelText: 'Kılavuz Adı *',
                              hintText:
                                  'Örn: Çocuk İmmünglobulin Referans Aralıkları',
                              helperText:
                                  'Kılavuzun amacını ve içeriğini belirten bir başlık girin',
                              prefixIcon: const Icon(Icons.title),
                              suffixIcon:
                                  _savedGuideName != null &&
                                      _savedGuideName ==
                                          _guideNameController.text.trim()
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.clear,
                                        color: Colors.grey,
                                      ),
                                      tooltip: 'Kaydedilmiş başlığı temizle',
                                      onPressed: () {
                                        setState(() {
                                          _guideNameController.clear();
                                          _savedGuideName = null;
                                        });
                                        _clearSavedGuideName();
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color:
                                      _savedGuideName != null &&
                                          _savedGuideName ==
                                              _guideNameController.text.trim()
                                      ? Colors.green
                                      : Colors.grey[300]!,
                                  width: 2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF0058A3),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Yaş/Ay Seçimi
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF0058A3,
                              ).withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(
                                  0xFF0058A3,
                                ).withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Yaş Aralığı',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0058A3),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Birim seçimi ve yaş aralığı input alanları
                                isMobile
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Birim seçimi
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF0058A3,
                                              ).withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                const Text(
                                                  'Birim: ',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                ChoiceChip(
                                                  label: const Text('Ay'),
                                                  selected:
                                                      _selectedAgeUnit == 'ay',
                                                  onSelected: (selected) {
                                                    setState(() {
                                                      _selectedAgeUnit = 'ay';
                                                      _selectedAgeRange = '';
                                                      _ageRangeStartController
                                                          .clear();
                                                      _ageRangeEndController
                                                          .clear();
                                                    });
                                                    _updateAgeRange();
                                                  },
                                                  selectedColor: const Color(
                                                    0xFF0058A3,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                ChoiceChip(
                                                  label: const Text('Yıl'),
                                                  selected:
                                                      _selectedAgeUnit == 'yıl',
                                                  onSelected: (selected) {
                                                    setState(() {
                                                      _selectedAgeUnit = 'yıl';
                                                      _selectedAgeRange = '';
                                                      _ageRangeStartController
                                                          .clear();
                                                      _ageRangeEndController
                                                          .clear();
                                                    });
                                                    _updateAgeRange();
                                                  },
                                                  selectedColor: const Color(
                                                    0xFF0058A3,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          // Başlangıç ve Bitiş input alanları
                                          Row(
                                            children: [
                                              Expanded(
                                                child: TextField(
                                                  controller:
                                                      _ageRangeStartController,
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText: 'Başlangıç',
                                                        hintText:
                                                            'Örn: 0, 1, 18',
                                                        border: OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.all(
                                                                Radius.circular(
                                                                  12,
                                                                ),
                                                              ),
                                                        ),
                                                      ),
                                                  keyboardType:
                                                      TextInputType.number,
                                                  onChanged: (value) {
                                                    _updateAgeRange();
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: TextField(
                                                  controller:
                                                      _ageRangeEndController,
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText: 'Bitiş',
                                                        hintText:
                                                            'Örn: 6, 12, 18',
                                                        border: OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.all(
                                                                Radius.circular(
                                                                  12,
                                                                ),
                                                              ),
                                                        ),
                                                      ),
                                                  keyboardType:
                                                      TextInputType.number,
                                                  onChanged: (value) {
                                                    _updateAgeRange();
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.arrow_drop_down,
                                                  color: Color(0xFF0058A3),
                                                ),
                                                onPressed:
                                                    _showPredefinedAgeRangePicker,
                                                tooltip: 'Yaş Aralığı Seç',
                                              ),
                                            ],
                                          ),
                                        ],
                                      )
                                    : Row(
                                        children: [
                                          // Birim seçimi
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF0058A3,
                                              ).withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                const Text(
                                                  'Birim: ',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                ChoiceChip(
                                                  label: const Text('Ay'),
                                                  selected:
                                                      _selectedAgeUnit == 'ay',
                                                  onSelected: (selected) {
                                                    setState(() {
                                                      _selectedAgeUnit = 'ay';
                                                      _selectedAgeRange = '';
                                                      _ageRangeStartController
                                                          .clear();
                                                      _ageRangeEndController
                                                          .clear();
                                                    });
                                                    _updateAgeRange();
                                                  },
                                                  selectedColor: const Color(
                                                    0xFF0058A3,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                ChoiceChip(
                                                  label: const Text('Yıl'),
                                                  selected:
                                                      _selectedAgeUnit == 'yıl',
                                                  onSelected: (selected) {
                                                    setState(() {
                                                      _selectedAgeUnit = 'yıl';
                                                      _selectedAgeRange = '';
                                                      _ageRangeStartController
                                                          .clear();
                                                      _ageRangeEndController
                                                          .clear();
                                                    });
                                                    _updateAgeRange();
                                                  },
                                                  selectedColor: const Color(
                                                    0xFF0058A3,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          // Başlangıç ve Bitiş input alanları
                                          Expanded(
                                            child: TextField(
                                              controller:
                                                  _ageRangeStartController,
                                              decoration: const InputDecoration(
                                                labelText: 'Başlangıç',
                                                hintText: 'Örn: 0, 1, 18',
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                        Radius.circular(12),
                                                      ),
                                                ),
                                              ),
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged: (value) {
                                                _updateAgeRange();
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: TextField(
                                              controller:
                                                  _ageRangeEndController,
                                              decoration: const InputDecoration(
                                                labelText: 'Bitiş',
                                                hintText: 'Örn: 6, 12, 18',
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                        Radius.circular(12),
                                                      ),
                                                ),
                                              ),
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged: (value) {
                                                _updateAgeRange();
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.arrow_drop_down,
                                              color: Color(0xFF0058A3),
                                            ),
                                            onPressed:
                                                _showPredefinedAgeRangePicker,
                                            tooltip: 'Yaş Aralığı Seç',
                                          ),
                                        ],
                                      ),
                                if (_selectedAgeRange.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.blue.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.preview,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Önizleme: $_selectedAgeRange',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Serum Değerleri Başlığı
                          const Text(
                            'Serum Değerleri - Referans Aralıkları',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0058A3),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Her serum tipi için minimum ve maksimum referans değerlerini girebilirsiniz. Boş bırakılabilir.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Serum tipleri için input alanları
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: _serumTypes.map((serumType) {
                              // Controller'ları kullan veya oluştur
                              if (!_serumMinControllers.containsKey(
                                serumType,
                              )) {
                                _serumMinControllers[serumType] =
                                    TextEditingController(
                                      text:
                                          _serumValues[serumType]?['min'] ?? '',
                                    );
                              }
                              if (!_serumMaxControllers.containsKey(
                                serumType,
                              )) {
                                _serumMaxControllers[serumType] =
                                    TextEditingController(
                                      text:
                                          _serumValues[serumType]?['max'] ?? '',
                                    );
                              }

                              final minController =
                                  _serumMinControllers[serumType]!;
                              final maxController =
                                  _serumMaxControllers[serumType]!;

                              return Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Container(
                                  width: isMobile ? double.infinity : 280,
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF0058A3,
                                              ).withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.science,
                                              color: Color(0xFF0058A3),
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              serumType,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF0058A3),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: minController,
                                              decoration: const InputDecoration(
                                                labelText: 'Min',
                                                hintText: 'Min değer',
                                                border: OutlineInputBorder(),
                                                isDense: true,
                                              ),
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged: (value) {
                                                if (!_serumValues.containsKey(
                                                  serumType,
                                                )) {
                                                  _serumValues[serumType] = {};
                                                }
                                                _serumValues[serumType]!['min'] =
                                                    value;
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: TextField(
                                              controller: maxController,
                                              decoration: const InputDecoration(
                                                labelText: 'Max',
                                                hintText: 'Max değer',
                                                border: OutlineInputBorder(),
                                                isDense: true,
                                              ),
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged: (value) {
                                                if (!_serumValues.containsKey(
                                                  serumType,
                                                )) {
                                                  _serumValues[serumType] = {};
                                                }
                                                _serumValues[serumType]!['max'] =
                                                    value;
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                          // Satırlar Başlığı (Eski yapı - geriye dönük uyumluluk için)
                          Text(
                            'Kılavuz Satırları',
                            style: TextStyle(
                              fontSize: isMobile ? 18 : 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0058A3),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Yeni Serum Ekleme Formu
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF0058A3,
                                ).withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(
                                    0xFF0058A3,
                                  ).withValues(alpha: 0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF0058A3,
                                          ).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.add_circle_outline,
                                          color: Color(0xFF0058A3),
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Text(
                                          'Yeni Serum Tipi Ekle',
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
                                  isMobile
                                      ? Column(
                                          children: [
                                            TextField(
                                              controller:
                                                  _newSerumTypeController,
                                              decoration: const InputDecoration(
                                                labelText: 'Serum Tipi Adı',
                                                hintText: 'Örn: IgG5, IgE',
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                        Radius.circular(12),
                                                      ),
                                                ),
                                                prefixIcon: Icon(Icons.science),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: TextField(
                                                    controller:
                                                        _newSerumMinController,
                                                    decoration: const InputDecoration(
                                                      labelText: 'Min',
                                                      hintText: 'Min değer',
                                                      border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                              Radius.circular(
                                                                12,
                                                              ),
                                                            ),
                                                      ),
                                                      isDense: true,
                                                    ),
                                                    keyboardType:
                                                        TextInputType.number,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: TextField(
                                                    controller:
                                                        _newSerumMaxController,
                                                    decoration: const InputDecoration(
                                                      labelText: 'Max',
                                                      hintText: 'Max değer',
                                                      border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                              Radius.circular(
                                                                12,
                                                              ),
                                                            ),
                                                      ),
                                                      isDense: true,
                                                    ),
                                                    keyboardType:
                                                        TextInputType.number,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton.icon(
                                                onPressed: _addNewSerumType,
                                                icon: const Icon(Icons.add),
                                                label: const Text(
                                                  'Serum Tipi Ekle',
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(
                                                    0xFF0058A3,
                                                  ),
                                                  foregroundColor: Colors.white,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 12,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: TextField(
                                                controller:
                                                    _newSerumTypeController,
                                                decoration:
                                                    const InputDecoration(
                                                      labelText:
                                                          'Serum Tipi Adı',
                                                      hintText:
                                                          'Örn: IgG5, IgE',
                                                      border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                              Radius.circular(
                                                                12,
                                                              ),
                                                            ),
                                                      ),
                                                      prefixIcon: Icon(
                                                        Icons.science,
                                                      ),
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: TextField(
                                                controller:
                                                    _newSerumMinController,
                                                decoration:
                                                    const InputDecoration(
                                                      labelText: 'Min',
                                                      hintText: 'Min değer',
                                                      border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                              Radius.circular(
                                                                12,
                                                              ),
                                                            ),
                                                      ),
                                                      isDense: true,
                                                    ),
                                                keyboardType:
                                                    TextInputType.number,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: TextField(
                                                controller:
                                                    _newSerumMaxController,
                                                decoration:
                                                    const InputDecoration(
                                                      labelText: 'Max',
                                                      hintText: 'Max değer',
                                                      border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                              Radius.circular(
                                                                12,
                                                              ),
                                                            ),
                                                      ),
                                                      isDense: true,
                                                    ),
                                                keyboardType:
                                                    TextInputType.number,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            ElevatedButton.icon(
                                              onPressed: _addNewSerumType,
                                              icon: const Icon(Icons.add),
                                              label: const Text('Ekle'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xFF0058A3,
                                                ),
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 12,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Satırlar Listesi
                          ..._rows.asMap().entries.map((entry) {
                            final index = entry.key;
                            final row = entry.value;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF0058A3,
                                    ).withValues(alpha: 0.2),
                                  ),
                                ),
                                child: ExpansionTile(
                                  initiallyExpanded:
                                      index < 3, // İlk 3 satır açık
                                  tilePadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 8,
                                  ),
                                  title: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF0058A3,
                                          ).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0058A3),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                if (row['serumType']
                                                        ?.toString()
                                                        .isNotEmpty ??
                                                    false)
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFF00A8E8,
                                                      ).withValues(alpha: 0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      row['serumType']
                                                          .toString(),
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                        color: Color(
                                                          0xFF0058A3,
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                else
                                                  const Text(
                                                    'Serum Tipi Seçin',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                if ((row['min']
                                                            ?.toString()
                                                            .isNotEmpty ??
                                                        false) &&
                                                    (row['max']
                                                            ?.toString()
                                                            .isNotEmpty ??
                                                        false))
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          left: 8,
                                                        ),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.green
                                                            .withValues(
                                                              alpha: 0.1,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        '${row['min']}-${row['max']}',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.green,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            if (row['ageRange']
                                                    ?.toString()
                                                    .isNotEmpty ??
                                                false) ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.calendar_today,
                                                    size: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Yaş: ${row['ageRange']}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Satırı Sil'),
                                              content: const Text(
                                                'Bu satırı silmek istediğinizden emin misiniz?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text('İptal'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    _deleteRow(row['id']);
                                                  },
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: Colors.red,
                                                  ),
                                                  child: const Text('Sil'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        tooltip: 'Satırı Sil',
                                      ),
                                    ],
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Temel Bilgiler
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  const Color(
                                                    0xFF0058A3,
                                                  ).withValues(alpha: 0.1),
                                                  const Color(
                                                    0xFF00A8E8,
                                                  ).withValues(alpha: 0.1),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.info_outline,
                                                      color: Color(0xFF0058A3),
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Text(
                                                      'Temel Bilgiler',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Color(
                                                          0xFF0058A3,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 16),
                                                LayoutBuilder(
                                                  builder: (context, constraints) {
                                                    final isNarrow =
                                                        constraints.maxWidth <
                                                        600;
                                                    return isNarrow
                                                        ? Column(
                                                            children: [
                                                              DropdownButtonFormField<
                                                                String
                                                              >(
                                                                decoration: InputDecoration(
                                                                  labelText:
                                                                      'Tahlil Değeri (Serum Tipi) *',
                                                                  hintText:
                                                                      'Seçin (IgG, IgA, IgM, vb.)',
                                                                  prefixIcon:
                                                                      const Icon(
                                                                        Icons
                                                                            .science,
                                                                      ),
                                                                  border: OutlineInputBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          12,
                                                                        ),
                                                                  ),
                                                                  filled: true,
                                                                  fillColor:
                                                                      Colors
                                                                          .white,
                                                                ),
                                                                value:
                                                                    row['serumType']
                                                                            ?.toString()
                                                                            .isEmpty ??
                                                                        true
                                                                    ? null
                                                                    : row['serumType'],
                                                                items: serumTypes.map((
                                                                  type,
                                                                ) {
                                                                  return DropdownMenuItem(
                                                                    value: type,
                                                                    child: Text(
                                                                      type,
                                                                    ),
                                                                  );
                                                                }).toList(),
                                                                onChanged:
                                                                    (
                                                                      value,
                                                                    ) => _updateRow(
                                                                      index,
                                                                      'serumType',
                                                                      value,
                                                                    ),
                                                              ),
                                                              const SizedBox(
                                                                height: 12,
                                                              ),
                                                              InkWell(
                                                                onTap: () =>
                                                                    _showAgeRangePicker(
                                                                      context,
                                                                      index,
                                                                    ),
                                                                child: Container(
                                                                  padding:
                                                                      const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            16,
                                                                        vertical:
                                                                            16,
                                                                      ),
                                                                  decoration: BoxDecoration(
                                                                    color: Colors
                                                                        .white,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          12,
                                                                        ),
                                                                    border: Border.all(
                                                                      color:
                                                                          row['ageRange']?.toString().isNotEmpty ??
                                                                              false
                                                                          ? const Color(
                                                                              0xFF0058A3,
                                                                            )
                                                                          : Colors.grey[300]!,
                                                                      width: 2,
                                                                    ),
                                                                  ),
                                                                  child: Row(
                                                                    children: [
                                                                      const Icon(
                                                                        Icons
                                                                            .calendar_today,
                                                                        color: Color(
                                                                          0xFF0058A3,
                                                                        ),
                                                                      ),
                                                                      const SizedBox(
                                                                        width:
                                                                            12,
                                                                      ),
                                                                      Expanded(
                                                                        child: Column(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.start,
                                                                          children: [
                                                                            Text(
                                                                              row['ageRange']?.toString().isNotEmpty ??
                                                                                      false
                                                                                  ? row['ageRange'].toString()
                                                                                  : 'Yaş Aralığı Seç *',
                                                                              style: TextStyle(
                                                                                fontSize: 16,
                                                                                color:
                                                                                    row['ageRange']?.toString().isNotEmpty ??
                                                                                        false
                                                                                    ? Colors.black87
                                                                                    : Colors.grey[600],
                                                                                fontWeight:
                                                                                    row['ageRange']?.toString().isNotEmpty ??
                                                                                        false
                                                                                    ? FontWeight.w500
                                                                                    : FontWeight.normal,
                                                                              ),
                                                                            ),
                                                                            if (row['ageRange']?.toString().isEmpty ??
                                                                                true)
                                                                              Text(
                                                                                'Örn: 0-6 ay, 1-3 yaş, 18+ yaş',
                                                                                style: TextStyle(
                                                                                  fontSize: 12,
                                                                                  color: Colors.grey[500],
                                                                                ),
                                                                              ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                      Icon(
                                                                        Icons
                                                                            .arrow_drop_down,
                                                                        color: Colors
                                                                            .grey[600],
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          )
                                                        : Row(
                                                            children: [
                                                              Expanded(
                                                                child: DropdownButtonFormField<String>(
                                                                  decoration: InputDecoration(
                                                                    labelText:
                                                                        'Tahlil Değeri (Serum Tipi) *',
                                                                    hintText:
                                                                        'Seçin (IgG, IgA, IgM, vb.)',
                                                                    prefixIcon:
                                                                        const Icon(
                                                                          Icons
                                                                              .science,
                                                                        ),
                                                                    border: OutlineInputBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            12,
                                                                          ),
                                                                    ),
                                                                    filled:
                                                                        true,
                                                                    fillColor:
                                                                        Colors
                                                                            .white,
                                                                  ),
                                                                  value:
                                                                      row['serumType']
                                                                              ?.toString()
                                                                              .isEmpty ??
                                                                          true
                                                                      ? null
                                                                      : row['serumType'],
                                                                  items: serumTypes.map((
                                                                    type,
                                                                  ) {
                                                                    return DropdownMenuItem(
                                                                      value:
                                                                          type,
                                                                      child:
                                                                          Text(
                                                                            type,
                                                                          ),
                                                                    );
                                                                  }).toList(),
                                                                  onChanged:
                                                                      (
                                                                        value,
                                                                      ) => _updateRow(
                                                                        index,
                                                                        'serumType',
                                                                        value,
                                                                      ),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 12,
                                                              ),
                                                              Expanded(
                                                                child: InkWell(
                                                                  onTap: () =>
                                                                      _showAgeRangePicker(
                                                                        context,
                                                                        index,
                                                                      ),
                                                                  child: Container(
                                                                    padding: const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          16,
                                                                      vertical:
                                                                          16,
                                                                    ),
                                                                    decoration: BoxDecoration(
                                                                      color: Colors
                                                                          .white,
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            12,
                                                                          ),
                                                                      border: Border.all(
                                                                        color:
                                                                            row['ageRange']?.toString().isNotEmpty ??
                                                                                false
                                                                            ? const Color(
                                                                                0xFF0058A3,
                                                                              )
                                                                            : Colors.grey[300]!,
                                                                        width:
                                                                            2,
                                                                      ),
                                                                    ),
                                                                    child: Row(
                                                                      children: [
                                                                        const Icon(
                                                                          Icons
                                                                              .calendar_today,
                                                                          color: Color(
                                                                            0xFF0058A3,
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                          width:
                                                                              12,
                                                                        ),
                                                                        Expanded(
                                                                          child: Column(
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.start,
                                                                            mainAxisSize:
                                                                                MainAxisSize.min,
                                                                            children: [
                                                                              Text(
                                                                                row['ageRange']?.toString().isNotEmpty ??
                                                                                        false
                                                                                    ? row['ageRange'].toString()
                                                                                    : 'Yaş Aralığı Seç *',
                                                                                style: TextStyle(
                                                                                  fontSize: 16,
                                                                                  color:
                                                                                      row['ageRange']?.toString().isNotEmpty ??
                                                                                          false
                                                                                      ? Colors.black87
                                                                                      : Colors.grey[600],
                                                                                  fontWeight:
                                                                                      row['ageRange']?.toString().isNotEmpty ??
                                                                                          false
                                                                                      ? FontWeight.w500
                                                                                      : FontWeight.normal,
                                                                                ),
                                                                              ),
                                                                              if (row['ageRange']?.toString().isEmpty ??
                                                                                  true)
                                                                                Text(
                                                                                  'Örn: 0-6 ay, 1-3 yaş',
                                                                                  style: TextStyle(
                                                                                    fontSize: 12,
                                                                                    color: Colors.grey[500],
                                                                                  ),
                                                                                ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                        Icon(
                                                                          Icons
                                                                              .arrow_drop_down,
                                                                          color:
                                                                              Colors.grey[600],
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          // Referans Aralıkları - Ana Bölüm
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.green.withValues(
                                                    alpha: 0.1,
                                                  ),
                                                  Colors.greenAccent.withValues(
                                                    alpha: 0.1,
                                                  ),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.green.withValues(
                                                  alpha: 0.3,
                                                ),
                                                width: 2,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            8,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.green,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: const Icon(
                                                        Icons.verified,
                                                        color: Colors.white,
                                                        size: 20,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    const Expanded(
                                                      child: Text(
                                                        'Referans Aralıkları (Normal Sınırlar)',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.green,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Bu değerler, sistemin tahlil sonuçlarını kıyaslamak için kullanacağı normal aralıklardır.',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: TextField(
                                                        controller:
                                                            TextEditingController(
                                                              text:
                                                                  row['min']
                                                                      ?.toString() ??
                                                                  '',
                                                            ),
                                                        decoration: InputDecoration(
                                                          labelText:
                                                              'Normal Alt Sınır (mg/dL) *',
                                                          hintText: 'Örn: 600',
                                                          prefixIcon: const Icon(
                                                            Icons
                                                                .arrow_downward,
                                                            color: Colors.red,
                                                          ),
                                                          border: OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                          filled: true,
                                                          fillColor:
                                                              Colors.white,
                                                          helperText:
                                                              'Değer bu sınırın altındaysa ↓ Düşük',
                                                        ),
                                                        keyboardType:
                                                            const TextInputType.numberWithOptions(
                                                              decimal: true,
                                                            ),
                                                        onChanged: (value) =>
                                                            _updateRow(
                                                              index,
                                                              'min',
                                                              value,
                                                            ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: TextField(
                                                        controller:
                                                            TextEditingController(
                                                              text:
                                                                  row['max']
                                                                      ?.toString() ??
                                                                  '',
                                                            ),
                                                        decoration: InputDecoration(
                                                          labelText:
                                                              'Normal Üst Sınır (mg/dL) *',
                                                          hintText: 'Örn: 1400',
                                                          prefixIcon: const Icon(
                                                            Icons.arrow_upward,
                                                            color:
                                                                Colors.orange,
                                                          ),
                                                          border: OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                          filled: true,
                                                          fillColor:
                                                              Colors.white,
                                                          helperText:
                                                              'Değer bu sınırın üstündeyse ↑ Yüksek',
                                                        ),
                                                        keyboardType:
                                                            const TextInputType.numberWithOptions(
                                                              decimal: true,
                                                            ),
                                                        onChanged: (value) =>
                                                            _updateRow(
                                                              index,
                                                              'max',
                                                              value,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.lightbulb_outline,
                                                        size: 18,
                                                        color: Colors.blue,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          'Sistem, hastanın yaşına göre uygun aralığı bulur ve tahlil değerini karşılaştırır: ↓ Düşük, ↔ Normal, ↑ Yüksek',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors
                                                                .blue[900],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          // İleri Seviye Ayarlar (Opsiyonel)
                                          ExpansionTile(
                                            title: const Text(
                                              'İleri Seviye Ayarlar (Opsiyonel)',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            subtitle: const Text(
                                              'Geometrik/Aritmetik ortalama ve standart sapma değerleri',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            initiallyExpanded: false,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.all(
                                                  16,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    _buildSectionTitle(
                                                      'Geometric Mean (Geometrik Ortalama)',
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: TextField(
                                                            controller: TextEditingController(
                                                              text:
                                                                  row['geoMean']
                                                                      ?.toString() ??
                                                                  '',
                                                            ),
                                                            decoration: InputDecoration(
                                                              labelText:
                                                                  'Geometric Mean',
                                                              hintText: '0.00',
                                                              prefixIcon:
                                                                  const Icon(
                                                                    Icons
                                                                        .calculate,
                                                                  ),
                                                              border: OutlineInputBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                              ),
                                                              filled: true,
                                                              fillColor: Colors
                                                                  .grey[50],
                                                            ),
                                                            keyboardType:
                                                                const TextInputType.numberWithOptions(
                                                                  decimal: true,
                                                                ),
                                                            onChanged:
                                                                (value) =>
                                                                    _updateRow(
                                                                      index,
                                                                      'geoMean',
                                                                      value,
                                                                    ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        Expanded(
                                                          child: TextField(
                                                            controller:
                                                                TextEditingController(
                                                                  text:
                                                                      row['gSD']
                                                                          ?.toString() ??
                                                                      '',
                                                                ),
                                                            decoration: InputDecoration(
                                                              labelText:
                                                                  'Standart Sapma (SD)',
                                                              hintText: '0.00',
                                                              prefixIcon:
                                                                  const Icon(
                                                                    Icons
                                                                        .trending_up,
                                                                  ),
                                                              border: OutlineInputBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                              ),
                                                              filled: true,
                                                              fillColor: Colors
                                                                  .grey[50],
                                                            ),
                                                            keyboardType:
                                                                const TextInputType.numberWithOptions(
                                                                  decimal: true,
                                                                ),
                                                            onChanged:
                                                                (value) =>
                                                                    _updateRow(
                                                                      index,
                                                                      'gSD',
                                                                      value,
                                                                    ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 24),
                                                    _buildSectionTitle(
                                                      'Mean (Aritmetik Ortalama)',
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: TextField(
                                                            controller:
                                                                TextEditingController(
                                                                  text:
                                                                      row['mean']
                                                                          ?.toString() ??
                                                                      '',
                                                                ),
                                                            decoration: InputDecoration(
                                                              labelText: 'Mean',
                                                              hintText: '0.00',
                                                              prefixIcon:
                                                                  const Icon(
                                                                    Icons
                                                                        .calculate,
                                                                  ),
                                                              border: OutlineInputBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                              ),
                                                              filled: true,
                                                              fillColor: Colors
                                                                  .grey[50],
                                                            ),
                                                            keyboardType:
                                                                const TextInputType.numberWithOptions(
                                                                  decimal: true,
                                                                ),
                                                            onChanged:
                                                                (value) =>
                                                                    _updateRow(
                                                                      index,
                                                                      'mean',
                                                                      value,
                                                                    ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        Expanded(
                                                          child: TextField(
                                                            controller:
                                                                TextEditingController(
                                                                  text:
                                                                      row['mSD']
                                                                          ?.toString() ??
                                                                      '',
                                                                ),
                                                            decoration: InputDecoration(
                                                              labelText:
                                                                  'Standart Sapma (SD)',
                                                              hintText: '0.00',
                                                              prefixIcon:
                                                                  const Icon(
                                                                    Icons
                                                                        .trending_up,
                                                                  ),
                                                              border: OutlineInputBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                              ),
                                                              filled: true,
                                                              fillColor: Colors
                                                                  .grey[50],
                                                            ),
                                                            keyboardType:
                                                                const TextInputType.numberWithOptions(
                                                                  decimal: true,
                                                                ),
                                                            onChanged:
                                                                (value) =>
                                                                    _updateRow(
                                                                      index,
                                                                      'mSD',
                                                                      value,
                                                                    ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 24),
                                                    _buildSectionTitle(
                                                      'Interval Aralıkları',
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: TextField(
                                                            controller: TextEditingController(
                                                              text:
                                                                  row['intervalMin']
                                                                      ?.toString() ??
                                                                  '',
                                                            ),
                                                            decoration: InputDecoration(
                                                              labelText:
                                                                  'Interval Min',
                                                              hintText: '0.00',
                                                              prefixIcon:
                                                                  const Icon(
                                                                    Icons
                                                                        .trending_down,
                                                                  ),
                                                              border: OutlineInputBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                              ),
                                                              filled: true,
                                                              fillColor: Colors
                                                                  .grey[50],
                                                            ),
                                                            keyboardType:
                                                                const TextInputType.numberWithOptions(
                                                                  decimal: true,
                                                                ),
                                                            onChanged:
                                                                (
                                                                  value,
                                                                ) => _updateRow(
                                                                  index,
                                                                  'intervalMin',
                                                                  value,
                                                                ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        Expanded(
                                                          child: TextField(
                                                            controller: TextEditingController(
                                                              text:
                                                                  row['intervalMax']
                                                                      ?.toString() ??
                                                                  '',
                                                            ),
                                                            decoration: InputDecoration(
                                                              labelText:
                                                                  'Interval Max',
                                                              hintText: '0.00',
                                                              prefixIcon:
                                                                  const Icon(
                                                                    Icons
                                                                        .trending_up,
                                                                  ),
                                                              border: OutlineInputBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                              ),
                                                              filled: true,
                                                              fillColor: Colors
                                                                  .grey[50],
                                                            ),
                                                            keyboardType:
                                                                const TextInputType.numberWithOptions(
                                                                  decimal: true,
                                                                ),
                                                            onChanged:
                                                                (
                                                                  value,
                                                                ) => _updateRow(
                                                                  index,
                                                                  'intervalMax',
                                                                  value,
                                                                ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 24),
                                                    _buildSectionTitle(
                                                      'Aritmetik Ortalama (Alternatif)',
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: TextField(
                                                            controller: TextEditingController(
                                                              text:
                                                                  row['arithMean']
                                                                      ?.toString() ??
                                                                  '',
                                                            ),
                                                            decoration: InputDecoration(
                                                              labelText:
                                                                  'Aritmetik Ortalama',
                                                              hintText: '0.00',
                                                              prefixIcon:
                                                                  const Icon(
                                                                    Icons
                                                                        .calculate,
                                                                  ),
                                                              border: OutlineInputBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                              ),
                                                              filled: true,
                                                              fillColor: Colors
                                                                  .grey[50],
                                                            ),
                                                            keyboardType:
                                                                const TextInputType.numberWithOptions(
                                                                  decimal: true,
                                                                ),
                                                            onChanged:
                                                                (
                                                                  value,
                                                                ) => _updateRow(
                                                                  index,
                                                                  'arithMean',
                                                                  value,
                                                                ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        Expanded(
                                                          child: TextField(
                                                            controller: TextEditingController(
                                                              text:
                                                                  row['arithSD']
                                                                      ?.toString() ??
                                                                  '',
                                                            ),
                                                            decoration: InputDecoration(
                                                              labelText:
                                                                  'Standart Sapma (SS)',
                                                              hintText: '0.00',
                                                              prefixIcon:
                                                                  const Icon(
                                                                    Icons
                                                                        .trending_up,
                                                                  ),
                                                              border: OutlineInputBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                              ),
                                                              filled: true,
                                                              fillColor: Colors
                                                                  .grey[50],
                                                            ),
                                                            keyboardType:
                                                                const TextInputType.numberWithOptions(
                                                                  decimal: true,
                                                                ),
                                                            onChanged:
                                                                (value) =>
                                                                    _updateRow(
                                                                      index,
                                                                      'arithSD',
                                                                      value,
                                                                    ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 32),
                          // Kaydet Butonu (Ortalanmış, Container olmadan)
                          Center(
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              onEnter: (_) =>
                                  setState(() => _isButtonHovered = true),
                              onExit: (_) =>
                                  setState(() => _isButtonHovered = false),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                transform: Matrix4.identity()
                                  ..scale(_isButtonHovered ? 1.05 : 1.0),
                                child: ElevatedButton.icon(
                                  onPressed: _saveGuide,
                                  icon: const Icon(Icons.save),
                                  label: Text(
                                    _isEditMode
                                        ? 'Kılavuzu Güncelle'
                                        : 'Kılavuzu Kaydet',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isButtonHovered
                                        ? Colors.green[700]
                                        : Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 18,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: _isButtonHovered ? 6 : 4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (_rows.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                '${_rows.length} satır eklendi',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: isMobile
          ? AdminBottomNavBar(
              currentIndex: 0,
              onTap: (index) {
                switch (index) {
                  case 0:
                    // Zaten bu sayfadayız
                    break;
                  case 1:
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const KilavuzListScreen(),
                      ),
                    );
                    break;
                  case 2:
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminDashboardScreen(),
                      ),
                    );
                    break;
                  case 3:
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TahlilEkleScreen(),
                      ),
                    );
                    break;
                  case 4:
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TahlilListScreen(),
                      ),
                    );
                    break;
                }
              },
            )
          : null,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0058A3).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: const Color(0xFF0058A3)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0058A3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(String stepNumber, String stepText) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: Color(0xFF0058A3),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              stepNumber,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              stepText,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationRail(BuildContext context) {
    return NavigationRail(
      selectedIndex: _selectedNavIndex,
      labelType: NavigationRailLabelType.all,
      selectedIconTheme: IconThemeData(
        color: Theme.of(context).colorScheme.primary,
      ),
      selectedLabelTextStyle: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
      unselectedIconTheme: IconThemeData(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
      ),
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
          case 0:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminDashboardScreen(),
              ),
            );
            break;
          case 1:
            // Zaten bu sayfadayız
            break;
          case 2:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const KilavuzListScreen(),
              ),
            );
            break;
          case 3:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const TahlilEkleScreen()),
            );
            break;
          case 4:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const TahlilListScreen()),
            );
            break;
          case 5:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminProfileScreen(),
              ),
            );
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
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Ana Sayfa'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminDashboardScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_circle),
            title: const Text('Kılavuz Oluştur'),
            selected: true,
            selectedTileColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.1),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.list),
            title: const Text('Kılavuz Listesi'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const KilavuzListScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Tahlil Ekle'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const TahlilEkleScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('Tahlil Listesi'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const TahlilListScreen(),
                ),
              );
            },
          ),
          const Divider(),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return ListTile(
                leading: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                title: Text(themeProvider.isDarkMode ? 'Açık Mod' : 'Koyu Mod'),
                onTap: () {
                  themeProvider.toggleTheme();
                },
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Ayarlar'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminProfileScreen(),
                ),
              );
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
