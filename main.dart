import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/login/user_login_screen.dart';
import 'screens/login/admin_login_screen.dart';
import 'screens/user/user_tahlil_list_screen.dart';
import 'screens/user/user_tahlil_detail_screen.dart';
import 'screens/user/user_profile_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/tahlil_ekle_screen.dart';
import 'screens/admin/tahlil_list_screen.dart';
import 'screens/admin/tahlil_detail_screen.dart';
import 'screens/admin/kilavuz_screen.dart';
import 'screens/admin/kilavuz_list_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      title: 'E-Laboratuvar Sistemi',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0058A3),
          brightness: Brightness.light,
          primary: const Color(0xFF0058A3),
          secondary: const Color(0xFF00A8E8),
          surface: Colors.white,
          error: const Color(0xFFE63946),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          color: Colors.white,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0058A3),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            shadowColor: const Color(0xFF0058A3).withValues(alpha: 0.3),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0058A3), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Color(0xFF0058A3),
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0058A3),
          brightness: Brightness.dark,
          primary: const Color(0xFF0058A3),
          secondary: const Color(0xFF00A8E8),
          surface: const Color(0xFF1E1E1E),
          error: const Color(0xFFE63946),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey.shade800, width: 1),
          ),
          color: const Color(0xFF1E1E1E),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0058A3),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            shadowColor: const Color(0xFF0058A3).withValues(alpha: 0.3),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade700),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade700),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00A8E8), width: 2),
          ),
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Color(0xFF0058A3),
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      builder: (context, child) {
        // Navigation bar rengini gradient maviye ayarla
        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            systemNavigationBarColor: Color(0xFF0058A3),
            systemNavigationBarIconBrightness: Brightness.light,
          ),
        );
        
        return ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: [
          const Breakpoint(start: 0, end: 450, name: MOBILE),
          const Breakpoint(start: 451, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: 1920, name: DESKTOP),
        ],
        );
      },
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/user-login': (context) => const UserLoginScreen(),
        '/admin-login': (context) => const AdminLoginScreen(),
        '/user-tahlil-list': (context) => const UserTahlilListScreen(),
        '/user-tahlil-detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>;
          return UserTahlilDetailScreen(tahlilId: args['tahlilId']!);
        },
        '/user-profile': (context) => const UserProfileScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/tahlil-ekle': (context) => const TahlilEkleScreen(),
        '/tahlil-list': (context) => const TahlilListScreen(),
        '/tahlil-detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>;
          return TahlilDetailScreen(tahlilId: args['tahlilId']!);
        },
        '/kilavuz': (context) => const KilavuzScreen(),
        '/kilavuz-list': (context) => const KilavuzListScreen(),
      },
    );
  }
}
