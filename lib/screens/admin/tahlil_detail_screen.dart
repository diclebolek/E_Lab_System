import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../models/tahlil_model.dart';
import '../../services/firebase_service.dart';
import '../../widgets/theme_toggle_button.dart';
import '../../widgets/admin_bottom_nav_bar.dart';
import 'admin_dashboard_screen.dart';
import 'kilavuz_screen.dart';
import 'kilavuz_list_screen.dart';
import 'tahlil_ekle_screen.dart';
import 'tahlil_list_screen.dart';

class TahlilDetailScreen extends StatefulWidget {
  final String tahlilId;

  const TahlilDetailScreen({super.key, required this.tahlilId});

  @override
  State<TahlilDetailScreen> createState() => _TahlilDetailScreenState();
}

class _TahlilDetailScreenState extends State<TahlilDetailScreen> {
  List<TahlilModel> _previousTahliller = [];
  String? _currentPatientType;
  int _refreshKey = 0;
  
  // Düzenlenebilir alanlar için güncel değerler
  String? _currentFullName;
  String? _currentTCNumber;
  int? _currentAge;
  String? _currentGender;
  String? _currentSampleType;

  String _getChangeIndicator(double current, double? previous) {
    if (previous == null) return '';
    if (current > previous) return '↑';
    if (current < previous) return '↓';
    return '↔';
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

  double? _getPreviousSerumValue(String serumType, List<TahlilModel> previousTahliller) {
    if (previousTahliller.isEmpty) return null;
    
    // En son tahlilden önceki değeri bul
    for (var tahlil in previousTahliller) {
      for (var serum in tahlil.serumTypes) {
        if (serum.type == serumType) {
          return double.tryParse(serum.value);
        }
      }
    }
    return null;
  }

  Future<void> _loadPreviousTahliller(String tc) async {
    try {
      // Aynı hastanın önceki tahlillerini yükle (mevcut tahlil hariç)
      final allTahlillerList = <Map<String, dynamic>>[];
      await for (var data in FirebaseService.getTahlillerByTC(tc)) {
        allTahlillerList.add(data as Map<String, dynamic>);
      }
      
      final previousTahliller = <TahlilModel>[];

      for (var data in allTahlillerList) {
        // Mevcut tahlili atla
        if (data['id']?.toString() == widget.tahlilId) continue;

        final detail = await FirebaseService.getTahlilById(data['id'] ?? '');
        if (detail == null) continue;

        final serumTypes = <SerumType>[];
        if (detail['serumTypes'] != null) {
          for (var s in detail['serumTypes'] as List) {
            serumTypes.add(
              SerumType(type: s['type'] ?? '', value: s['value'] ?? ''),
            );
          }
        }

        previousTahliller.add(
          TahlilModel(
            id: data['id']?.toString() ?? '',
            fullName: data['fullName'] ?? '',
            tcNumber: data['tcNumber'] ?? '',
            birthDate: data['birthDate'] != null
                ? DateTime.tryParse(data['birthDate'].toString())
                : null,
            age: data['age'] ?? 0,
            gender: data['gender'] ?? '',
            patientType: data['patientType'] ?? '',
            sampleType: data['sampleType'] ?? '',
            serumTypes: serumTypes,
            reportDate: data['reportDate'] ?? '',
          ),
        );
      }

      // Tarihe göre sırala (en yeni önce)
      previousTahliller.sort((a, b) {
        final dateA = _parseDate(a.reportDate);
        final dateB = _parseDate(b.reportDate);
        if (dateA == null || dateB == null) return 0;
        return dateB.compareTo(dateA);
      });

      setState(() {
        _previousTahliller = previousTahliller;
      });
    } catch (e) {
      setState(() {
        _previousTahliller = [];
      });
    }
  }

  DateTime? _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length >= 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Map<String, dynamic>?>(
          future: FirebaseService.getTahlilById(widget.tahlilId),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              final tahlil = TahlilModel.fromFirestore(snapshot.data!, widget.tahlilId);
              return isMobile
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Text(tahlil.fullName),
                    )
                  : Text(tahlil.fullName);
            }
            return isMobile
                ? const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Tahlil Detayı'),
                  )
                : const Text('Tahlil Detayı');
          },
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
          if (!isMobile) const ThemeToggleButton(),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        key: ValueKey(_refreshKey),
        future: FirebaseService.getTahlilById(widget.tahlilId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Tahlil bulunamadı'));
          }

          final tahlil = TahlilModel.fromFirestore(snapshot.data!, widget.tahlilId);
          
          // Güncel değerleri başlat (sadece bir kez)
          if (_currentFullName == null) {
            _currentFullName = tahlil.fullName;
            _currentTCNumber = tahlil.tcNumber;
            _currentAge = tahlil.age;
            _currentGender = tahlil.gender;
            _currentPatientType = tahlil.patientType;
            _currentSampleType = tahlil.sampleType;
          }
          
          // Önceki tahlilleri yükle
          _loadPreviousTahliller(tahlil.tcNumber);

          return SingleChildScrollView(
            key: ValueKey(_refreshKey),
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEditableInfoCard(
                  'Adı Soyadı',
                  _currentFullName ?? tahlil.fullName,
                  Icons.person,
                  'fullName',
                ),
                _buildEditableInfoCard(
                  'T.C. Kimlik No',
                  _currentTCNumber ?? tahlil.tcNumber,
                  Icons.badge,
                  'tcNumber',
                ),
                _buildEditableInfoCard(
                  'Yaş (Yıl)',
                  (_currentAge ?? tahlil.age).toString(),
                  Icons.cake,
                  'age',
                ),
                _buildEditableInfoCard(
                  'Cinsiyet',
                  (_currentGender ?? tahlil.gender).isEmpty ? '(Cinsiyet girilmemiş)' : (_currentGender ?? tahlil.gender),
                  Icons.wc,
                  'gender',
                ),
                _buildEditableInfoCard(
                  'Hastalık Tanısı',
                  (_currentPatientType ?? tahlil.patientType).isEmpty ? '(Tanı girilmemiş)' : (_currentPatientType ?? tahlil.patientType),
                  Icons.local_hospital,
                  'patientType',
                ),
                _buildEditableInfoCard(
                  'Numune Türü',
                  _currentSampleType ?? tahlil.sampleType,
                  Icons.science,
                  'sampleType',
                ),
                _buildInfoCard('Rapor Tarihi', tahlil.reportDate, Icons.calendar_today),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text(
                      'Serum Değerleri',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0058A3),
                      ),
                    ),
                    if (_previousTahliller.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0058A3).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Değişim Analizi Aktif',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF0058A3),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                ...tahlil.serumTypes.map((serum) {
                  final currentValue = double.tryParse(serum.value) ?? 0.0;
                  final previousValue = _getPreviousSerumValue(serum.type, _previousTahliller);
                  final changeIndicator = _getChangeIndicator(currentValue, previousValue);
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: previousValue != null
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
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: _getChangeColor(changeIndicator),
                                  ),
                                ),
                              ),
                            )
                          : null,
                      title: Text(
                        '${serum.type}: ${serum.value} mg/dl',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: previousValue != null
                          ? Text(
                              'Önceki: $previousValue mg/dl',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            )
                          : null,
                      trailing: previousValue != null
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getChangeColor(changeIndicator).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                changeIndicator,
                                style: TextStyle(
                                  fontSize: 18,
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
          );
        },
      ),
      bottomNavigationBar: isMobile
          ? AdminBottomNavBar(
              currentIndex: 4,
              onTap: (index) {
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
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const KilavuzScreen(),
                      ),
                    );
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

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF0058A3).withValues(alpha: 0.1),
          child: Icon(icon, color: const Color(0xFF0058A3)),
        ),
        title: Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        subtitle: Text(
          value.isEmpty ? '(Girilmemiş)' : value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0058A3),
          ),
        ),
      ),
    );
  }

  Widget _buildEditableInfoCard(String label, String value, IconData icon, String fieldName) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF0058A3).withValues(alpha: 0.1),
              child: Icon(icon, color: const Color(0xFF0058A3)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0058A3),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0058A3).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF0058A3), size: 24),
                onPressed: () => _showEditDialog(label, value, fieldName),
                tooltip: '$label Düzenle',
                padding: const EdgeInsets.all(8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(
    String label,
    String currentValue,
    String fieldName,
  ) async {
    final TextEditingController controller = TextEditingController(text: currentValue);
    
    Widget? content;
    
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
                value: selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Cinsiyet',
                  border: OutlineInputBorder(),
                ),
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
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
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
        await _updateField(fieldName, result);
      }
      return;
    }
    
    // Yaş için sayı inputu
    if (fieldName == 'age') {
      content = TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: 'Yaş girin',
          border: const OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        autofocus: true,
      );
    } else {
      // Diğer alanlar için normal text input
      content = TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: '$label girin',
          border: const OutlineInputBorder(),
        ),
        maxLines: fieldName == 'patientType' ? 3 : 1,
        autofocus: true,
      );
    }
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$label Düzenle'),
        content: content,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0058A3),
              foregroundColor: Colors.white,
            ),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (result != null && result != currentValue) {
      await _updateField(fieldName, result);
    }
  }

  Future<void> _updateField(String fieldName, String value) async {
    Map<String, dynamic> updates = {};
    
    if (fieldName == 'fullName') {
      updates['fullName'] = value;
      _currentFullName = value;
    } else if (fieldName == 'tcNumber') {
      updates['tcNumber'] = value;
      _currentTCNumber = value;
    } else if (fieldName == 'age') {
      final age = int.tryParse(value);
      if (age != null) {
        updates['age'] = age;
        _currentAge = age;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Geçerli bir yaş giriniz'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    } else if (fieldName == 'gender') {
      updates['gender'] = value;
      _currentGender = value;
    } else if (fieldName == 'patientType') {
      updates['patientType'] = value;
      _currentPatientType = value;
    } else if (fieldName == 'sampleType') {
      updates['sampleType'] = value;
      _currentSampleType = value;
    }

    if (updates.isEmpty) return;

    final success = await FirebaseService.updateTahlil(widget.tahlilId, updates);

    if (success && mounted) {
      setState(() {
        _refreshKey++; // Sayfayı yenile
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$fieldName başarıyla güncellendi!'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Güncelleme sırasında bir hata oluştu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

