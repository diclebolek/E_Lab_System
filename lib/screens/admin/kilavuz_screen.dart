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

// --- SABİT DEĞERLER VE RENKLER ---

const Color kPrimaryColor = Color(0xFF0058A3);
const Color kSecondaryColor = Color(0xFF00A8E8);

// --- WIDGET BAŞLANGICI ---

class KilavuzScreen extends StatefulWidget {
  final String? guideNameToEdit; // Düzenlenecek kılavuz adı
  final Map<String, dynamic>? guideDataToEdit; // Düzenlenecek kılavuz verisi

  const KilavuzScreen({super.key, this.guideNameToEdit, this.guideDataToEdit});

  @override
  State<KilavuzScreen> createState() => _KilavuzScreenState();
}

class _KilavuzScreenState extends State<KilavuzScreen> {
  final List<Map<String, dynamic>> _rows = [];
  String? _savedGuideName; // Kaydedilen başlık
  bool _isLoading = true;
  bool _isButtonHovered = false; // Buton hover durumu
  final int _selectedNavIndex = 1; // NavigationRail için seçili index

  // Yeni yapı için değişkenler
  String? _selectedSerumType; // Seçilen serum tipi (kılavuz adı olacak)
  String _selectedAgeUnit = 'gün'; // 'gün', 'ay' veya 'yıl'
  String _selectedAgeRange = ''; // Seçilen yaş aralığı

  // Yeni serum ekleme için controller'lar (tekrar tekrar kullanılacak)
  final _newSerumMinController = TextEditingController();
  final _newSerumMaxController = TextEditingController();

  // Hazır serum tipleri
  final List<String> _serumTypes = ['IgG', 'IgG1', 'IgG2', 'IgG3', 'IgG4', 'IgA', 'IgA1', 'IgA2', 'IgM'];

  @override
  void initState() {
    super.initState();
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
    _newSerumMinController.dispose();
    _newSerumMaxController.dispose();
    super.dispose();
  }

  bool get _isEditMode => widget.guideNameToEdit != null || widget.guideDataToEdit != null;

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

  // Hassasiyet formatlama
  double _formatNumber(double num, int precision) {
    if (num == 0.0) return 0.0;
    num = double.parse(num.toStringAsFixed(precision));
    return num;
  }

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
          _selectedSerumType = guideName.split(' - ').first;
          _savedGuideName = guideName;
          _rows.clear();

          for (var i = 0; i < rows.length; i++) {
            final row = rows[i] as Map<String, dynamic>;
            final ageRange = row['ageRange']?.toString() ?? '';
            final serumType = row['serumType']?.toString() ?? '';

            if (i == 0 && ageRange.isNotEmpty) {
              if (ageRange.contains('gün')) {
                _selectedAgeUnit = 'gün';
              } else if (ageRange.contains('ay')) {
                _selectedAgeUnit = 'ay';
              } else if (ageRange.contains('yıl') || ageRange.contains('yaş')) {
                _selectedAgeUnit = 'yıl';
              }
              _selectedAgeRange = ageRange;
            }

            // Ortalama/SD değerlerini hesapla
            final geoMeanMin = _safeParseDouble(row['geoMeanMin']);
            final geoMeanMax = _safeParseDouble(row['geoMeanMax']);
            final geoMean = (geoMeanMin + geoMeanMax) / 2;
            final gSD = (geoMeanMax - geoMeanMin) / 2;

            final meanMin = _safeParseDouble(row['meanMin']);
            final meanMax = _safeParseDouble(row['meanMax']);
            final mean = (meanMin + meanMax) / 2;
            final mSD = (meanMax - meanMin) / 2;

            final arithMeanMin = _safeParseDouble(row['arithMeanMin']);
            final arithMeanMax = _safeParseDouble(row['arithMeanMax']);
            final arithMean = (arithMeanMin + arithMeanMax) / 2;
            final arithSD = (arithMeanMax - arithMeanMin) / 2;

            _rows.add({
              'id': i + 1,
              'ageRange': ageRange,
              'geoMean': _formatNumber(geoMean, 2).toString(),
              'gSD': _formatNumber(gSD, 2).toString(),
              'mean': _formatNumber(mean, 2).toString(),
              'mSD': _formatNumber(mSD, 2).toString(),
              'min': row['min']?.toString() ?? '',
              'max': row['max']?.toString() ?? '',
              'intervalMin': row['intervalMin']?.toString() ?? '',
              'intervalMax': row['intervalMax']?.toString() ?? '',
              'serumType': serumType,
              'arithMean': _formatNumber(arithMean, 2).toString(),
              'arithSD': _formatNumber(arithSD, 2).toString(),
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
          const SnackBar(content: Text('Kılavuz yüklenirken bir hata oluştu!'), backgroundColor: Colors.red),
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
          _selectedSerumType = savedName.split(' - ').first;
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

  void _addRow() {
    if (_selectedSerumType == null || _selectedSerumType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen önce bir serum tipi seçin!'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_selectedAgeRange.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lütfen bir yaş aralığı seçin!'), backgroundColor: Colors.orange));
      return;
    }

    String min = _newSerumMinController.text.trim();
    String max = _newSerumMaxController.text.trim();

    if (min.isEmpty && max.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen en az bir değer (Min veya Max) girin!'), backgroundColor: Colors.orange),
      );
      return;
    }

