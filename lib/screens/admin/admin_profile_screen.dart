import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:provider/provider.dart';
import '../../services/firebase_service.dart';
import '../../widgets/admin_bottom_nav_bar.dart';
import '../../providers/theme_provider.dart';
import 'admin_dashboard_screen.dart';
import 'kilavuz_screen.dart';
import 'kilavuz_list_screen.dart';
import 'tahlil_ekle_screen.dart';
import 'tahlil_list_screen.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _tcNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isEditing = false;
  bool _isEditingEmail = false;
  bool _isEditingFullName = false;
  bool _isEditingTC = false;
  bool _isEditingPassword = false;
  String _createdAt = '';
  String _updatedAt = '';
  int _selectedNavIndex = 5; // NavigationRail için seçili index

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _fullNameController.dispose();
    _tcNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);

    final adminInfo = await FirebaseService.getAdminInfo();

    if (adminInfo != null && mounted) {
      setState(() {
        _emailController.text = adminInfo['email'] ?? '';
        _fullNameController.text = adminInfo['fullName'] ?? '';
        _tcNumberController.text = adminInfo['tcNumber'] ?? '';
        _createdAt = adminInfo['created_at'] ?? '';
        _updatedAt = adminInfo['updated_at'] ?? '';
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil bilgileri yüklenemedi')));
    }
  }

  Future<void> _updateProfile() async {
    // Validasyon
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('E-posta adresi boş olamaz')));
      return;
    }

    if (!_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Geçerli bir e-posta adresi giriniz')));
      return;
    }

    if (_fullNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ad Soyad boş olamaz')));
      return;
    }

    if (_tcNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('TC Kimlik No boş olamaz')));
      return;
    }

    if (_tcNumberController.text.trim().length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('TC Kimlik No 11 haneli olmalıdır')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await FirebaseService.updateAdminInfo(
        email: _emailController.text.trim(),
        fullName: _fullNameController.text.trim(),
        tcNumber: _tcNumberController.text.trim(),
      );

      if (!mounted) return;

      // Şifre güncellemesi varsa
      if (_passwordController.text.isNotEmpty) {
        if (_passwordController.text.length < 6) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Şifre en az 6 karakter olmalıdır')));
          setState(() => _isLoading = false);
          return;
        }
        await FirebaseService.updateAdminPassword(_passwordController.text);
        _passwordController.clear();
      }

      setState(() {
        _isLoading = false;
        _isEditing = false;
        _isEditingEmail = false;
        _isEditingFullName = false;
        _isEditingTC = false;
        _isEditingPassword = false;
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bilgileriniz başarıyla güncellendi')));
        await _loadAdminData(); // Güncel bilgileri yeniden yükle
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Bilgiler güncellenirken bir hata oluştu')));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Scaffold(
      appBar: AppBar(
        title: isMobile
            ? const Align(alignment: Alignment.centerLeft, child: Text('Profil Ayarları'))
            : const Text('Profil Ayarları'),
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
            child: _isLoading && !_isEditing
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profil Başlığı
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF0058A3), Color(0xFF00A8E8)]),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0058A3).withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.local_hospital, color: Colors.white, size: 40),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Doktor Profili',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _fullNameController.text.isEmpty ? 'Yükleniyor...' : _fullNameController.text,
                                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Ayarlar
                          const Text(
                            'Ayarlar',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0058A3)),
                          ),
                          const SizedBox(height: 20),

                          // E-posta
                          _buildEditableFieldWithIcon(
                            label: 'E-posta',
                            icon: Icons.email,
                            controller: _emailController,
                            isEditing: _isEditingEmail,
                            keyboardType: TextInputType.emailAddress,
                            onEditToggle: () {
                              setState(() {
                                _isEditingEmail = !_isEditingEmail;
                                if (!_isEditingEmail) {
                                  _loadAdminData(); // Orijinal değere geri dön
                                }
                              });
                            },
                          ),

                          const SizedBox(height: 16),

                          // Ad Soyad
                          _buildEditableFieldWithIcon(
                            label: 'Ad Soyad',
                            icon: Icons.person,
                            controller: _fullNameController,
                            isEditing: _isEditingFullName,
                            onEditToggle: () {
                              setState(() {
                                _isEditingFullName = !_isEditingFullName;
                                if (!_isEditingFullName) {
                                  _loadAdminData(); // Orijinal değere geri dön
                                }
                              });
                            },
                          ),

                          const SizedBox(height: 16),

                          // TC Kimlik No
                          _buildEditableFieldWithIcon(
                            label: 'TC Kimlik No',
                            icon: Icons.badge,
                            controller: _tcNumberController,
                            isEditing: _isEditingTC,
                            keyboardType: TextInputType.number,
                            maxLength: 11,
                            onEditToggle: () {
                              setState(() {
                                _isEditingTC = !_isEditingTC;
                                if (!_isEditingTC) {
                                  _loadAdminData(); // Orijinal değere geri dön
                                }
                              });
                            },
                          ),

                          const SizedBox(height: 16),

                          // Şifre
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.lock, color: Color(0xFF0058A3), size: 20),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Şifre',
                                        style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: Icon(
                                          _isEditingPassword ? Icons.check : Icons.edit,
                                          color: Colors.green,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isEditingPassword = !_isEditingPassword;
                                            if (!_isEditingPassword) {
                                              _passwordController.clear();
                                            }
                                          });
                                        },
                                        tooltip: _isEditingPassword ? 'Kaydet' : 'Düzenle',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _passwordController,
                                    enabled: _isEditingPassword,
                                    obscureText: _isEditingPassword,
                                    decoration: InputDecoration(
                                      hintText: _isEditingPassword
                                          ? 'Yeni şifrenizi girin'
                                          : 'Şifre değiştirmek için düzenle',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      prefixIcon: const Icon(Icons.lock),
                                      filled: true,
                                      // Koyu modda beyaz yerine daha koyu bir arka plan kullan
                                      fillColor: _isEditingPassword
                                          ? null
                                          : (Theme.of(context).brightness == Brightness.dark
                                                ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.8)
                                                : Colors.grey[100]),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Tema Değiştir
                          Consumer<ThemeProvider>(
                            builder: (context, themeProvider, _) {
                              return InkWell(
                                onTap: () {
                                  themeProvider.toggleTheme();
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  decoration: BoxDecoration(
                                    // Tema butonu için arka planı temaya göre ayarla
                                    color: themeProvider.isDarkMode
                                        ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.9)
                                        : Colors.white,
                                    border: Border.all(color: const Color(0xFF0058A3), width: 1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                                        color: const Color(0xFF0058A3),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        themeProvider.isDarkMode ? 'Açık Mod' : 'Koyu Mod',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Color(0xFF0058A3),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 30),

                          // Bilgilerimi Güncelle Butonu
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _updateProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Bilgilerimi Güncelle',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                            ),
                          ),

                          // Tarih Bilgileri (En Altta, Daha Az Belirgin)
                          if ((_createdAt.isNotEmpty || _updatedAt.isNotEmpty)) ...[
                            const SizedBox(height: 40),
                            const Divider(),
                            const SizedBox(height: 20),
                            if (_createdAt.isNotEmpty)
                              _buildSubtleInfoRow('Hesap Oluşturulma', _formatDate(_createdAt), Icons.calendar_today),
                            if (_createdAt.isNotEmpty && _updatedAt.isNotEmpty) const SizedBox(height: 8),
                            if (_updatedAt.isNotEmpty)
                              _buildSubtleInfoRow('Son Güncelleme', _formatDate(_updatedAt), Icons.update),
                          ],

                          // Çıkış Yap Butonu (En Altta)
                          ...[
                            const SizedBox(height: 40),
                            const Divider(),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Çıkış Yap'),
                                      content: const Text('Çıkış yapmak istediğinizden emin misiniz?'),
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
                                          child: const Text('Çıkış Yap'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true && context.mounted) {
                                    await FirebaseService.signOut();
                                    if (context.mounted) {
                                      Navigator.pushReplacementNamed(context, '/');
                                    }
                                  }
                                },
                                icon: const Icon(Icons.logout, color: Colors.red),
                                label: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: isMobile
          ? AdminBottomNavBar(
              currentIndex: 5, // Profil sayfası için geçersiz index (hiçbir öğe seçili değil)
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
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TahlilEkleScreen()));
            break;
          case 4:
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TahlilListScreen()));
            break;
          case 5:
            // Zaten bu sayfadayız
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
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Profil Ayarları'),
            selected: true,
            selectedTileColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            onTap: () => Navigator.pop(context),
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

  Widget _buildEditableFieldWithIcon({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required bool isEditing,
    required VoidCallback onEditToggle,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF0058A3), size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(isEditing ? Icons.check : Icons.edit, color: Colors.green, size: 20),
                  onPressed: onEditToggle,
                  tooltip: isEditing ? 'Kaydet' : 'Düzenle',
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              enabled: isEditing,
              keyboardType: keyboardType,
              maxLength: maxLength,
              decoration: InputDecoration(
                hintText: '$label girin',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: Icon(icon, color: theme.colorScheme.primary),
                counterText: maxLength != null ? null : '',
                // Düzenleme modunda değilken bile, koyu modda beyaz yerine
                // kart arka planına yakın koyu bir renk kullan.
                filled: true,
                fillColor: isEditing
                    ? null
                    : (isDark ? theme.colorScheme.surface.withValues(alpha: 0.7) : Colors.grey[100]),
              ),
              // Varsayılan tema metin renklerini kullan
              style: null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtleInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          Text(value, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}
