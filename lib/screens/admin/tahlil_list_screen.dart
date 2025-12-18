import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:provider/provider.dart';
import '../../models/tahlil_model.dart';
import '../../services/firebase_service.dart';
import '../../services/postgres_service.dart';
import '../../widgets/admin_bottom_nav_bar.dart';
import '../../providers/theme_provider.dart';
import 'admin_dashboard_screen.dart';
import 'admin_profile_screen.dart';
import 'kilavuz_screen.dart';
import 'kilavuz_list_screen.dart';
import 'tahlil_ekle_screen.dart';
import 'patient_tahlil_history_screen.dart';

class TahlilListScreen extends StatefulWidget {
  const TahlilListScreen({super.key});

  @override
  State<TahlilListScreen> createState() => _TahlilListScreenState();
}

class _TahlilListScreenState extends State<TahlilListScreen> {
  final _searchController = TextEditingController();
  List<TahlilModel> _allTahliller = [];
  List<TahlilModel> _filteredTahliller = [];
  String _sortOrder = 'desc'; // 'asc' veya 'desc'
  String? _selectedAgeCategory; // 'bebek', 'çocuk', 'erişkin', 'yaşlı'
  int _selectedNavIndex = 4; // NavigationRail için seçili index
  late Future<List<TahlilModel>> _tahlillerFuture;

  @override
  void initState() {
    super.initState();
    _tahlillerFuture = _loadAllTahliller();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<TahlilModel>> _loadAllTahliller() async {
    final dataList = await PostgresService.getAllTahliller();
    final tahliller = <TahlilModel>[];
    
    for (final data in dataList) {
      final detail = await FirebaseService.getTahlilById(data['id'] ?? '');
      final serumTypes = <SerumType>[];
      
      if (detail != null && detail['serumTypes'] != null) {
        for (final s in detail['serumTypes'] as List) {
          serumTypes.add(SerumType(type: s['type'] ?? '', value: s['value'] ?? ''));
        }
      }
      
      // Doğum tarihi ve yaş bilgilerini parse et
      DateTime? birthDate;
      if (data['birthDate'] != null) {
        birthDate = DateTime.tryParse(data['birthDate'].toString());
      }
      
      final age = data['age'] is int ? data['age'] as int : (data['age'] != null ? int.tryParse(data['age'].toString()) ?? 0 : 0);
      
      tahliller.add(TahlilModel(
        id: data['id']?.toString() ?? '',
        fullName: data['fullName'] ?? '',
        tcNumber: data['tcNumber'] ?? '',
        birthDate: birthDate,
        age: age,
        gender: data['gender']?.toString() ?? '',
        patientType: data['patientType']?.toString() ?? '',
        sampleType: data['sampleType']?.toString() ?? '',
        serumTypes: serumTypes,
        reportDate: data['reportDate'] ?? '',
      ));
    }
    
    return tahliller;
  }

  // Yaş kategorisini belirle
  String? _getAgeCategory(TahlilModel tahlil) {
    if (tahlil.birthDate != null) {
      final now = DateTime.now();
      final birthDate = tahlil.birthDate!;
      int years = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        years--;
      }
      
      if (years < 2) return 'bebek';
      if (years < 12) return 'çocuk';
      if (years < 65) return 'erişkin';
      return 'yaşlı';
    } else if (tahlil.age > 0) {
      // Doğum tarihi yoksa yaş bilgisini kullan
      if (tahlil.age < 2) return 'bebek';
      if (tahlil.age < 12) return 'çocuk';
      if (tahlil.age < 65) return 'erişkin';
      return 'yaşlı';
    }
    return null;
  }

  void _filterTahliller(String query) {
    setState(() {
      var filtered = List<TahlilModel>.from(_allTahliller);
      
      // Arama filtresi
      if (query.isNotEmpty) {
        filtered = filtered
            .where((tahlil) =>
                tahlil.fullName.toLowerCase().contains(query.toLowerCase()) ||
                tahlil.tcNumber.contains(query))
            .toList();
      }
      
      // Yaş kategorisi filtresi
      if (_selectedAgeCategory != null) {
        filtered = filtered
            .where((tahlil) => _getAgeCategory(tahlil) == _selectedAgeCategory)
            .toList();
      }
      
      _filteredTahliller = filtered;
      _sortTahliller();
    });
  }
  
  void _applyAgeCategoryFilter(String? category) {
    setState(() {
      _selectedAgeCategory = category;
      _filterTahliller(_searchController.text);
    });
  }

  void _sortTahliller() {
    setState(() {
      _sortTahlillerWithoutSetState();
    });
  }

