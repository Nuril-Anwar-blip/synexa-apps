import 'package:shared_preferences/shared_preferences.dart';

/// Layanan lokal untuk mengelola status login menggunakan SharedPreferences.
class AuthLocalService {
  static const _keyIsLoggedIn = "is_logged_in";

  /// Menyimpan status login (true/false) ke penyimpanan lokal.
  static Future<void> setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, value);
  }

  /// Menghapus status login dari penyimpanan lokal (Logout).
  static Future<bool> clearLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(_keyIsLoggedIn);
  }
}

