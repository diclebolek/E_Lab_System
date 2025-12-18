import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:provider/provider.dart';
import '../../models/tahlil_model.dart';
import '../../services/firebase_service.dart';
import '../../widgets/user_bottom_nav_bar.dart';
import '../../providers/theme_provider.dart';

class UserTahlilDetailScreen extends StatefulWidget {
  final String tahlilId;

  const UserTahlilDetailScreen({super.key, required this.tahlilId});

  @override
  State<UserTahlilDetailScreen> createState() => _UserTahlilDetailScreenState();
}

class _UserTahlilDetailScreenState extends State<UserTahlilDetailScreen> {
  List<Map<String, dynamic>> _guides = [];
  List<TahlilModel> _previousTahliller = [];
  bool _previousTahlillerLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadGuides();
  }

  Future<void> _loadGuides() async {
    try {
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
            guides.add({'name': guideName, 'data': guideData['rows'] ?? []});
          }
        }
      }

      setState(() {
        _guides = guides;
      });
    } catch (e) {
      setState(() {
        _guides = [];
      });
    }
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
            serumTypes.add(SerumType(type: s['type'] ?? '', value: s['value'] ?? ''));
          }
        }

        previousTahliller.add(
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
        return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      }
    } catch (e) {
      return null;
    }
    return null;
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

  String _evaluateSerumValue(double serumValue, double min, double max) {
    if (serumValue < min) return '↓';
    if (serumValue > max) return '↑';
    return '↔';
  }

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

  Map<String, String>? _evaluateSerumForAge(TahlilModel tahlil, String serumType, double serumValue) {
    // Kılavuzlardan yaşa uygun aralığı bul
    for (var guide in _guides) {
      final guideData = guide['data'] as List?;
      if (guideData == null) continue;

      for (var row in guideData) {
        final ageRange = row['ageRange'] as String?;
        final rowSerumType = row['serumType'] as String?;

        if (rowSerumType != serumType) continue;
        if (ageRange == null) continue;

        final parts = ageRange.split('-');
        final minAge = parts[0].isEmpty ? null : int.tryParse(parts[0]);
        final maxAge = parts.length > 1 && parts[1].isNotEmpty ? int.tryParse(parts[1]) : null;

        bool ageMatches = false;
        if (minAge != null && maxAge != null) {
          ageMatches = tahlil.age >= minAge && tahlil.age <= maxAge;
        } else if (minAge != null) {
          ageMatches = tahlil.age >= minAge;
        } else if (maxAge != null) {
          ageMatches = tahlil.age <= maxAge;
        }

        if (ageMatches) {
          // Öncelik sırası: min/max (Normal Alt/Üst Sınır) > geoMean > arithMean > mean
          final minValue = _safeToDouble(row['min']);
          final maxValue = _safeToDouble(row['max']);
          if (minValue != null && maxValue != null) {
            final arrow = _evaluateSerumValue(serumValue, minValue, maxValue);
            return {'arrow': arrow, 'range': '${row['min']}-${row['max']}'};
          }
          final geoMeanMin = _safeToDouble(row['geoMeanMin']);
          final geoMeanMax = _safeToDouble(row['geoMeanMax']);
          if (geoMeanMin != null && geoMeanMax != null) {
            final arrow = _evaluateSerumValue(serumValue, geoMeanMin, geoMeanMax);
            return {'arrow': arrow, 'range': '${row['geoMeanMin']}-${row['geoMeanMax']}'};
          }
          final arithMeanMin = _safeToDouble(row['arithMeanMin']);
          final arithMeanMax = _safeToDouble(row['arithMeanMax']);
          if (arithMeanMin != null && arithMeanMax != null) {
            final arrow = _evaluateSerumValue(serumValue, arithMeanMin, arithMeanMax);
            return {'arrow': arrow, 'range': '${row['arithMeanMin']}-${row['arithMeanMax']}'};
          }
          final meanMin = _safeToDouble(row['meanMin']);
          final meanMax = _safeToDouble(row['meanMax']);
          if (meanMin != null && meanMax != null) {
            final arrow = _evaluateSerumValue(serumValue, meanMin, meanMax);
            return {'arrow': arrow, 'range': '${row['meanMin']}-${row['meanMax']}'};
          }
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tahlil Detay'),
        automaticallyImplyLeading: false,
        centerTitle: false,
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
                onPressed: () => Scaffold.of(context).openDrawer(),
                tooltip: 'Menü',
              ),
            ),
        ],
      ),
      drawer: isMobile
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
                        const Icon(Icons.person, color: Colors.white, size: 48),
                        const SizedBox(height: 8),
                        const Text(
                          'Hasta Paneli',
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.assignment),
                    title: const Text('Tahliller'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/user-tahlil-list');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Profil'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/user-profile');
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
                      Navigator.pushNamed(context, '/user-profile');
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
      body: FutureBuilder<Map<String, dynamic>?>(
        future: FirebaseService.getTahlilById(widget.tahlilId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Tahlil bulunamadı'));
          }

          final tahlil = TahlilModel.fromFirestore(snapshot.data!, widget.tahlilId);

          // Önceki tahlilleri yükle (sadece bir kez)
          if (!_previousTahlillerLoaded) {
            _previousTahlillerLoaded = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadPreviousTahliller(tahlil.tcNumber);
            });
          }

          return SingleChildScrollView(
            padding: EdgeInsets.only(
              left: isMobile ? 16 : 24,
              right: isMobile ? 16 : 24,
              top: isMobile ? 16 : 24,
              bottom: isMobile ? 80 : 24, // Bottom navigation bar için ekstra alan
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(context, 'Adı Soyadı', tahlil.fullName, Icons.person),
                _buildInfoCard(context, 'T.C. Kimlik No', tahlil.tcNumber, Icons.badge),
                _buildInfoCard(context, 'Yaş (Yıl)', tahlil.age.toString(), Icons.cake),
                _buildInfoCard(
                  context,
                  'Cinsiyet',
                  tahlil.gender.isEmpty ? '(Cinsiyet girilmemiş)' : tahlil.gender,
                  Icons.wc,
                ),
                _buildInfoCard(
                  context,
                  'Hastalık Tanısı',
                  tahlil.patientType.isEmpty ? '(Tanı girilmemiş)' : tahlil.patientType,
                  Icons.medical_information,
                ),
                _buildInfoCard(context, 'Numune Türü', tahlil.sampleType, Icons.science),
                const SizedBox(height: 20),
                const Text(
                  'Serum Değerleri',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0058A3)),
                ),
                const SizedBox(height: 10),
                if (_previousTahliller.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0058A3).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.trending_up, color: Color(0xFF0058A3), size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Değişim Analizi Aktif',
                          style: TextStyle(fontSize: 12, color: Color(0xFF0058A3), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                ...tahlil.serumTypes.map((serum) {
                  final serumValue = double.tryParse(serum.value) ?? 0.0;
                  final evaluation = _evaluateSerumForAge(tahlil, serum.type, serumValue);
                  final previousValue = _getPreviousSerumValue(serum.type, _previousTahliller);
                  final changeIndicator = _getChangeIndicator(serumValue, previousValue);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (evaluation != null)
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _getArrowColor(evaluation['arrow']!).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(color: _getArrowColor(evaluation['arrow']!), width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  evaluation['arrow']!,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _getArrowColor(evaluation['arrow']!),
                                  ),
                                ),
                              ),
                            ),
                          if (evaluation != null && previousValue != null) const SizedBox(width: 8),
                          if (previousValue != null)
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _getChangeColor(changeIndicator).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(color: _getChangeColor(changeIndicator), width: 2),
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
                            ),
                        ],
                      ),
                      title: Text(
                        '${serum.type}: ${serum.value} mg/dl',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (evaluation != null) ...[
                            Row(
                              children: [
                                Text(
                                  evaluation['arrow'] == '↔'
                                      ? 'Normal'
                                      : evaluation['arrow'] == '↓'
                                      ? 'Düşük'
                                      : 'Yüksek',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _getArrowColor(evaluation['arrow']!),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    '• Normal Aralık: ${evaluation['range']} mg/dl',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (previousValue != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Önceki: $previousValue mg/dl',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                            ),
                          ],
                        ],
                      ),
                      trailing: evaluation != null
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getArrowColor(evaluation['arrow']!).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    evaluation['arrow']!,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _getArrowColor(evaluation['arrow']!),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    evaluation['arrow'] == '↔'
                                        ? 'Normal'
                                        : evaluation['arrow'] == '↓'
                                        ? 'Düşük'
                                        : 'Yüksek',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: _getArrowColor(evaluation['arrow']!),
                                    ),
                                  ),
                                ],
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
          ? Builder(
              builder: (navContext) => UserBottomNavBar(
                currentIndex: 0,
                onTap: (index) {
                  if (index == 0) {
                    // Hamburger menüyü aç (soldan)
                    Scaffold.of(navContext).openDrawer();
                  } else if (index == 1) {
                    Navigator.pushNamed(context, '/user-profile');
                  }
                },
              ),
            )
          : null,
    );
  }

  // ignore: unused_element
  Future<void> _deleteTahlil() async {
    final tahlilData = await FirebaseService.getTahlilById(widget.tahlilId);
    if (tahlilData == null) return;

    final tahlilName = tahlilData['fullName'] ?? 'Tahlil';

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tahlili Sil'),
        content: Text('Bu tahlili silmek istediğinizden emin misiniz?\n\n$tahlilName\n\nBu işlem geri alınamaz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await FirebaseService.deleteTahlil(widget.tahlilId);

      if (success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tahlil başarıyla silindi.'), backgroundColor: Colors.green));
        // Tahlil listesine geri dön
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tahlil silinirken bir hata oluştu.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildInfoCard(BuildContext context, String label, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF0058A3).withValues(alpha: 0.1),
          child: Icon(icon, color: const Color(0xFF0058A3)),
        ),
        title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0058A3)),
        ),
      ),
    );
  }
}
