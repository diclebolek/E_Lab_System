import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:provider/provider.dart';
import '../../services/firebase_service.dart';
import '../../widgets/user_bottom_nav_bar.dart';
import '../../providers/theme_provider.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _fullNameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _ageController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  bool _isLoading = false;
  String _tcNumber = '';
  String? _gender;
  String? _bloodType;
  DateTime? _birthDate;
  String _createdAt = '';
  String _updatedAt = '';
  int _selectedNavIndex = 1; // NavigationRail için seçili index

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _birthDateController.dispose();
    _ageController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    final userInfo = await FirebaseService.getUserInfo();

    if (userInfo != null && mounted) {
      setState(() {
        _tcNumber = userInfo['tcNumber'] ?? '';
        _fullNameController.text = userInfo['fullName'] ?? '';
        _gender = userInfo['gender'];
        _bloodType = userInfo['bloodType'];
        _ageController.text = userInfo['age']?.toString() ?? '';
        _emergencyContactController.text = userInfo['emergencyContact'] ?? '';

        if (userInfo['birthDate'] != null) {
          _birthDate = DateTime.tryParse(userInfo['birthDate']);
          if (_birthDate != null) {
            _birthDateController.text = '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}';
          }
        }

        _createdAt = userInfo['created_at'] ?? '';
        _updatedAt = userInfo['updated_at'] ?? '';
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil bilgileri yüklenemedi')));
    }
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('tr', 'TR'),
    );

    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _birthDateController.text = '${picked.day}/${picked.month}/${picked.year}';
        // Yaşı otomatik hesapla
        final age = DateTime.now().year - picked.year;
        if (DateTime.now().month < picked.month ||
            (DateTime.now().month == picked.month && DateTime.now().day < picked.day)) {
          _ageController.text = (age - 1).toString();
        } else {
          _ageController.text = age.toString();
        }
      });
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);

    try {
      int? age;
      if (_ageController.text.isNotEmpty) {
        age = int.tryParse(_ageController.text);
        if (age == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Geçerli bir yaş giriniz')));
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      final success = await FirebaseService.updateUserInfo(
        fullName: _fullNameController.text.trim().isEmpty ? null : _fullNameController.text.trim(),
        birthDate: _birthDate,
        age: age,
        gender: _gender,
        bloodType: _bloodType,
        emergencyContact: _emergencyContactController.text.trim().isEmpty
            ? null
            : _emergencyContactController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil bilgileri başarıyla güncellendi'), backgroundColor: Colors.green),
        );
        await _loadUserData(); // Güncel bilgileri yeniden yükle
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil güncellenirken bir hata oluştu'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: ${e.toString()}')));
      }
    }
  }

  // Şifre değiştirme dialog
  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isChanging = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock_outline, color: Color(0xFF0058A3)),
              SizedBox(width: 8),
              Text('Şifre Değiştir'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Mevcut Şifre',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Yeni Şifre',
                    prefixIcon: const Icon(Icons.lock_open),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    helperText: 'En az 6 karakter',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Yeni Şifre (Tekrar)',
                    prefixIcon: const Icon(Icons.lock_open),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
            ElevatedButton(
              onPressed: isChanging
                  ? null
                  : () async {
                      if (newPasswordController.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Yeni şifre en az 6 karakter olmalıdır'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }
                      if (newPasswordController.text != confirmPasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Yeni şifreler eşleşmiyor'), backgroundColor: Colors.orange),
                        );
                        return;
                      }

                      setDialogState(() => isChanging = true);

                      final success = await FirebaseService.changePassword(
                        currentPasswordController.text,
                        newPasswordController.text,
                      );

                      setDialogState(() => isChanging = false);

                      if (!mounted) return;

                      if (success) {
                        Navigator.pop(this.context);
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text('Şifreniz başarıyla değiştirildi'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text('Şifre değiştirilemedi. Mevcut şifrenizi kontrol edin.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0058A3), foregroundColor: Colors.white),
              child: isChanging
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Şifreyi Değiştir'),
            ),
          ],
        ),
      ),
    );

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesabı Sil'),
        content: const Text('Hesabınızı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hayır')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Evet', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      final success = await FirebaseService.deleteAccount();

      setState(() => _isLoading = false);

      if (success && mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hesap silinirken bir hata oluştu.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Scaffold(
      appBar: AppBar(
        title: isMobile
            ? const Align(alignment: Alignment.centerLeft, child: Text('Profil Yönetimi'))
            : const Text('Profil Yönetimi'),
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
                      Navigator.pushReplacementNamed(context, '/user-tahlil-list');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Profil'),
                    selected: true,
                    selectedTileColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    onTap: () => Navigator.pop(context),
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
            )
          : null,
      body: Row(
        children: [
          if (!isMobile) _buildNavigationRail(context),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: isMobile ? 16 : 24,
                      right: isMobile ? 16 : 24,
                      top: isMobile ? 16 : 8,
                      bottom: isMobile ? 80 : 24, // Bottom navigation bar için ekstra alan
                    ),
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
                                  child: const Icon(Icons.person, color: Colors.white, size: 40),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Hasta Profili',
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

                          // Profil Bilgileri
                          const Text(
                            'Profil Bilgileri',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0058A3)),
                          ),
                          const SizedBox(height: 16),

                          // T.C. Kimlik Numarası (Sadece Görüntüleme)
                          _buildInfoCard(
                            'T.C. Kimlik Numarası',
                            _tcNumber.isEmpty ? 'Yükleniyor...' : _tcNumber,
                            Icons.badge,
                          ),

                          const SizedBox(height: 16),

                          // Ad Soyad
                          _buildEditableCard(
                            label: 'Ad Soyad',
                            icon: Icons.person,
                            child: TextField(
                              controller: _fullNameController,
                              decoration: InputDecoration(
                                hintText: 'Adınızı ve soyadınızı girin',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[900]
                                    : null,
                                prefixIcon: const Icon(Icons.person),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Doğum Tarihi
                          _buildEditableCard(
                            label: 'Doğum Tarihi',
                            icon: Icons.calendar_today,
                            child: TextField(
                              controller: _birthDateController,
                              readOnly: true,
                              decoration: InputDecoration(
                                hintText: 'Doğum tarihinizi seçin',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[900]
                                    : null,
                                prefixIcon: const Icon(Icons.calendar_today),
                                suffixIcon: IconButton(icon: const Icon(Icons.date_range), onPressed: _selectBirthDate),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Yaş
                          _buildEditableCard(
                            label: 'Yaş',
                            icon: Icons.cake,
                            child: TextField(
                              controller: _ageController,
                              decoration: InputDecoration(
                                hintText: 'Yaşınızı girin',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[900]
                                    : null,
                                prefixIcon: const Icon(Icons.cake),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Cinsiyet
                          _buildEditableCard(
                            label: 'Cinsiyet',
                            icon: Icons.wc,
                            child: DropdownButtonFormField<String>(
                              initialValue: _gender,
                              decoration: InputDecoration(
                                hintText: 'Cinsiyet seçin',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[900]
                                    : null,
                                prefixIcon: const Icon(Icons.wc),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'Erkek', child: Text('Erkek')),
                                DropdownMenuItem(value: 'Kadın', child: Text('Kadın')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _gender = value;
                                });
                              },
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Kan Grubu
                          _buildEditableCard(
                            label: 'Kan Grubu',
                            icon: Icons.bloodtype,
                            child: DropdownButtonFormField<String>(
                              initialValue: _bloodType,
                              decoration: InputDecoration(
                                hintText: 'Kan grubunuzu seçin',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[900]
                                    : null,
                                prefixIcon: const Icon(Icons.bloodtype),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'A+', child: Text('A+')),
                                DropdownMenuItem(value: 'A-', child: Text('A-')),
                                DropdownMenuItem(value: 'B+', child: Text('B+')),
                                DropdownMenuItem(value: 'B-', child: Text('B-')),
                                DropdownMenuItem(value: 'AB+', child: Text('AB+')),
                                DropdownMenuItem(value: 'AB-', child: Text('AB-')),
                                DropdownMenuItem(value: '0+', child: Text('0+')),
                                DropdownMenuItem(value: '0-', child: Text('0-')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _bloodType = value;
                                });
                              },
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Acil Durum İçin Yedek Telefon
                          _buildEditableCard(
                            label: 'Acil Durum İçin Yedek Telefon',
                            icon: Icons.phone,
                            child: TextField(
                              controller: _emergencyContactController,
                              decoration: InputDecoration(
                                hintText: 'Acil durum telefon numaranızı girin',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[900]
                                    : null,
                                prefixIcon: const Icon(Icons.phone),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Ayarlar
                          const Text(
                            'Ayarlar',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0058A3)),
                          ),
                          const SizedBox(height: 20),

                          // Tema Değiştir
                          Consumer<ThemeProvider>(
                            builder: (context, themeProvider, _) {
                              return SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    themeProvider.toggleTheme();
                                  },
                                  icon: Icon(
                                    themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                                    color: const Color(0xFF0058A3),
                                  ),
                                  label: Text(
                                    themeProvider.isDarkMode ? 'Açık Mod' : 'Koyu Mod',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF0058A3),
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    side: const BorderSide(color: Color(0xFF0058A3)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                backgroundColor: const Color(0xFF0058A3),
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

                          const SizedBox(height: 20),

                          // Şifre Değiştir Butonu
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _showChangePasswordDialog,
                              icon: const Icon(Icons.lock_outline, color: Color(0xFF0058A3)),
                              label: const Text(
                                'Şifre Değiştir',
                                style: TextStyle(fontSize: 16, color: Color(0xFF0058A3)),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(color: Color(0xFF0058A3)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),
                          const Divider(),
                          const SizedBox(height: 20),

                          // Çıkış Yap Butonu
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

                          const SizedBox(height: 16),

                          // Hesabımı Sil Butonu
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _deleteAccount,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text(
                                'Hesabımı Sil',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),

                          // Tarih Bilgileri (En Altta, Daha Az Belirgin)
                          if (_createdAt.isNotEmpty || _updatedAt.isNotEmpty) ...[
                            const SizedBox(height: 40),
                            const Divider(),
                            const SizedBox(height: 20),
                            if (_createdAt.isNotEmpty)
                              _buildSubtleInfoRow('Hesap Oluşturulma', _formatDate(_createdAt), Icons.calendar_today),
                            if (_createdAt.isNotEmpty && _updatedAt.isNotEmpty) const SizedBox(height: 8),
                            if (_updatedAt.isNotEmpty)
                              _buildSubtleInfoRow('Son Güncelleme', _formatDate(_updatedAt), Icons.update),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: isMobile
          ? Builder(
              builder: (navContext) => UserBottomNavBar(
                currentIndex: 1,
                onTap: (index) {
                  if (index == 0) {
                    // Tahlil listesine git
                    Navigator.pushReplacementNamed(context, '/user-tahlil-list');
                  } else if (index == 1) {
                    // Zaten profil sayfasındayız
                  }
                },
              ),
            )
          : null,
    );
  }

  Widget _buildEditableCard({required String label, required IconData icon, required Widget child}) {
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
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF0058A3).withValues(alpha: 0.1),
          child: Icon(icon, color: const Color(0xFF0058A3), size: 20),
        ),
        title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0058A3)),
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
            Navigator.pushReplacementNamed(context, '/user-tahlil-list');
            break;
          case 1:
            // Zaten bu sayfadayız
            break;
        }
      },
    );
  }
}
