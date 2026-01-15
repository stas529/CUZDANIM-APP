import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';
// Bu genellikle gerekmez, ancak denenebilir.

class ThemeManager extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system; // Varsayılan: Sistem ayarı

  ThemeMode get themeMode => _themeMode;

  // Constructor: Uygulama başladığında kaydedilen ayarı yükler
  ThemeManager() {
    _loadThemeMode();
  }

  // Kayıtlı temayı SharedPreferences'tan yükleme
  _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString('themeMode') ?? 'system';

    // Yüklenen dizeyi ThemeMode nesnesine dönüştürme
    if (savedMode == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (savedMode == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners(); // Yüklendikten sonra dinleyicileri bilgilendir
  }

  // Temayı değiştirme ve kaydetme
  void setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;

    _themeMode = mode;
    notifyListeners(); // Temanın değiştiğini bildir

    // SharedPreferences'a yeni ayarı kaydetme
    final prefs = await SharedPreferences.getInstance();
    String modeString =
        mode.toString().split('.').last; // 'dark', 'light' veya 'system'
    prefs.setString('themeMode', modeString);
  }
}