  void _sortTahlillerWithoutSetState() {
      _filteredTahliller.sort((a, b) {
        // Tarih parse et (GG/AA/YYYY formatı)
        DateTime? dateA = _parseDate(a.reportDate);
        DateTime? dateB = _parseDate(b.reportDate);
        
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
      if (parts.length == 3) {
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

  Future<void> _deleteTahlil(TahlilModel tahlil) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tahlili Sil'),
        content: Text(
          'Bu tahlili silmek istediğinizden emin misiniz?\n\n'
          '${tahlil.fullName}\nTC: ${tahlil.tcNumber}\nTarih: ${tahlil.reportDate}\n\n'
          'Bu işlem geri alınamaz.',
        ),
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
      final success = await FirebaseService.deleteTahlil(tahlil.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tahlil başarıyla silindi.'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _allTahliller.removeWhere((item) => item.id == tahlil.id);
          _filteredTahliller.removeWhere((item) => item.id == tahlil.id);
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
          if (!isMobile)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  _allTahliller = [];
                  _filteredTahliller = [];
                  _tahlillerFuture = _loadAllTahliller();
                });
              },
              tooltip: 'Yenile',
            ),
        ],
      ),
      endDrawer: isMobile ? _buildAdminDrawer(context, isMobile) : null,
      body: Row(
        children: [
          if (!isMobile) _buildNavigationRail(context),
          Expanded(
            child: FutureBuilder<List<TahlilModel>>(
              future: _tahlillerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

                final data = snapshot.data ?? [];

                // İlk yüklemede state'i güncelle (postFrameCallback ile)
                if (_allTahliller.isEmpty && data.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _allTahliller = data;
            _filteredTahliller = List.from(_allTahliller);
                        _sortTahlillerWithoutSetState();
                      });
                    }
                  });
          }

                // Görüntüleme için mevcut filtered list'i kullan, yoksa data'yı kullan
                // displayList artık kullanılmıyor, _filteredTahliller veya _allTahliller kullanılıyor

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              labelText: 'İsim veya TC ile Ara',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onChanged: _filterTahliller,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: PopupMenuButton<String>(
                            icon: const Icon(Icons.sort),
                            tooltip: 'Sırala',
                            onSelected: (value) {
                              setState(() {
                                _sortOrder = value;
                                _sortTahliller();
                              });
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'desc',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.arrow_downward,
                                      size: 16,
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
                                      size: 16,
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
                    const SizedBox(height: 12),
                    // Yaş kategorisi filtreleri
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildAgeCategoryChip('Tümü', null),
                          const SizedBox(width: 8),
                          _buildAgeCategoryChip('Bebek (0-2 yaş)', 'bebek'),
                          const SizedBox(width: 8),
                          _buildAgeCategoryChip('Çocuk (2-12 yaş)', 'çocuk'),
                          const SizedBox(width: 8),
                          _buildAgeCategoryChip('Erişkin (12-65 yaş)', 'erişkin'),
                          const SizedBox(width: 8),
                          _buildAgeCategoryChip('Yaşlı (65+ yaş)', 'yaşlı'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _filteredTahliller.isEmpty && (_searchController.text.isNotEmpty || _selectedAgeCategory != null)
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Sonuç bulunamadı',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Arama kriterlerinizi değiştirip tekrar deneyin',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : _filteredTahliller.isEmpty && _allTahliller.isEmpty
                        ? const Center(child: Text('Tahlil bulunamadı'))
                        : ListView.builder(
                        padding: EdgeInsets.all(isMobile ? 16 : 24),
                        itemCount: _filteredTahliller.isEmpty ? _allTahliller.length : _filteredTahliller.length,
                        itemBuilder: (context, index) {
                          final displayList = _filteredTahliller.isEmpty ? _allTahliller : _filteredTahliller;
                          final tahlil = displayList[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFF0058A3),
                                child: Icon(Icons.assignment, color: Colors.white),
                              ),
                              title: Text(
                                tahlil.fullName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('Tarih: ${tahlil.reportDate}'),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete,
                                                      color: Colors.red,
                                                    ),
                                                    tooltip: 'Tahlili Sil',
                                                    onPressed: () => _deleteTahlil(tahlil),
                                                  ),
                                                  const Icon(Icons.chevron_right),
                                                ],
                                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PatientTahlilHistoryScreen(
                                      tcNumber: tahlil.tcNumber,
                                      patientName: tahlil.fullName,
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
                      MaterialPageRoute(
                        builder: (context) => const KilavuzScreen(),
                      ),
                    );
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TahlilEkleScreen(),
                      ),
                    ).then((_) {
                      // Tahlil ekleme ekranından dönüldüğünde listeyi yenile
                      setState(() {
                        _allTahliller = [];
                        _filteredTahliller = [];
                        _tahlillerFuture = _loadAllTahliller();
                      });
                    });
                    break;
                  case 4:
                    // Zaten bu sayfadayız
                    break;
                }
              },
            )
          : null,
    );
  }

  Widget _buildAgeCategoryChip(String label, String? category) {
    final isSelected = _selectedAgeCategory == category;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        _applyAgeCategoryFilter(selected ? category : null);
      },
      selectedColor: const Color(0xFF0058A3).withValues(alpha: 0.2),
      checkmarkColor: const Color(0xFF0058A3),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF0058A3) : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFF0058A3) : Colors.grey.shade300,
        width: isSelected ? 2 : 1,
      ),
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TahlilEkleScreen(),
              ),
            ).then((_) {
              // Tahlil ekleme ekranından dönüldüğünde listeyi yenile
              setState(() {
                _allTahliller = [];
                _filteredTahliller = [];
                _tahlillerFuture = _loadAllTahliller();
              });
            });
            break;
          case 4:
            // Zaten bu sayfadayız
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
                const Icon(
                  Icons.local_hospital,
                  color: Colors.white,
                  size: 48,
                ),
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
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const KilavuzScreen(),
                ),
              );
            },
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TahlilEkleScreen(),
                ),
              ).then((_) {
                // Tahlil ekleme ekranından dönüldüğünde listeyi yenile
                setState(() {
                  _allTahliller = [];
                  _filteredTahliller = [];
                  _tahlillerFuture = _loadAllTahliller();
                });
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('Tahlil Listesi'),
            selected: true,
            selectedTileColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            onTap: () => Navigator.pop(context),
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
    );
  }
}

