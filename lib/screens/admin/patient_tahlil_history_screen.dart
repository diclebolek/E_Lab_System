import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:provider/provider.dart';
import '../../models/tahlil_model.dart';
import '../../services/firebase_service.dart';
import '../../services/postgres_service.dart';
import '../../widgets/admin_bottom_nav_bar.dart';
import '../../providers/theme_provider.dart';
import 'admin_dashboard_screen.dart';
import 'kilavuz_screen.dart';
import 'kilavuz_list_screen.dart';
import 'tahlil_ekle_screen.dart';
import 'tahlil_list_screen.dart';
import 'admin_profile_screen.dart';

class PatientTahlilHistoryScreen extends StatefulWidget {
  final String tcNumber;
  final String patientName;

  const PatientTahlilHistoryScreen({super.key, required this.tcNumber, required this.patientName});

  @override
  State<PatientTahlilHistoryScreen> createState() => _PatientTahlilHistoryScreenState();
}

class _PatientTahlilHistoryScreenState extends State<PatientTahlilHistoryScreen> {
  List<TahlilModel> _allTahliller = [];
  List<TahlilModel> _displayedTahliller = [];
  final String _sortOrder = 'desc'; // 'asc' veya 'desc'
  bool _isLoading = true;
  String? _selectedSerumType; // Karşılaştırma için seçilen serum tipi
  List<Map<String, dynamic>> _guides = []; // Kılavuzlar

  @override
  void initState() {
    super.initState();
    _loadTahliller();
    _loadGuides();
  }

