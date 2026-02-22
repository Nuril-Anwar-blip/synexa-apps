import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider untuk mengelola bahasa aplikasi (Indonesia, Inggris, Melayu).
/// Menyimpan preferensi bahasa menggunakan SharedPreferences.
class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  
  // Default language: Indonesia
  String _currentLanguage = 'id';

  String get currentLanguage => _currentLanguage;

  Locale get locale => Locale(_currentLanguage);

  LanguageProvider() {
    _loadLanguage();
  }

  /// Memuat bahasa yang tersimpan dari SharedPreferences.
  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey);
      if (savedLanguage != null) {
        _currentLanguage = savedLanguage;
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Mengatur bahasa aplikasi dan menyimpannya.
  Future<void> setLanguage(String languageCode) async {
    if (_currentLanguage == languageCode) return;
    _currentLanguage = languageCode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
    } catch (_) {}
  }

  /// Mendapatkan nama bahasa yang ramah pengguna.
  String get languageName {
    switch (_currentLanguage) {
      case 'en':
        return 'English';
      case 'ms':
        return 'Melayu';
      case 'id':
      default:
        return 'Bahasa Indonesia';
    }
  }

  /// Helper untuk mendapatkan teks berdasarkan bahasa (Placeholder sederhana)
  /// Dalam skala besar, sebaiknya menggunakan flutter_localizations atau arb files.
  String translate(Map<String, String> values) {
    return values[_currentLanguage] ?? values['id'] ?? '';
  }
}
