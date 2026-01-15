import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  // Varsayılan dil Türkçe
  Locale _currentLocale = const Locale('tr', 'TR');

  Locale get currentLocale => _currentLocale;
  String get currencySymbol => _currentLocale.languageCode == 'tr' ? '₺' : '\$';

  LanguageProvider() {
    _loadLanguage();
  }

  // Dili ayarlar ve hafızaya kaydeder
  void setLanguage(Locale locale) async {
    _currentLocale = locale;
    notifyListeners(); // Ekranları yeniler
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
  }

  // --- BU YENİ: Tek tıkla dili değiştirmek için kullanacaksın ---
  void toggleLanguage() {
    if (_currentLocale.languageCode == 'tr') {
      setLanguage(const Locale('en', 'US'));
    } else {
      setLanguage(const Locale('tr', 'TR'));
    }
  }

  // Uygulama açıldığında hafızadan dili yükler
  void _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    // Eğer hafızada hiçbir şey yoksa 'tr' (Türkçe) açılmasını garanti ediyoruz
    String languageCode = prefs.getString('language_code') ?? 'tr';
    _currentLocale = Locale(languageCode);
    notifyListeners();
  }
}