  // Kılavuzları yükle
  Future<void> _loadGuides() async {
    try {
      final guides = await PostgresService.getGuides();
      final guidesWithData = <Map<String, dynamic>>[];

      for (var guide in guides) {
        final guideData = await FirebaseService.getGuide(guide['name']);
        if (guideData != null) {
          guidesWithData.add({'guideName': guide['name'], 'data': guideData['rows'] ?? []});
        }
      }

      setState(() {
        _guides = guidesWithData;
      });
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  Future<void> _loadTahliller() async {
    setState(() => _isLoading = true);
    try {
      final dataList = await PostgresService.getTahlillerByTC(widget.tcNumber);
      final tahliller = <TahlilModel>[];

      for (final data in dataList) {
        final detail = await FirebaseService.getTahlilById(data['id'] ?? '');
        final serumTypes = <SerumType>[];

        if (detail != null && detail['serumTypes'] != null) {
          for (final s in detail['serumTypes'] as List) {
            serumTypes.add(SerumType(type: s['type'] ?? '', value: s['value'] ?? ''));
          }
        }

        tahliller.add(
          TahlilModel(
            id: data['id']?.toString() ?? '',
            fullName: data['fullName'] ?? '',
            tcNumber: data['tcNumber'] ?? '',
            birthDate: data['birthDate'] != null ? DateTime.tryParse(data['birthDate'].toString()) : null,
            age: data['age'] ?? 0,
            gender: data['gender'] ?? '',
            patientType: data['patientType'] ?? '',
            sampleType: data['sampleType'] ?? '',
            serumTypes: serumTypes,
            reportDate: data['reportDate'] ?? '',
          ),
        );
      }

      setState(() {
        _allTahliller = tahliller;
        _sortTahliller();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _allTahliller = [];
        _displayedTahliller = [];
        _isLoading = false;
      });
    }
  }

  void _sortTahliller() {
    _displayedTahliller = List.from(_allTahliller);
    _displayedTahliller.sort((a, b) {
      final dateA = _parseDate(a.reportDate);
      final dateB = _parseDate(b.reportDate);

      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;

      if (_sortOrder == 'desc') {
        return dateB.compareTo(dateA); // Yeni -> Eski
      } else {
        return dateA.compareTo(dateB); // Eski -> Yeni
      }
    });
  }

  DateTime? _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length >= 3) {
        return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  // Yaşı formatla: manuel yaş değeri varsa onu kullan, yoksa doğum tarihinden hesapla
  String _formatAge(TahlilModel tahlil) {
    // Admin tahlil detay ekranından girilen / güncellenen yaş bilgisi
    // varsa (0'dan büyükse) doğum tarihine bakmadan bunu göster.
    if (tahlil.age > 0) {
      return '${tahlil.age} yıl';
    }

    // Yaş alanı boşsa, doğum tarihinden otomatik hesapla
    if (tahlil.birthDate == null) {
      return '-';
    }

    final now = DateTime.now();
    final birthDate = tahlil.birthDate!;

    // Yaşı hesapla
    int years = now.year - birthDate.year;
    int months = now.month - birthDate.month;
    int days = now.day - birthDate.day;

    if (days < 0) {
      months--;
      // Önceki ayın gün sayısını al
      final prevMonth = DateTime(now.year, now.month - 1, 0);
      days += prevMonth.day;
    }

    if (months < 0) {
      years--;
      months += 12;
    }

    // 2 yaşından küçükse aylık göster
    if (years < 2) {
      final totalMonths = years * 12 + months;
      if (totalMonths == 0) {
        // 1 aydan küçükse günlük göster
        final totalDays = now.difference(birthDate).inDays;
        if (totalDays < 7) {
          return '$totalDays gün';
        } else if (totalDays < 30) {
          final weeks = (totalDays / 7).floor();
          return '$weeks hafta';
        } else {
          return '1 ay';
        }
      }
      return '$totalMonths ay';
    }

    // 2 yaş ve üzeri için yıl göster
    return '$years yıl';
  }

  String _getChangeIndicator(double current, double? previous) {
    if (previous == null) return '';
    if (current > previous) return '↑';
    if (current < previous) return '↓';
    return '↔';
  }

  // Yaşı hesapla (ay cinsinden)
  int _calculateAgeInMonths(TahlilModel tahlil) {
    if (tahlil.birthDate == null) {
      // Doğum tarihi yoksa yaş bilgisini kullan (yıl -> ay)
      return tahlil.age * 12;
    }

    final now = DateTime.now();
    final birthDate = tahlil.birthDate!;
    int years = now.year - birthDate.year;
    int months = now.month - birthDate.month;

    if (now.day < birthDate.day) {
      months--;
    }
    if (months < 0) {
      years--;
      months += 12;
    }

    return years * 12 + months;
  }

  // Yaş aralığında mı kontrol et
  bool _isAgeInRange(String ageRange, int ageInMonths) {
    if (ageRange.isEmpty) return false;

    // "0-6 ay" veya "2-5 yıl" formatını parse et
    final parts = ageRange.split(' ');
    if (parts.length < 2) return false;

    final rangePart = parts[0];
    final unit = parts[1].toLowerCase();

    if (rangePart.contains('-')) {
      final rangeValues = rangePart.split('-');
      if (rangeValues.length != 2) return false;

      final minStr = rangeValues[0].trim();
      final maxStr = rangeValues[1].trim();

      int? min = int.tryParse(minStr);
      int? max = int.tryParse(maxStr);

      if (min == null || max == null) return false;

      // Birime göre dönüştür
      if (unit.contains('yıl')) {
        min = min * 12;
        max = max * 12;
      }

      return ageInMonths >= min && ageInMonths <= max;
    } else if (rangePart.contains('+')) {
      final minStr = rangePart.replaceAll('+', '').trim();
      int? min = int.tryParse(minStr);
      if (min == null) return false;

      if (unit.contains('yıl')) {
        min = min * 12;
      }

      return ageInMonths >= min;
    }

    return false;
  }

  // Güvenli double dönüştürme
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

  // Serum değerini değerlendir
  String _evaluateSerumValue(double value, double min, double max) {
    if (value < min) return '↓'; // Düşük
    if (value > max) return '↑'; // Yüksek
    return '↔'; // Normal
  }

  // Kılavuza göre serum değerlendirmesi
  Map<String, dynamic>? _getSerumEvaluation(TahlilModel tahlil, String serumType, double value) {
    if (_guides.isEmpty) return null;

    final ageInMonths = _calculateAgeInMonths(tahlil);
    if (ageInMonths == 0) return null;

    for (var guide in _guides) {
      final guideData = guide['data'] as List;
      final filteredRows = guideData.where((row) {
        final ageRange = row['ageRange'] as String? ?? '';
        return _isAgeInRange(ageRange, ageInMonths);
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

  // Ok rengini al
  Color _getArrowColor(String arrow) {
    switch (arrow) {
      case '↓':
        return Colors.red;
      case '↑':
        return Colors.orange;
      case '↔':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getChangeColor(String indicator) {
    switch (indicator) {
      case '↑':
        return Colors.orange;
      case '↓':
        return Colors.red;
      case '↔':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  double? _getPreviousSerumValue(String serumType, int currentIndex) {
    if (currentIndex >= _displayedTahliller.length - 1) return null;

    // Bir sonraki (daha eski) tahlildeki değeri bul
    final nextTahlil = _displayedTahliller[currentIndex + 1];
    for (var serum in nextTahlil.serumTypes) {
      if (serum.type == serumType) {
        return double.tryParse(serum.value);
      }
    }
    return null;
  }

  Set<String> _getAllSerumTypes() {
    final types = <String>{};
    for (var tahlil in _allTahliller) {
      for (var serum in tahlil.serumTypes) {
        types.add(serum.type);
      }
    }
    return types;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.patientName.split('\n').first.split(' TC').first.trim(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _displayedTahliller.isEmpty
          ? const Center(child: Text('Bu hastaya ait tahlil bulunamadı'))
          : Column(
              children: [
                // Serum tipi seçimi (karşılaştırma için)
                if (_getAllSerumTypes().isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0058A3).withValues(alpha: 0.05),
                      border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
                            value: _selectedSerumType,
                            hint: const Text('Serum tipi seçin'),
                            isExpanded: true,
                            items: _getAllSerumTypes()
                                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedSerumType = value;
                              });
                            },
                          ),
                        ),
                        if (_selectedSerumType != null)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _selectedSerumType = null;
                              });
                            },
                            tooltip: 'Temizle',
                          ),
                      ],
                    ),
                  ),
                // Tahlil listesi
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    itemCount: _displayedTahliller.length,
                    itemBuilder: (context, index) {
                      final tahlil = _displayedTahliller[index];
                      final isLatest = index == 0 && _sortOrder == 'desc';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: isLatest ? 4 : 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isLatest ? BorderSide(color: const Color(0xFF0058A3), width: 2) : BorderSide.none,
                        ),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: isLatest ? const Color(0xFF0058A3) : Colors.grey.shade300,
                            child: Icon(Icons.assignment, color: isLatest ? Colors.white : Colors.grey.shade700),
                          ),
                          title: Text(
                            'Tahlil #${_displayedTahliller.length - index}',
                            style: TextStyle(
                              fontWeight: isLatest ? FontWeight.bold : FontWeight.normal,
                              color: isLatest ? const Color(0xFF0058A3) : Colors.black,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tarih: ${tahlil.reportDate}'),
                              if (isLatest)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0058A3).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'En Yeni',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0058A3),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Hasta bilgileri
                                  _buildEditableInfoRow('Adı Soyadı', tahlil.fullName, tahlil.id, 'fullName'),
                                  _buildEditableInfoRow('T.C. Kimlik No', tahlil.tcNumber, tahlil.id, 'tcNumber'),
                                  _buildEditableInfoRow('Yaş', _formatAge(tahlil), tahlil.id, 'age'),
                                  _buildEditableInfoRow('Cinsiyet', tahlil.gender, tahlil.id, 'gender'),
                                  _buildEditableInfoRow(
                                    'Hastalık Tanısı',
                                    tahlil.patientType,
                                    tahlil.id,
                                    'patientType',
                                  ),
                                  _buildEditableInfoRow('Numune Türü', tahlil.sampleType, tahlil.id, 'sampleType'),
                                  const Divider(),
                                  // Serum değerleri
                                  const Text(
                                    'Serum Değerleri',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0058A3),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...tahlil.serumTypes.map((serum) {
                                    final currentValue = double.tryParse(serum.value) ?? 0.0;
                                    final previousValue = _getPreviousSerumValue(serum.type, index);
                                    final changeIndicator = _getChangeIndicator(currentValue, previousValue);
                                    // Kılavuza göre değerlendirme
                                    final guideEvaluation = _getSerumEvaluation(tahlil, serum.type, currentValue);
                                    final showComparison =
                                        _selectedSerumType == null || _selectedSerumType == serum.type;

                                    if (!showComparison && _selectedSerumType != null) {
                                      return const SizedBox.shrink();
                                    }

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      color: previousValue != null
                                          ? _getChangeColor(changeIndicator).withValues(alpha: 0.05)
                                          : (guideEvaluation != null
                                                ? _getArrowColor(guideEvaluation['arrow']).withValues(alpha: 0.05)
                                                : null),
                                      child: ListTile(
                                        leading: guideEvaluation != null
                                            ? Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: _getArrowColor(
                                                    guideEvaluation['arrow'],
                                                  ).withValues(alpha: 0.1),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: _getArrowColor(guideEvaluation['arrow']),
                                                    width: 2,
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    guideEvaluation['arrow'],
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: _getArrowColor(guideEvaluation['arrow']),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : (previousValue != null
                                                  ? Container(
                                                      width: 40,
                                                      height: 40,
                                                      decoration: BoxDecoration(
                                                        color: _getChangeColor(changeIndicator).withValues(alpha: 0.1),
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color: _getChangeColor(changeIndicator),
                                                          width: 2,
                                                        ),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          changeIndicator,
                                                          style: TextStyle(
                                                            fontSize: 18,
                                                            fontWeight: FontWeight.bold,
                                                            color: _getChangeColor(changeIndicator),
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  : null),
                                        title: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '${serum.type}: ${serum.value} mg/dl',
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            if (guideEvaluation != null)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: _getArrowColor(
                                                    guideEvaluation['arrow'],
                                                  ).withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      guideEvaluation['arrow'] == '↔'
                                                          ? 'Normal'
                                                          : guideEvaluation['arrow'] == '↓'
                                                          ? 'Düşük'
                                                          : 'Yüksek',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                        color: _getArrowColor(guideEvaluation['arrow']),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (guideEvaluation != null)
                                              Text(
                                                'Kılavuz: ${guideEvaluation['rangeType']} (${guideEvaluation['range']})',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.blue[700],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            if (previousValue != null)
                                              Text(
                                                'Önceki: $previousValue mg/dl',
                                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                              )
                                            else if (guideEvaluation == null)
                                              const Text(
                                                'İlk ölçüm',
                                                style: TextStyle(fontSize: 12, color: Colors.grey),
                                              ),
                                          ],
                                        ),
                                        trailing: previousValue != null && guideEvaluation == null
                                            ? Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: _getChangeColor(changeIndicator).withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  changeIndicator,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: _getChangeColor(changeIndicator),
                                                  ),
                                                ),
                                              )
                                            : null,
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: isMobile
          ? AdminBottomNavBar(
              currentIndex: 4,
              onTap: (index) {
                switch (index) {
                  case 0:
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                    );
                    break;
                  case 1:
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const KilavuzScreen()));
                    break;
                  case 2:
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const KilavuzListScreen()),
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

  Widget _buildEditableInfoRow(String label, String value, String tahlilId, String fieldName) {
    String displayValue = value;
    if (value.isEmpty) {
      if (fieldName == 'patientType') {
        displayValue = '(Tanı girilmemiş)';
      } else if (fieldName == 'gender') {
        displayValue = '(Cinsiyet girilmemiş)';
      } else {
        displayValue = '(Girilmemiş)';
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(displayValue, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF0058A3), size: 20),
            onPressed: () => _showEditDialog(tahlilId, label, value, fieldName),
            tooltip: '$label Düzenle',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(String tahlilId, String label, String currentValue, String fieldName) async {
    Widget? content;
    Map<String, dynamic> updates = {};

    // Cinsiyet için dropdown
    if (fieldName == 'gender') {
      String? selectedGender = currentValue.isEmpty || currentValue == '(Cinsiyet girilmemiş)' ? null : currentValue;

      final result = await showDialog<String>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('$label Düzenle'),
              content: DropdownButtonFormField<String>(
                initialValue: selectedGender,
                decoration: const InputDecoration(labelText: 'Cinsiyet', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'Erkek', child: Text('Erkek')),
                  DropdownMenuItem(value: 'Kadın', child: Text('Kadın')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedGender = value;
                  });
                },
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, selectedGender ?? ''),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0058A3),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        ),
      );

