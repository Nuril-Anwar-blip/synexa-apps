import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider untuk mengelola tema aplikasi (Light/Dark Mode).
/// Menyimpan preferensi tema menggunakan SharedPreferences.
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _fontFamilyKey = 'font_family';
  static const String _fontSizeKey = 'font_size';

  ThemeMode _themeMode = ThemeMode.light;
  String _fontFamily = 'Poppins';
  double _fontSize = 1.0; // Scale factor: 0.8 (Kecil), 1.0 (Normal), 1.2 (Besar)

  ThemeMode get themeMode => _themeMode;
  String get fontFamily => _fontFamily;
  double get fontSize => _fontSize;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadSettings();
  }

  /// Memuat pengaturan yang tersimpan dari SharedPreferences.
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load Theme
      final savedTheme = prefs.getString(_themeKey);
      if (savedTheme != null) {
        _themeMode = ThemeMode.values.firstWhere(
          (mode) => mode.toString() == savedTheme,
          orElse: () => ThemeMode.light,
        );
      }

      // Load Font Family
      _fontFamily = prefs.getString(_fontFamilyKey) ?? 'Poppins';

      // Load Font Size Scale
      _fontSize = prefs.getDouble(_fontSizeKey) ?? 1.0;

      notifyListeners();
    } catch (_) {}
  }

  /// Mengatur mode tema dan menyimpannya.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.toString());
    } catch (_) {}
  }

  /// Mengatur jenis font.
  Future<void> setFontFamily(String family) async {
    if (_fontFamily == family) return;
    _fontFamily = family;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fontFamilyKey, family);
    } catch (_) {}
  }

  /// Mengatur skala ukuran font.
  Future<void> setFontSize(double size) async {
    if (_fontSize == size) return;
    _fontSize = size;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_fontSizeKey, size);
    } catch (_) {}
  }

  /// Mengganti tema antara Light dan Dark.
  Future<void> toggleTheme() async {
    final newMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }
}

