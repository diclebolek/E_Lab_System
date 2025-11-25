import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../lib/models/tahlil_model.dart';
import '../../lib/services/firebase_service.dart';
import '../../lib/widgets/theme_toggle_button.dart';
import '../../lib/widgets/admin_bottom_nav_bar.dart';
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
        title: const Text('Tahlil Detayı'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0058A3), Color(0xFF00A8E8)],
            ),
          ),
        ),
        actions: const [ThemeToggleButton()],
      ),
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
          
          // Önceki tahlilleri yükle
          _loadPreviousTahliller(tahlil.tcNumber);

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard('Adı Soyadı', tahlil.fullName, Icons.person),
                _buildInfoCard('T.C. Kimlik No', tahlil.tcNumber, Icons.badge),
                _buildInfoCard('Yaş (Yıl)', tahlil.age.toString(), Icons.cake),
                _buildInfoCard('Cinsiyet', tahlil.gender, Icons.wc),
                _buildEditableInfoCard('Hastalık Tanısı', tahlil.patientType, Icons.local_hospital, widget.tahlilId),
                _buildInfoCard('Numune Türü', tahlil.sampleType, Icons.science),
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
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0058A3),
          ),
        ),
      ),
    );
  }

  Widget _buildEditableInfoCard(String label, String value, IconData icon, String tahlilId) {
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
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                value.isEmpty ? '(Tanı girilmemiş)' : value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0058A3),
                  fontStyle: value.isEmpty ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              color: const Color(0xFF0058A3),
              onPressed: () => _showEditDiagnosisDialog(tahlilId, value),
              tooltip: 'Düzenle',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDiagnosisDialog(String tahlilId, String currentValue) async {
    final TextEditingController controller = TextEditingController(text: currentValue);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hastalık Tanısı Düzenle'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Hastalık Tanısı',
            hintText: 'Hastalık tanısını girin',
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0058A3),
            ),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (result != null && result != currentValue) {
      // Tahlili güncelle
      final success = await FirebaseService.updateTahlil(
        tahlilId,
        {'patientType': result},
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hastalık tanısı başarıyla güncellendi!')),
        );
        // Sayfayı yenile
        setState(() {});
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Güncelleme sırasında bir hata oluştu!')),
        );
      }
    }
  }
}