      if (result != null && result != currentValue && result != '(Cinsiyet girilmemiş)') {
        updates['gender'] = result;
        await _updateTahlil(tahlilId, updates, label);
      }
      return;
    }

    // Yaş için sayı inputu
    if (fieldName == 'age') {
      final TextEditingController controller = TextEditingController(
        text: currentValue.replaceAll(' yıl', '').replaceAll(' ay', '').replaceAll(' gün', '').replaceAll(' hafta', ''),
      );

      content = TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label, hintText: 'Yaş girin', border: const OutlineInputBorder()),
        keyboardType: TextInputType.number,
        autofocus: true,
      );

      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('$label Düzenle'),
          content: content,
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0058A3), foregroundColor: Colors.white),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      );

      if (result != null && result.isNotEmpty) {
        final age = int.tryParse(result);
        if (age != null) {
          updates['age'] = age;
          await _updateTahlil(tahlilId, updates, label);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Geçerli bir yaş giriniz'), backgroundColor: Colors.red));
          }
        }
      }
      return;
    }

    // Diğer alanlar için normal text input
    final TextEditingController controller = TextEditingController(text: currentValue);
    content = TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label, hintText: '$label girin', border: const OutlineInputBorder()),
      maxLines: fieldName == 'patientType' ? 3 : 1,
      autofocus: true,
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$label Düzenle'),
        content: content,
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0058A3), foregroundColor: Colors.white),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (result != null && result != currentValue) {
      if (fieldName == 'fullName') {
        updates['fullName'] = result;
      } else if (fieldName == 'tcNumber') {
        updates['tcNumber'] = result;
      } else if (fieldName == 'patientType') {
        updates['patientType'] = result;
      } else if (fieldName == 'sampleType') {
        updates['sampleType'] = result;
      }

      if (updates.isNotEmpty) {
        await _updateTahlil(tahlilId, updates, label);
      }
    }
  }

  Future<void> _updateTahlil(String tahlilId, Map<String, dynamic> updates, String label) async {
    final success = await FirebaseService.updateTahlil(tahlilId, updates);

    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$label başarıyla güncellendi!'), backgroundColor: Colors.green));
      // Tahlilleri yeniden yükle
      _loadTahliller();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Güncelleme sırasında bir hata oluştu!'), backgroundColor: Colors.red),
      );
    }
  }
}
