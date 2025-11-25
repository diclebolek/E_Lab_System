import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../login/admin_login_screen.dart';
import '../login/user_login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    final isDesktop = ResponsiveBreakpoints.of(context).isDesktop;

    // İçerik widget'ı - hem mobil hem web için ortak
    Widget contentWidget = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        // Logo/Icon - Modern tasarım
        Container(
          width: isMobile ? 140 : 180,
          height: isMobile ? 140 : 180,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0058A3), Color(0xFF00A8E8)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0058A3).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.science, size: 80, color: Colors.white),
        ),
        const SizedBox(height: 30),

        // Başlık - Sadece mavi text
        Column(
          children: [
            Text(
              'E-Laboratuvar',
              style: TextStyle(
                fontSize: isMobile ? 32 : 42,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF007BBF),
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Sistemi',
              style: TextStyle(
                fontSize: isMobile ? 32 : 42,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF007BBF),
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Hoşgeldiniz',
            style: TextStyle(
              fontSize: isMobile ? 18 : 22,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Tab Bar - Smooth geçişli
        Container(
          margin: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 40),
          child: TabBar(
            controller: _tabController,
            indicator: UnderlineTabIndicator(
              borderSide: const BorderSide(width: 3, color: Color(0xFF0083CC)),
              insets: const EdgeInsets.symmetric(horizontal: 16),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: const Color(0xFF0083CC),
            unselectedLabelColor: Colors.black,
            labelStyle: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_hospital,
                      size: 24,
                      color: _tabController.index == 0
                          ? const Color(0xFF0083CC)
                          : Colors.black,
                    ),
                    const SizedBox(width: 8),
                    const Text('Doktor Girişi'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person,
                      size: 24,
                      color: _tabController.index == 1
                          ? const Color(0xFF0083CC)
                          : Colors.black,
                    ),
                    const SizedBox(width: 8),
                    const Text('Hasta Girişi'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Tab Content
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: TabBarView(
            controller: _tabController,
            children: [
              // Doktor Girişi
              SingleChildScrollView(
                padding: EdgeInsets.only(
                  top: 8,
                  bottom: isMobile ? 20 : 40,
                  left: isMobile ? 20 : 40,
                  right: isMobile ? 20 : 40,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: const AdminLoginScreen(),
                ),
              ),
              // Hasta Girişi
              SingleChildScrollView(
                padding: EdgeInsets.only(
                  top: 8,
                  bottom: isMobile ? 20 : 40,
                  left: isMobile ? 20 : 40,
                  right: isMobile ? 20 : 40,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: const UserLoginScreen(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0058A3),
              const Color(0xFF00A8E8),
              Colors.white,
            ],
            stops: const [0.0, 0.3, 0.3],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Web görünümünde iki kolonlu düzen
              if (isDesktop) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          // Sol kolon - boş alan
                          Expanded(flex: 1, child: Container()),
                          // Sağ kolon - içerik ortalanmış
                          Expanded(
                            flex: 1,
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 600,
                                ),
                                child: contentWidget,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              // Mobil görünümünde mevcut düzen
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(child: contentWidget),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
