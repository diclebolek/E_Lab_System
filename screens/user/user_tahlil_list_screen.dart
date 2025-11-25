import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/models/tahlil_model.dart';
import '../../lib/services/firebase_service.dart';
import '../../lib/widgets/theme_toggle_button.dart';
import '../../lib/widgets/user_bottom_nav_bar.dart';
import '../../lib/providers/theme_provider.dart';

class UserTahlilListScreen extends StatefulWidget {
  const UserTahlilListScreen({super.key});

  @override
  State<UserTahlilListScreen> createState() => _UserTahlilListScreenState();
}

class _UserTahlilListScreenState extends State<UserTahlilListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortOrder = 'desc'; // 'asc' veya 'desc'
  int _refreshKey = 0; // Listeyi yenilemek için key

  String _userTC = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserTC();
  }

  Future<void> _loadUserTC() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userTC = prefs.getString('user_tc') ?? '';
      _isLoading = false;
    });
  }

  Future<List<TahlilModel>> _loadTahliller() async {
    if (_userTC.isEmpty) return [];

    final dataListStream = FirebaseService.getTahlillerByTC(_userTC);
    final dataList = <Map<String, dynamic>>[];
    await for (final data in dataListStream) {
      dataList.add(data as Map<String, dynamic>);
    }
    final tahliller = <TahlilModel>[];

    for (final data in dataList) {
      final detail = await FirebaseService.getTahlilById(data['id'] ?? '');
      final serumTypes = <SerumType>[];

      if (detail != null && detail['serumTypes'] != null) {
        for (final s in detail['serumTypes'] as List) {
          serumTypes.add(
            SerumType(type: s['type'] ?? '', value: s['value'] ?? ''),
          );
        }
      }

      // Yaş değerini güvenli şekilde dönüştür
      int age = 0;
      if (data['age'] != null) {
        if (data['age'] is int) {
          age = data['age'] as int;
        } else if (data['age'] is String) {
          age = int.tryParse(data['age'] as String) ?? 0;
        } else if (data['age'] is num) {
          age = (data['age'] as num).toInt();
        }
      }

      tahliller.add(
        TahlilModel(
          id: data['id']?.toString() ?? '',
          fullName: data['fullName'] ?? '',
          tcNumber: data['tcNumber'] ?? '',
          birthDate: data['birthDate'] != null
              ? DateTime.tryParse(data['birthDate'].toString())
              : null,
          age: age,
          gender: data['gender'] ?? '',
          patientType: data['patientType'] ?? '',
          sampleType: data['sampleType'] ?? '',
          serumTypes: serumTypes,
          reportDate: data['reportDate'] ?? '',
        ),
      );
    }

    return tahliller;
  }

  List<TahlilModel> _filterTahliller(
    List<TahlilModel> tahliller,
    String query,
  ) {
    if (query.isEmpty) return tahliller;

    final lowerQuery = query.toLowerCase();
    return tahliller.where((tahlil) {
      // İsim ile arama
      if (tahlil.fullName.toLowerCase().contains(lowerQuery)) return true;

      // Serum değerleri ile arama (tip veya değer)
      for (var serum in tahlil.serumTypes) {
        if (serum.type.toLowerCase().contains(lowerQuery) ||
            serum.value.toLowerCase().contains(lowerQuery)) {
          return true;
        }
      }

      return false;
    }).toList();
  }

  List<TahlilModel> _sortTahliller(List<TahlilModel> tahliller) {
    final sorted = List<TahlilModel>.from(tahliller);
    sorted.sort((a, b) {
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
    return sorted;
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

  Future<void> _deleteTahlil(String tahlilId, String tahlilName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tahlili Sil'),
        content: Text('Bu tahlili silmek istediğinizden emin misiniz?\n\n$tahlilName\n\nBu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await FirebaseService.deleteTahlil(tahlilId);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tahlil başarıyla silindi.'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _refreshKey++; // Listeyi yenile
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tahlil silinirken bir hata oluştu.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tahlil Listesi'),
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
          if (!isMobile) const ThemeToggleButton(),
          if (!isMobile)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await FirebaseService.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/');
                }
              },
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
                    leading: const Icon(Icons.assignment),
                    title: const Text('Tahliller'),
                    selected: true,
                    selectedTileColor: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    onTap: () => Navigator.pop(context),
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
                        leading: Icon(
                          themeProvider.isDarkMode
                              ? Icons.light_mode
                              : Icons.dark_mode,
                        ),
                        title: Text(
                          themeProvider.isDarkMode ? 'Açık Mod' : 'Koyu Mod',
                        ),
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
                    title: const Text(
                      'Çıkış Yap',
                      style: TextStyle(color: Colors.red),
                    ),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<TahlilModel>>(
              future: _loadTahliller(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Hata: ${snapshot.error}'));
                }

                List<TahlilModel> tahliller = snapshot.data ?? [];

                final filteredTahliller = _sortTahliller(
                  _filterTahliller(tahliller, _searchQuery),
                );

                if (filteredTahliller.isEmpty && tahliller.isNotEmpty) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: 'Serum Değeri veya İsim ile Ara',
                            hintText: 'Örn: IgG, IgA, IgM veya hasta adı',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                      const Expanded(
                        child: Center(child: Text('Arama sonucu bulunamadı')),
                      ),
                    ],
                  );
                }

                if (filteredTahliller.isEmpty) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: 'Serum Değeri veya İsim ile Ara',
                            hintText: 'Örn: IgG, IgA, IgM veya hasta adı',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assignment_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Henüz tahlil bulunmamaktadır',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                labelText: 'Serum Değeri veya İsim ile Ara',
                                hintText: 'Örn: IgG, IgA, IgM',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: PopupMenuButton<String>(
                              icon: const Icon(Icons.sort),
                              tooltip: 'Tarihe Göre Sırala',
                              onSelected: (value) {
                                setState(() {
                                  _sortOrder = value;
                                });
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'desc',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.arrow_downward,
                                        size: 18,
                                        color: _sortOrder == 'desc'
                                            ? const Color(0xFF0058A3)
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('Yeni → Eski'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'asc',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.arrow_upward,
                                        size: 18,
                                        color: _sortOrder == 'asc'
                                            ? const Color(0xFF0058A3)
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('Eski → Yeni'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.all(isMobile ? 16 : 24),
                        itemCount: filteredTahliller.length,
                        itemBuilder: (context, index) {
                          final tahlil = filteredTahliller[index];
                          return Card(
                            margin: EdgeInsets.only(
                              bottom: 16,
                              left: isMobile ? 0 : 8,
                              right: isMobile ? 0 : 8,
                            ),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: InkWell(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/user-tahlil-detail',
                                  arguments: {'tahlilId': tahlil.id},
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white,
                                      const Color(
                                        0xFF0058A3,
                                      ).withValues(alpha: 0.02),
                                    ],
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFF0058A3),
                                                Color(0xFF00A8E8),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFF0058A3,
                                                ).withValues(alpha: 0.3),
                                                blurRadius: 12,
                                                offset: const Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.assignment,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                tahlil.fullName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                  color: Color(0xFF0058A3),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              if (tahlil.patientType.isNotEmpty) ...[
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.medical_information,
                                                      size: 14,
                                                      color: Colors.grey[600],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        tahlil.patientType,
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: Colors.grey[700],
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                              ],
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.calendar_today,
                                                    size: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    tahlil.reportDate,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red,
                                                size: 24,
                                              ),
                                              onPressed: () => _deleteTahlil(tahlil.id, tahlil.fullName),
                                              tooltip: 'Tahlili Sil',
                                            ),
                                          ],
                                        ),
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
                                            Icons.chevron_right,
                                            color: Color(0xFF0058A3),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (tahlil.serumTypes.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      const Divider(),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: tahlil.serumTypes.take(4).map(
                                          (serum) {
                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFF00A8E8,
                                                ).withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFF00A8E8,
                                                  ).withValues(alpha: 0.3),
                                                ),
                                              ),
                                              child: Text(
                                                '${serum.type}: ${serum.value}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF0058A3),
                                                ),
                                              ),
                                            );
                                          },
                                        ).toList(),
                                      ),
                                      if (tahlil.serumTypes.length > 4)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: Text(
                                            '+${tahlil.serumTypes.length - 4} daha',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
      bottomNavigationBar: isMobile
          ? UserBottomNavBar(
              currentIndex: 0,
              onTap: (index) {
                if (index == 0) {
                  // Hamburger menüyü aç (soldan)
                  Scaffold.of(context).openDrawer();
                } else if (index == 1) {
                  Navigator.pushNamed(context, '/user-profile');
                }
              },
            )
          : null,
    );
  }
}
