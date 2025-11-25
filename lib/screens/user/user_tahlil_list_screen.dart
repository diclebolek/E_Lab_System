import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/tahlil_model.dart';
import '../../services/firebase_service.dart';
import '../../widgets/user_bottom_nav_bar.dart';
import '../../providers/theme_provider.dart';

class UserTahlilListScreen extends StatefulWidget {
  const UserTahlilListScreen({super.key});

  @override
  State<UserTahlilListScreen> createState() => _UserTahlilListScreenState();
}

class _UserTahlilListScreenState extends State<UserTahlilListScreen> {
  String _sortOrder = 'desc'; // 'asc' veya 'desc'
  int _refreshKey = 0; // Listeyi yenilemek için key

  String _userTC = '';
  bool _isLoading = true;
  int _selectedNavIndex = 0; // NavigationRail için seçili index

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Scaffold(
      appBar: AppBar(
        title: isMobile
            ? const Align(
                alignment: Alignment.centerLeft,
                child: Text('Tahlil Listesi'),
              )
            : const Text('Tahlil Listesi'),
        automaticallyImplyLeading: false,
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
      body: Row(
        children: [
          if (!isMobile) _buildNavigationRail(context),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : FutureBuilder<List<TahlilModel>>(
              key: ValueKey(_refreshKey),
              future: _loadTahliller(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Hata: ${snapshot.error}'));
                }

                List<TahlilModel> tahliller = snapshot.data ?? [];

                final sortedTahliller = _sortTahliller(tahliller);

                if (sortedTahliller.isEmpty) {
                  return Center(
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
                  );
                }

                return Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.only(
                          left: isMobile ? 16 : 24,
                          right: isMobile ? 16 : 24,
                          top: 16,
                          bottom: isMobile ? 80 : 24, // Bottom navigation bar için ekstra alan
                        ),
                        itemCount: sortedTahliller.length,
                        itemBuilder: (context, index) {
                          final tahlil = sortedTahliller[index];
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
                );
              },
            ),
          ),
        ],
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
          icon: Icon(Icons.assignment),
          selectedIcon: Icon(Icons.assignment),
          label: Text('Tahliller'),
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
            // Zaten bu sayfadayız
            break;
          case 1:
            Navigator.pushReplacementNamed(context, '/user-profile');
            break;
        }
      },
    );
  }
}
