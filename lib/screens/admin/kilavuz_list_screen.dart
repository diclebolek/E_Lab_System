import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:provider/provider.dart';
import '../../services/firebase_service.dart';
import '../../widgets/admin_bottom_nav_bar.dart';
import '../../providers/theme_provider.dart';
import 'admin_dashboard_screen.dart';
import 'admin_profile_screen.dart';
import 'kilavuz_screen.dart';
import 'tahlil_ekle_screen.dart';
import 'tahlil_list_screen.dart';

class KilavuzListScreen extends StatefulWidget {
  const KilavuzListScreen({super.key});

  @override
  State<KilavuzListScreen> createState() => _KilavuzListScreenState();
}

class _KilavuzListScreenState extends State<KilavuzListScreen> {
  List<Map<String, dynamic>> _guides = [];
  bool _isLoading = true;
  int _selectedNavIndex = 2; // NavigationRail için seçili index

  @override
  void initState() {
    super.initState();
    _loadGuides();
  }

  Future<void> _loadGuides() async {
    setState(() => _isLoading = true);
    try {
      final guidesList = <Map<String, dynamic>>[];
      await for (var guide in FirebaseService.getGuides()) {
        guidesList.add(guide as Map<String, dynamic>);
      }
      setState(() {
        _guides = guidesList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _guides = [];
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
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
                child: Text('Kılavuz Listesi'),
              )
            : const Text('Kılavuz Listesi'),
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
          if (!isMobile)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadGuides,
              tooltip: 'Yenile',
            ),
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _guides.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.book_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Henüz kılavuz bulunmamaktadır',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Yeni kılavuz oluşturmak için "Kılavuz Oluştur" sayfasına gidin',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const KilavuzScreen(),
                              ),
                            ).then((_) => _loadGuides());
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Yeni Kılavuz Oluştur'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0058A3),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadGuides,
                    child: ListView.builder(
                      padding: EdgeInsets.all(isMobile ? 16 : 24),
                      itemCount: _guides.length,
                      itemBuilder: (context, index) {
                        final guide = _guides[index];
                        final guideName =
                            guide['name'] ?? 'Kılavuz ${index + 1}';
                        final createdAt = _formatDate(guide['created_at']);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: InkWell(
                            onTap: () async {
                              // Kılavuz detayını göster
                              final guideData = await FirebaseService.getGuide(
                                guideName,
                              );
                              if (context.mounted && guideData != null) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(guideName),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Oluşturulma: $createdAt'),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Satır Sayısı: ${(guideData['rows'] as List).length}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text('Kılavuz Detayları:'),
                                          const SizedBox(height: 8),
                                          ...((guideData['rows'] as List)
                                              .take(5)
                                              .map((row) {
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        bottom: 4,
                                                      ),
                                                  child: Text(
                                                    '• ${row['serumType']} - Yaş: ${row['ageRange']}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                );
                                              })),
                                          if ((guideData['rows'] as List)
                                                  .length >
                                              5)
                                            Text(
                                              '... ve ${(guideData['rows'] as List).length - 5} satır daha',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontStyle: FontStyle.italic,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Kapat'),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  KilavuzScreen(
                                                    guideDataToEdit: guideData,
                                                  ),
                                            ),
                                          ).then((_) => _loadGuides());
                                        },
                                        icon: const Icon(Icons.edit, size: 18),
                                        label: const Text('Düzenle'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF0058A3,
                                          ),
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
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
                              child: Stack(
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
                                          borderRadius: BorderRadius.circular(14),
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
                                          Icons.book,
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
                                            Padding(
                                              padding: EdgeInsets.only(
                                                right: isMobile ? 60 : 0,
                                              ),
                                              child: Text(
                                                guideName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                  color: Color(0xFF0058A3),
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.calendar_today,
                                                  size: 14,
                                                  color: Colors.grey[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    createdAt.isNotEmpty
                                                        ? 'Oluşturulma: $createdAt'
                                                        : 'Tarih bilgisi yok',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[600],
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Sağ üstte küçük ikonlar (mobilde)
                                  if (isMobile)
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            icon: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.red.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                                size: 18,
                                              ),
                                            ),
                                            onPressed: () async {
                                      // Silme onayı
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Kılavuzu Sil'),
                                          content: Text(
                                            '"$guideName" kılavuzunu silmek istediğinizden emin misiniz?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('İptal'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                              ),
                                              child: const Text('Sil'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirmed == true && context.mounted) {
                                        final success = await FirebaseService
                                            .deleteGuide(guideName);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                success
                                                    ? 'Kılavuz başarıyla silindi!'
                                                    : 'Kılavuz silinirken bir hata oluştu!',
                                              ),
                                              backgroundColor: success
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          );
                                          if (success) {
                                            _loadGuides();
                                          }
                                        }
                                      }
                                    },
                                    tooltip: 'Sil',
                                  ),
                                          PopupMenuButton<String>(
                                            padding: EdgeInsets.zero,
                                            icon: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFF0058A3,
                                                ).withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Icon(
                                                Icons.more_vert,
                                                color: Color(0xFF0058A3),
                                                size: 18,
                                              ),
                                            ),
                                            onSelected: (value) async {
                                      if (value == 'edit') {
                                        final guideData =
                                            await FirebaseService.getGuide(
                                              guideName,
                                            );
                                        if (context.mounted &&
                                            guideData != null) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  KilavuzScreen(
                                                    guideDataToEdit: guideData,
                                                  ),
                                            ),
                                          ).then((_) => _loadGuides());
                                        }
                                      } else if (value == 'view') {
                                        final guideData =
                                            await FirebaseService.getGuide(
                                              guideName,
                                            );
                                        if (context.mounted &&
                                            guideData != null) {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text(guideName),
                                              content: SingleChildScrollView(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Oluşturulma: $createdAt',
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      'Satır Sayısı: ${(guideData['rows'] as List).length}',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    const Text(
                                                      'Kılavuz Detayları:',
                                                    ),
                                                    const SizedBox(height: 8),
                                                    ...((guideData['rows']
                                                            as List)
                                                        .take(5)
                                                        .map((row) {
                                                          return Padding(
                                                            padding:
                                                                const EdgeInsets.only(
                                                                  bottom: 4,
                                                                ),
                                                            child: Text(
                                                              '• ${row['serumType']} - Yaş: ${row['ageRange']}',
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                  ),
                                                            ),
                                                          );
                                                        })),
                                                    if ((guideData['rows']
                                                                as List)
                                                            .length >
                                                        5)
                                                      Text(
                                                        '... ve ${(guideData['rows'] as List).length - 5} satır daha',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontStyle:
                                                              FontStyle.italic,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text('Kapat'),
                                                ),
                                                ElevatedButton.icon(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            KilavuzScreen(
                                                              guideDataToEdit:
                                                                  guideData,
                                                            ),
                                                      ),
                                                    ).then(
                                                      (_) => _loadGuides(),
                                                    );
                                                  },
                                                  icon: const Icon(
                                                    Icons.edit,
                                                    size: 18,
                                                  ),
                                                  label: const Text('Düzenle'),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            const Color(
                                                              0xFF0058A3,
                                                            ),
                                                        foregroundColor:
                                                            Colors.white,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'view',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.visibility,
                                              size: 20,
                                              color: Color(0xFF0058A3),
                                            ),
                                            SizedBox(width: 8),
                                            Text('Detayları Görüntüle'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.edit,
                                              size: 20,
                                              color: Color(0xFF0058A3),
                                            ),
                                            SizedBox(width: 8),
                                            Text('Düzenle'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                        ],
                                      ),
                                    )
                                  else
                                    // Desktop görünümünde eski yapı
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.red.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                            ),
                                            onPressed: () async {
                                              final confirmed = await showDialog<bool>(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text('Kılavuzu Sil'),
                                                  content: Text(
                                                    '"$guideName" kılavuzunu silmek istediğinizden emin misiniz?',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(context, false),
                                                      child: const Text('İptal'),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () =>
                                                          Navigator.pop(context, true),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.red,
                                                        foregroundColor: Colors.white,
                                                      ),
                                                      child: const Text('Sil'),
                                                    ),
                                                  ],
                                                ),
                                              );

                                              if (confirmed == true && context.mounted) {
                                                final success = await FirebaseService
                                                    .deleteGuide(guideName);
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        success
                                                            ? 'Kılavuz başarıyla silindi!'
                                                            : 'Kılavuz silinirken bir hata oluştu!',
                                                      ),
                                                      backgroundColor: success
                                                          ? Colors.green
                                                          : Colors.red,
                                                    ),
                                                  );
                                                  if (success) {
                                                    _loadGuides();
                                                  }
                                                }
                                              }
                                            },
                                            tooltip: 'Sil',
                                          ),
                                          const SizedBox(width: 8),
                                          PopupMenuButton<String>(
                                            icon: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFF0058A3,
                                                ).withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.more_vert,
                                                color: Color(0xFF0058A3),
                                              ),
                                            ),
                                            onSelected: (value) async {
                                              if (value == 'edit') {
                                                final guideData =
                                                    await FirebaseService.getGuide(
                                                      guideName,
                                                    );
                                                if (context.mounted &&
                                                    guideData != null) {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          KilavuzScreen(
                                                            guideDataToEdit: guideData,
                                                          ),
                                                    ),
                                                  ).then((_) => _loadGuides());
                                                }
                                              } else if (value == 'view') {
                                                final guideData =
                                                    await FirebaseService.getGuide(
                                                      guideName,
                                                    );
                                                if (context.mounted &&
                                                    guideData != null) {
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      title: Text(guideName),
                                                      content: SingleChildScrollView(
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              'Oluşturulma: $createdAt',
                                                            ),
                                                            const SizedBox(height: 16),
                                                            Text(
                                                              'Satır Sayısı: ${(guideData['rows'] as List).length}',
                                                              style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight.bold,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 8),
                                                            const Text(
                                                              'Kılavuz Detayları:',
                                                            ),
                                                            const SizedBox(height: 8),
                                                            ...((guideData['rows']
                                                                    as List)
                                                                .take(5)
                                                                .map((row) {
                                                                  return Padding(
                                                                    padding:
                                                                        const EdgeInsets.only(
                                                                          bottom: 4,
                                                                        ),
                                                                    child: Text(
                                                                      '• ${row['serumType']} - Yaş: ${row['ageRange']}',
                                                                      style:
                                                                          const TextStyle(
                                                                            fontSize:
                                                                                12,
                                                                          ),
                                                                    ),
                                                                  );
                                                                })),
                                                            if ((guideData['rows']
                                                                        as List)
                                                                    .length >
                                                                5)
                                                              Text(
                                                                '... ve ${(guideData['rows'] as List).length - 5} satır daha',
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  fontStyle:
                                                                      FontStyle.italic,
                                                                  color:
                                                                      Colors.grey[600],
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(context),
                                                          child: const Text('Kapat'),
                                                        ),
                                                        ElevatedButton.icon(
                                                          onPressed: () {
                                                            Navigator.pop(context);
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder: (context) =>
                                                                    KilavuzScreen(
                                                                      guideDataToEdit:
                                                                          guideData,
                                                                    ),
                                                              ),
                                                            ).then(
                                                              (_) => _loadGuides(),
                                                            );
                                                          },
                                                          icon: const Icon(
                                                            Icons.edit,
                                                            size: 18,
                                                          ),
                                                          label: const Text('Düzenle'),
                                                          style:
                                                              ElevatedButton.styleFrom(
                                                                backgroundColor:
                                                                    const Color(
                                                                      0xFF0058A3,
                                                                    ),
                                                                foregroundColor:
                                                                    Colors.white,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'view',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.visibility,
                                                      size: 20,
                                                      color: Color(0xFF0058A3),
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text('Detayları Görüntüle'),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.edit,
                                                      size: 20,
                                                      color: Color(0xFF0058A3),
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text('Düzenle'),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: isMobile
          ? AdminBottomNavBar(
              currentIndex: 1,
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
                    // Zaten bu sayfadayız
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
              MaterialPageRoute(builder: (context) => const KilavuzScreen()),
            );
            break;
          case 2:
            // Zaten bu sayfadayız
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
                const Icon(Icons.local_hospital, color: Colors.white, size: 48),
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
                MaterialPageRoute(builder: (context) => const KilavuzScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.list),
            title: const Text('Kılavuz Listesi'),
            selected: true,
            selectedTileColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.1),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Tahlil Ekle'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const TahlilEkleScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('Tahlil Listesi'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const TahlilListScreen(),
                ),
              );
            },
          ),
          const Divider(),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return ListTile(
                leading: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
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
