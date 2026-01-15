import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

// Kendi dosyaların için sadece package olanları veya sadece dosya yollarını seçelim
import 'package:cuzdanim_app/language_provider.dart';
import 'package:cuzdanim_app/theme_manager.dart';
import 'database/database_helper.dart';
import 'pages/home_screen.dart';
import 'pages/login_register.dart';
import 'pages/reports_screen.dart';
import 'pages/transaction_history_screen.dart';

import 'pages/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  final dbHelper = DatabaseHelper();
  try {
    await dbHelper.database;
  } catch (e) {
    // burası boş - ignore: avoid_print
    debugPrint("Error initializing database: $e");
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeManager()),
        ChangeNotifierProvider(create: (context) => LanguageProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final themeManager = Provider.of<ThemeManager>(context);
    return MaterialApp(
      title: 'Cuzdanim',
      locale: langProvider.currentLocale, // Seçili dili provider'dan alıyoruz
      supportedLocales: const [
        Locale('tr', 'TR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // 2. ADIM: Tema modunu Provider'dan al (Sistem mi, açık mı, koyu mu?)
      themeMode: themeManager.themeMode,

      // Açık Tema Ayarları
      // Açık Tema Ayarları
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF000428),
          brightness: Brightness.light,
        ),
        navigationBarTheme: NavigationBarThemeData(
          // withOpacity(0.3) yerine .withValues(alpha: 0.3) kullanıyoruz
          indicatorColor: const Color(0xFF004e92).withValues(alpha: 0.3),
        ),
      ),

      // Karanlık Tema Ayarları
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        // Saf siyah yerine yumuşak bir kömür grisi
        scaffoldBackgroundColor: const Color(0xFF121212),

        // Kartlar ve üst bar için bir tık daha açık bir ton
        cardColor: const Color(0xFF1E1E1E),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
        ),

        // Yazıları tam beyaz yerine "Off-White" yaparak parlamayı önleyelim
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFE0E0E0)),
          bodyMedium: TextStyle(color: Color(0xFFB0B0B0)),
        ),

        // Altın sarısı butonların dark mode'da parlaması için:
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFC2B32A), // altın rengi --kararsizim
          secondary: Color(0xFF006064), // Koyu Turkuaz
          surface: Color(0xFF1E1E1E),
        ),
      ),

      debugShowCheckedModeBanner: false,
      home: const LoginRegister(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final int? userId;
  final String? userName;
  final String? userEmail;

  // Login'den gelen verileri karşılayan kapı
  const MainNavigationScreen({
    super.key,
    this.userId, // Burayı ekle
    required this.userName,
    required this.userEmail,
  });

  @override
  MainNavigationScreenState createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      // 1. Anasayfa (İndeks 0)
      HomeScreen(
        userId: widget.userId,
        userName: widget.userName,
        userEmail: widget.userEmail,
      ),

      // 2. Geçmiş (İndeks 1)
      TransactionHistoryScreen(userId: widget.userId!),

      // 3. Raporlar (İndeks 2)
      ReportsScreen(userId: widget.userId!),

      // 4. Ayarlar/Hesap (İndeks 3)
      const SettingsScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);

    // 1. KORUMA: Liste dolmadan sayfa çizilmeye çalışılırsa hata vermemesi için

    return Scaffold(
      // Sayfa geçiş animasyonu (Senin istediğin yumuşak geçiş)
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_selectedIndex],
      ),

      // Senin o meşhur lüks Navigasyon Bar tasarımın
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E1E1E)
              : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(30),
              blurRadius: 15,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            backgroundColor: Colors.transparent,
            elevation: 0,
            indicatorColor: Colors.transparent,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              // 1. ANA SAYFA
              NavigationDestination(
                icon: const Icon(Icons.home_outlined, color: Colors.grey),
                selectedIcon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0x33FEBD11),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.home, color: Color(0xFFFEBD11)),
                ),
                label: langProvider.currentLocale.languageCode == 'tr'
                    ? 'Anasayfa'
                    : 'Home',
              ),

              // 2. GEÇMİŞ
              NavigationDestination(
                icon: const Icon(Icons.history_outlined, color: Colors.grey),
                selectedIcon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0x334FCBD6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.history, color: Color(0xFF4FCBD6)),
                ),
                label: langProvider.currentLocale.languageCode == 'tr'
                    ? 'Geçmiş'
                    : 'History',
              ),

              // 3. RAPORLAR
              NavigationDestination(
                icon: const Icon(Icons.bar_chart_outlined, color: Colors.grey),
                selectedIcon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0x33FEBD11),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bar_chart, color: Color(0xFFFEBD11)),
                ),
                label: langProvider.currentLocale.languageCode == 'tr'
                    ? 'Raporlar'
                    : 'Reports',
              ),

              // 4. AYARLAR (PROFİL)
              NavigationDestination(
                icon: const Icon(Icons.settings_outlined, color: Colors.grey),
                selectedIcon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0x334FCBD6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.settings, color: Color(0xFF4FCBD6)),
                ),
                label: langProvider.currentLocale.languageCode == 'tr'
                    ? 'Ayarlar'
                    : 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
