import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_manager.dart'; // Veya doğru dosya yolu
// ...
import 'package:cuzdanim_app/language_provider.dart'; // Dosya yolun neyse ona göre düzelt

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDarkMode = themeManager.themeMode == ThemeMode.dark;
    final langProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : const Color(0xFFFFFDF5),
      appBar: AppBar(
        title: Text(
          langProvider.currentLocale.languageCode == 'tr'
              ? 'Ayarlar'
              : 'Settings',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 17, 96, 111),
                Color.fromARGB(255, 90, 231, 231),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TEMA DEĞİŞTİRME KARTI
            _buildSettingCard(
              context,
              child: SwitchListTile.adaptive(
                secondary:
                    const Icon(Icons.dark_mode, color: Colors.deepPurpleAccent),
                title: Text(
                  langProvider.currentLocale.languageCode == 'tr'
                      ? 'Karanlık Mod'
                      : 'Dark Mode',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87),
                ),
                subtitle: Text(
                  langProvider.currentLocale.languageCode == 'tr'
                      ? (isDarkMode ? 'Açık' : 'Kapalı')
                      : (isDarkMode ? 'Enabled' : 'Disabled'),
                  style: TextStyle(
                      color: isDarkMode ? Colors.white60 : Colors.black54),
                ),
                value: isDarkMode,
                onChanged: (value) {
                  themeManager
                      .setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                },
              ),
            ),

            const SizedBox(height: 12),

            // 2. DİL SEÇİMİ KARTI
            _buildSettingCard(
              context,
              child: SwitchListTile.adaptive(
                secondary: const Icon(Icons.language, color: Colors.blueAccent),
                title: Text(
                  langProvider.currentLocale.languageCode == 'tr'
                      ? 'Dil (Türkçe)'
                      : 'Language (English)',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87),
                ),
                subtitle: Text(
                  langProvider.currentLocale.languageCode == 'tr'
                      ? 'İngilizceye geçmek için kaydır'
                      : 'Switch to Turkish',
                  style: TextStyle(
                      color: isDarkMode ? Colors.white60 : Colors.black54),
                ),
                value: langProvider.currentLocale.languageCode == 'en',
                onChanged: (value) {
                  langProvider.setLanguage(value
                      ? const Locale('en', 'US')
                      : const Locale('tr', 'TR'));
                },
              ),
            ),

            const SizedBox(height: 12),

            // 3. PARA BİRİMİ SEÇİMİ KARTI

            const SizedBox(height: 16),
            const Divider(),
          ],
        ),
      ),
    );
  }

  // --- BU FONKSİYONU BUILD METODUNUN HEMEN ALTINA (AMA DIŞINA) EKLEMEYİ UNUTMA ---
  Widget _buildSettingCard(BuildContext context, {required Widget child}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    const Color elegantTeal = Color.fromARGB(255, 7, 72, 79);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2226) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color.fromARGB(255, 4, 69, 77).withAlpha(160)
              : Colors.grey.withAlpha(60),
          width: 1.5,
        ),
        boxShadow: [
          if (isDark)
            BoxShadow(
              color: elegantTeal.withAlpha(30),
              blurRadius: 10,
              spreadRadius: 1,
            ),
        ],
      ),
      child: child,
    );
  }
}