    // Duplicate check
    final isDuplicate = _rows.any(
      (row) => row['ageRange'] == _selectedAgeRange && row['serumType'] == _selectedSerumType,
    );

    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bu serum tipi ve yaş aralığı ($_selectedAgeRange) zaten eklenmiş.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _rows.add({
        'id': _rows.length + 1,
        'ageRange': _selectedAgeRange,
        'serumType': _selectedSerumType!,
        'min': min,
        'max': max,
        'geoMean': '',
        'gSD': '',
        'mean': '',
        'mSD': '',
        'intervalMin': '',
        'intervalMax': '',
        'arithMean': '',
        'arithSD': '',
      });

      // Yaş aralığı ve değer alanlarını temizle (başlık kalacak)
      _selectedAgeRange = '';
      _newSerumMinController.clear();
      _newSerumMaxController.clear();
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Yaş aralığı başarıyla eklendi!'), backgroundColor: Colors.green));
  }

  void _deleteRow(int id) {
    setState(() {
      _rows.removeWhere((row) => row['id'] == id);
    });
  }

  void _updateRow(int index, String field, dynamic value) {
    if (index < 0 || index >= _rows.length) return;

    setState(() {
      _rows[index][field] = value;
    });
  }

  Future<void> _saveGuide() async {
    if (_selectedSerumType == null || _selectedSerumType!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen bir serum tipi seçin!')));
      }
      return;
    }

    if (_rows.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Lütfen en az bir yaş aralığı ve değer aralığı ekleyin!')));
      }
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

    String guideName = _selectedSerumType!;
    bool success;

    if (_isEditMode) {
      final originalName = widget.guideNameToEdit ?? widget.guideDataToEdit?['name'] as String? ?? '';

      success = await FirebaseService.updateGuide(originalName, formattedRows, newGuideName: guideName);

      if (success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Kılavuz başarıyla güncellendi!'), backgroundColor: Colors.green));
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const KilavuzListScreen()));
          }
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kılavuz güncellenirken bir hata oluştu!'), backgroundColor: Colors.red),
        );
      }
    } else {
      success = await FirebaseService.addGuide(guideName, formattedRows);

      if (success) {
        await _saveGuideNameToPrefs(guideName);

        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Kılavuz başarıyla oluşturuldu!'), backgroundColor: Colors.green));
        setState(() {
          _savedGuideName = guideName;
          _rows.clear();
        });
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const KilavuzListScreen()));
          }
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kılavuz oluşturulurken bir hata oluştu!'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Modern yaş aralığı seçici dialog
  Future<void> _showAgeRangePicker(BuildContext context, int rowIndex) async {
    String? ageUnit = _selectedAgeUnit;
    int? minAge;
    int? maxAge;
    bool isPlus = false;

    // Mevcut değeri parse et
    String currentValue = '';
    if (rowIndex == -1) {
      currentValue = _selectedAgeRange;
    } else if (rowIndex >= 0 && rowIndex < _rows.length) {
      currentValue = _rows[rowIndex]['ageRange']?.toString() ?? '';
    }

    if (currentValue.isNotEmpty) {
      // Birimi çıkart
      if (currentValue.contains('gün')) {
        ageUnit = 'gün';
      } else if (currentValue.contains('ay')) {
        ageUnit = 'ay';
      } else if (currentValue.contains('yıl') || currentValue.contains('yaş')) {
        ageUnit = 'yıl';
      }

      if (currentValue.contains('+')) {
        isPlus = true;
        minAge = int.tryParse(currentValue.replaceAll('+', '').trim().replaceAll(RegExp(r'[^0-9]'), ''));
      } else if (currentValue.contains('-')) {
        final parts = currentValue.split('-');
        if (parts.length == 2) {
          minAge = int.tryParse(parts[0].trim().replaceAll(RegExp(r'[^0-9]'), ''));
          maxAge = int.tryParse(parts[1].trim().split(' ').first.replaceAll(RegExp(r'[^0-9]'), ''));
        }
      }
    }

    // Hazır yaş aralıkları (tümü)
    final List<Map<String, String>> predefinedRanges = [
      {'start': '0', 'end': '30', 'label': '0-30 Gün', 'unit': 'gün'},
      {'start': '1', 'end': '3', 'label': '1-3 Ay', 'unit': 'ay'},
      {'start': '4', 'end': '6', 'label': '4-6 Ay', 'unit': 'ay'},
      {'start': '7', 'end': '12', 'label': '7-12 Ay', 'unit': 'ay'},
      {'start': '13', 'end': '24', 'label': '13-24 Ay', 'unit': 'ay'},
      {'start': '25', 'end': '36', 'label': '25-36 Ay', 'unit': 'ay'},
      {'start': '3', 'end': '5', 'label': '3-5 Yıl', 'unit': 'yıl'},
      {'start': '6', 'end': '8', 'label': '6-8 Yıl', 'unit': 'yıl'},
      {'start': '9', 'end': '11', 'label': '9-11 Yıl', 'unit': 'yıl'},
      {'start': '12', 'end': '16', 'label': '12-16 Yıl', 'unit': 'yıl'},
      {'start': '16', 'end': '18', 'label': '16-18 Yıl', 'unit': 'yıl'},
      {'start': '18', 'end': '', 'label': '18+ Yıl', 'unit': 'yıl'},
    ];

    // Controller'ları dialog dışında tanımlıyoruz
    final minAgeController = TextEditingController(text: minAge?.toString() ?? '');
    final maxAgeController = TextEditingController(text: maxAge?.toString() ?? '');

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Seçili hazır aralığı bul
          String? selectedPresetLabel;
          for (final range in predefinedRanges) {
            final currentMin = int.tryParse(range['start']!);
            final currentMax = int.tryParse(range['end'] ?? '');
            if (currentMin == minAge && currentMax == maxAge) {
              selectedPresetLabel = range['label'];
              break;
            }
          }

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.calendar_today, color: kPrimaryColor),
                SizedBox(width: 8),
                Text('Yaş Aralığı Seç'),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Yaş birimi seçimi
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Text('Birim: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Gün'),
                            selected: ageUnit == 'gün',
                            onSelected: (selected) {
                              setDialogState(() {
                                ageUnit = 'gün';
                                minAge = null;
                                maxAge = null;
                                minAgeController.text = '';
                                maxAgeController.text = '';
                              });
                            },
                            selectedColor: kPrimaryColor,
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Ay'),
                            selected: ageUnit == 'ay',
                            onSelected: (selected) {
                              setDialogState(() {
                                ageUnit = 'ay';
                                minAge = null;
                                maxAge = null;
                                minAgeController.text = '';
                                maxAgeController.text = '';
                              });
                            },
                            selectedColor: kPrimaryColor,
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Yıl'),
                            selected: ageUnit == 'yıl',
                            onSelected: (selected) {
                              setDialogState(() {
                                ageUnit = 'yıl';
                                minAge = null;
                                maxAge = null;
                                minAgeController.text = '';
                                maxAgeController.text = '';
                              });
                            },
                            selectedColor: kPrimaryColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Hazır aralıklar - Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selectedPresetLabel,
                      decoration: InputDecoration(
                        labelText: 'Hazır Aralıklar',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.list_alt),
                      ),
                      items: predefinedRanges
                          .map(
                            (range) =>
                                DropdownMenuItem<String>(value: range['label'], child: Text(range['label'] ?? '')),
                          )
                          .toList(),
                      onChanged: (label) {
                        final range = predefinedRanges.firstWhere((r) => r['label'] == label, orElse: () => {});
                        if (range.isEmpty) return;
                        final currentMin = int.tryParse(range['start']!);
                        final currentMax = int.tryParse(range['end'] ?? '');
                        setDialogState(() {
                          selectedPresetLabel = label;
                          minAge = currentMin;
                          maxAge = currentMax;
                          isPlus = (range['end'] ?? '').isEmpty;
                          ageUnit = range['unit'] ?? 'yıl'; // Birimi otomatik ayarla
                          minAgeController.text = range['start']!;
                          maxAgeController.text = range['end'] ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const Text(
                      'Yaş Aralığı Belirle',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kPrimaryColor),
                    ),
                    const SizedBox(height: 12),
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
                                maxAge = null;
                                maxAgeController.text = '';
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                        Expanded(
                          child: CheckboxListTile(
                            title: const Text('Üstü (örn: 16+)'),
                            value: isPlus,
                            onChanged: (value) {
                              setDialogState(() {
                                isPlus = true;
                                maxAge = null;
                                maxAgeController.text = '';
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Minimum yaş
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Başlangıç',
                        hintText: 'Örn: 0, 1, 16',
                        prefixIcon: const Icon(Icons.numbers),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.number,
                      controller: minAgeController,
                      onChanged: (value) {
                        setDialogState(() {
                          minAge = int.tryParse(value);
                        });
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
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.number,
                        controller: maxAgeController,
                        onChanged: (value) {
                          setDialogState(() {
                            maxAge = int.tryParse(value);
                          });
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
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
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
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
              ElevatedButton(
                onPressed: () {
                  String result = '';
                  if (minAge == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lütfen başlangıç yaşını girin!'), backgroundColor: Colors.orange),
                    );
                    return;
                  }

                  if (!isPlus && maxAge == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Lütfen bitiş yaşını girin veya "Üstü" seçeneğini işaretleyin!'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  if (isPlus) {
                    result = '$minAge+ $ageUnit';
                  } else if (maxAge != null) {
                    result = '$minAge-$maxAge $ageUnit';
                  } else {
                    result = '$minAge $ageUnit';
                  }

                  // Hata düzeltmesi: rowIndex -1 ise _rows'u değil, _selectedAgeRange'i güncelle
                  if (rowIndex == -1) {
                    setState(() {
                      _selectedAgeRange = result;
                      _selectedAgeUnit = ageUnit ?? 'yıl';
                    });
                  } else {
                    _updateRow(rowIndex, 'ageRange', result);
                  }

                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, foregroundColor: Colors.white),
                child: const Text('Kaydet'),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- WIDGET BUILD METODU ---

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    final isTablet = ResponsiveBreakpoints.of(context).isTablet;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: isMobile
            ? Align(alignment: Alignment.centerLeft, child: Text(_isEditMode ? 'Kılavuz Düzenle' : 'Kılavuz Oluştur'))
            : Text(_isEditMode ? 'Kılavuz Düzenle' : 'Kılavuz Oluştur'),
        automaticallyImplyLeading: false,
        centerTitle: !isMobile,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kPrimaryColor, kSecondaryColor],
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
                      constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderContainer(isMobile),
                          const SizedBox(height: 16),
                          if (_savedGuideName != null && _selectedSerumType == _savedGuideName) _buildSavedGuideAlert(),
                          _buildSerumTypeDropdown(),
                          const SizedBox(height: 24),
                          _buildAgeRangeAndValueInput(isMobile),
                          const SizedBox(height: 24),
                          // Eklenen Satırlar
                          if (_rows.isNotEmpty) ...[
                            Text(
                              'Eklenen Yaş Aralıkları (${_rows.length})',
                              style: TextStyle(
                                fontSize: isMobile ? 18 : 20,
                                fontWeight: FontWeight.bold,
                                color: kPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ..._rows.asMap().entries.map((entry) {
                              final index = entry.key;
                              final row = entry.value;

                              return _buildRowCard(index, row, isMobile);
                            }),
                          ],
                          const SizedBox(height: 32),
                          _buildSaveButton(),
                          if (_rows.isNotEmpty)
                            Center(
                              child: Text(
                                '${_rows.length} satır eklendi',
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                              ),
                            ),
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
              // Kılavuz Oluştur sayfası: en soldaki (index 0) buton seçili olsun
              currentIndex: 0,
              onTap: (index) {
                switch (index) {
                  case 0:
                    // Zaten bu sayfadayız (Kılavuz Oluştur)
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
                }
              },
            )
          : null,
    );
  }

  // --- YARDIMCI WIDGET METOTLARI ---

  Widget _buildHeaderContainer(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryColor.withValues(alpha: 0.1), kSecondaryColor.withValues(alpha: 0.1)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryColor.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [kPrimaryColor, kSecondaryColor]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.book, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isEditMode
                  ? 'Kılavuz Düzenle: ${widget.guideNameToEdit ?? widget.guideDataToEdit?['name'] ?? ''}'
                  : 'Yeni Kılavuz Bilgileri',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryColor),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: kPrimaryColor),
            tooltip: 'Kılavuz Oluşturma Adımları',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.info_outline, color: kPrimaryColor),
                      SizedBox(width: 8),
                      Text('Kılavuz Oluşturma Adımları'),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStepItem('1', 'Serum tipini seçin (Kılavuz Başlığı).'),
                      const SizedBox(height: 12),
                      _buildStepItem('2', 'Yaş aralığını belirleyin (Manuel veya Hazır).'),
                      const SizedBox(height: 12),
                      _buildStepItem('3', 'Normal Alt/Üst Sınır değerlerini girin.'),
                      const SizedBox(height: 12),
                      _buildStepItem('4', 'Bu yaş aralığını tabloya ekleyin.'),
                      const SizedBox(height: 12),
                      _buildStepItem('5', 'Tüm satırları ekledikten sonra Kaydet butonuna basın.'),
                    ],
                  ),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tamam'))],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSavedGuideAlert() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Bu başlık ("$_savedGuideName") en son kaydedilen başlıktır. Yeni bir kılavuz oluşturmak için farklı bir serum tipi seçin.',
              style: TextStyle(fontSize: 12, color: Colors.green[800], fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSerumTypeDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedSerumType,
      decoration: InputDecoration(
        labelText: 'Serum Tipi *',
        hintText: 'Serum tipini seçin',
        helperText: 'Bu kılavuz hangi serum tipi için olacak?',
        prefixIcon: const Icon(Icons.science),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimaryColor, width: 2),
        ),
      ),
      items: _serumTypes.map((String type) {
        return DropdownMenuItem<String>(value: type, child: Text(type));
      }).toList(),
      onChanged: (String? value) {
        setState(() {
          _selectedSerumType = value;
          _savedGuideName = value; // Seçilen serum tipini başlık olarak kaydet
        });
      },
    );
  }

  Widget _buildAgeRangeAndValueInput(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kPrimaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Yeni Yaş Aralığı Tanımla',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryColor),
          ),
          const SizedBox(height: 12),
          // Seçili Yaş Aralığı Önizlemesi
          InkWell(
            onTap: () => _showAgeRangePicker(context, -1),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _selectedAgeRange.isNotEmpty
                    ? kPrimaryColor.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedAgeRange.isNotEmpty
                      ? kPrimaryColor.withValues(alpha: 0.5)
                      : Colors.grey.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: kPrimaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedAgeRange.isNotEmpty ? 'Seçili Aralık: $_selectedAgeRange' : 'Yaş Aralığı Seç *',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _selectedAgeRange.isNotEmpty ? kPrimaryColor : Colors.grey[600],
                          ),
                        ),
                        if (_selectedAgeRange.isEmpty)
                          Text(
                            'Buraya tıklayarak yaş aralığını seçin.',
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.edit, color: kPrimaryColor),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Min-Max değerleri için alanlar
          const Text(
            'Normal Alt/Üst Sınır Değerleri (mg/dL) *',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kPrimaryColor),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newSerumMinController,
                  decoration: const InputDecoration(
                    labelText: 'Min Değer',
                    hintText: 'Örn: 600',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    prefixIcon: Icon(Icons.arrow_downward, color: Colors.red),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _newSerumMaxController,
                  decoration: const InputDecoration(
                    labelText: 'Max Değer',
                    hintText: 'Örn: 1400',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    prefixIcon: Icon(Icons.arrow_upward, color: Colors.orange),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Satır Ekleme Butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addRow,
              icon: const Icon(Icons.add_box),
              label: const Text('Bu Yaş Aralığını Tabloya Ekle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowCard(int index, Map<String, dynamic> row, bool isMobile) {
    final ageRange = row['ageRange']?.toString() ?? '';
    final serumType = row['serumType']?.toString() ?? 'Bilinmiyor';

    // Bu controller'lar widget state'ini güncelleyeceği için burada tanımlanmalıdır.
    TextEditingController minController = TextEditingController(text: row['min']?.toString() ?? '');
    TextEditingController maxController = TextEditingController(text: row['max']?.toString() ?? '');
    TextEditingController geoMeanController = TextEditingController(text: row['geoMean']?.toString() ?? '');
    TextEditingController gSDController = TextEditingController(text: row['gSD']?.toString() ?? '');
    TextEditingController meanController = TextEditingController(text: row['mean']?.toString() ?? '');
    TextEditingController mSDController = TextEditingController(text: row['mSD']?.toString() ?? '');
    TextEditingController intervalMinController = TextEditingController(text: row['intervalMin']?.toString() ?? '');
    TextEditingController intervalMaxController = TextEditingController(text: row['intervalMax']?.toString() ?? '');
    TextEditingController arithMeanController = TextEditingController(text: row['arithMean']?.toString() ?? '');
    TextEditingController arithSDController = TextEditingController(text: row['arithSD']?.toString() ?? '');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Theme.of(context).cardColor, kPrimaryColor.withValues(alpha: 0.02)],
          ),
          border: Border.all(color: kPrimaryColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BAŞLIK VE SİL BUTONU
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(color: kPrimaryColor, shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('$serumType Kılavuzu', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Yaş Aralığını Sil'),
                        content: Text(
                          'Bu satırı ($_selectedSerumType: ${ageRange.isNotEmpty ? ageRange : "Seçilmemiş"}) silmek istediğinizden emin misiniz?',
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteRow(row['id']);
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            child: const Text('Sil'),
                          ),
                        ],
                      ),
                    );
                  },
                  tooltip: 'Sil',
                ),
              ],
            ),
            const Divider(height: 24),

            // TEMEL BİLGİLER
            _buildSectionTitle('Temel Bilgiler'),
            const SizedBox(height: 12),

            isMobile
                ? Column(
                    children: [
                      _buildTitledContainer('Serum Tipi', Text(serumType), Icons.science),
                      const SizedBox(height: 12),
                      _buildAgeRangeEditable(index, ageRange),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: _buildTitledContainer('Serum Tipi', Text(serumType), Icons.science)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildAgeRangeEditable(index, ageRange)),
                    ],
                  ),
            const SizedBox(height: 24),

            // NORMAL SINIRLAR
            _buildSectionTitle('Normal Referans Aralıkları'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: minController,
                    decoration: const InputDecoration(
                      labelText: 'Alt Sınır (Min) *',
                      hintText: 'Örn: 600.00',
                      prefixIcon: Icon(Icons.arrow_downward, color: Colors.red),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      helperText: 'Altındaki değerler ↓ Düşük kabul edilir.',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) => _updateRow(index, 'min', value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: maxController,
                    decoration: const InputDecoration(
                      labelText: 'Üst Sınır (Max) *',
                      hintText: 'Örn: 1400.00',
                      prefixIcon: Icon(Icons.arrow_upward, color: Colors.orange),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      helperText: 'Üstündeki değerler ↑ Yüksek kabul edilir.',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) => _updateRow(index, 'max', value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // İLERİ SEVİYE AYARLAR (ExpansionTile)
            ExpansionTile(
              title: const Text(
                'İleri Seviye Ayarlar (Opsiyonel)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Geometrik/Aritmetik ortalama ve standart sapma değerleri',
                style: TextStyle(fontSize: 12),
              ),
              initiallyExpanded: false,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // GEOMETRİK ORTALAMA
                      _buildSectionTitle('Geometric Mean (Geometrik Ortalama)'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: geoMeanController,
                              decoration: _inputDecoration('Geo. Mean', Icons.calculate, Colors.grey[50]),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (value) => _updateRow(index, 'geoMean', value),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: gSDController,
                              decoration: _inputDecoration('SD (Geo.)', Icons.trending_up, Colors.grey[50]),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (value) => _updateRow(index, 'gSD', value),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ARİTMETİK ORTALAMA
                      _buildSectionTitle('Mean (Aritmetik Ortalama)'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: meanController,
                              decoration: _inputDecoration('Mean', Icons.calculate, Colors.grey[50]),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (value) => _updateRow(index, 'mean', value),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: mSDController,
                              decoration: _inputDecoration('SD (Arith.)', Icons.trending_up, Colors.grey[50]),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (value) => _updateRow(index, 'mSD', value),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // INTERVAL ARALIKLARI
                      _buildSectionTitle('Interval Aralıkları (Alternatif Min/Max)'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: intervalMinController,
                              decoration: _inputDecoration('Interval Min', Icons.trending_down, Colors.grey[50]),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (value) => _updateRow(index, 'intervalMin', value),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: intervalMaxController,
                              decoration: _inputDecoration('Interval Max', Icons.trending_up, Colors.grey[50]),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (value) => _updateRow(index, 'intervalMax', value),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ARİTMETİK ORTALAMA (Alternatif)
                      _buildSectionTitle('Aritmetik Ortalama (Alternatif Alanlar)'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: arithMeanController,
                              decoration: _inputDecoration('Arith. Mean', Icons.calculate, Colors.grey[50]),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (value) => _updateRow(index, 'arithMean', value),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: arithSDController,
                              decoration: _inputDecoration('Arith. SD', Icons.trending_up, Colors.grey[50]),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (value) => _updateRow(index, 'arithSD', value),
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
    );
  }

  Widget _buildAgeRangeEditable(int index, String ageRange) {
    return InkWell(
      onTap: () => _showAgeRangePicker(context, index),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ageRange.isNotEmpty ? kPrimaryColor.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ageRange.isNotEmpty ? kPrimaryColor.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: kPrimaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Yaş Aralığı (Güncelle)',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600),
                  ),
                  Text(
                    ageRange.isNotEmpty ? ageRange : 'Aralık Seçilmedi *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ageRange.isNotEmpty ? kPrimaryColor : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit, color: kPrimaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildTitledContainer(String title, Widget content, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(icon, size: 18, color: kPrimaryColor),
              const SizedBox(width: 8),
              Expanded(child: content),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, Color? fillColor) {
    return InputDecoration(
      labelText: label,
      hintText: '0.00',
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: fillColor,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: kPrimaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: kPrimaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kPrimaryColor),
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
          decoration: const BoxDecoration(color: kPrimaryColor, shape: BoxShape.circle),
          child: Center(
            child: Text(
              stepNumber,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(stepText, style: const TextStyle(fontSize: 15, color: Colors.black87)),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Center(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isButtonHovered = true),
        onExit: (_) => setState(() => _isButtonHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()
            ..scaleByDouble(
              _isButtonHovered ? 1.05 : 1.0,
              _isButtonHovered ? 1.05 : 1.0,
              _isButtonHovered ? 1.05 : 1.0,
              1.0,
            ),
          child: ElevatedButton.icon(
            onPressed: _saveGuide,
            icon: const Icon(Icons.save),
            label: Text(_isEditMode ? 'Kılavuzu Güncelle' : 'Kılavuzu Kaydet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isButtonHovered ? Colors.green[700] : Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: _isButtonHovered ? 6 : 4,
            ),
          ),
        ),
      ),
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
        // Navigasyon sadece yönlendirme yapıyor, index'i set etmek build'i yeniden tetikleyebilir.
        // Ancak bu sayfadan ayrılacağımız için setState'e gerek yok.
        switch (index) {
          case 0:
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminDashboardScreen()));
            break;
          case 1:
            break;
          case 2:
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const KilavuzListScreen()));
            break;
          case 3:
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TahlilEkleScreen()));
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
          const DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kPrimaryColor, kSecondaryColor],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.local_hospital, color: Colors.white, size: 48),
                SizedBox(height: 8),
                Text(
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
            selected: true,
            selectedTileColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            onTap: () => Navigator.pop(context),
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
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TahlilEkleScreen()));
            },
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
            title: const Text('Ayarlar'),
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
