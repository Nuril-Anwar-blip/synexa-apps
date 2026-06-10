import 'package:shared_preferences/shared_preferences.dart';

class AuthLocalService {
  static const String _keyRefreshToken = "refresh_token";
  static const String _keyUserId = "user_id";
  static const String _keyEmail = "email";

  /// Simpan session ke lokal
  static Future<void> saveSession({
    required String refreshToken,
    required String userId,
    String? email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRefreshToken, refreshToken);
    await prefs.setString(_keyUserId, userId);
    if (email != null) {
      await prefs.setString(_keyEmail, email);
    }
  }

  /// Ambil session dari lokal
  static Future<Map<String, String>?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(_keyRefreshToken);
    final userId = prefs.getString(_keyUserId);

    if (refreshToken == null || userId == null) return null;

    return {
      "refresh_token": refreshToken,
      "user_id": userId,
      "email": prefs.getString(_keyEmail) ?? "",
    };
  }

  /// Hapus session dari lokal
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyEmail);
  }

  /// Cek apakah ada session valid
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyRefreshToken) &&
        prefs.containsKey(_keyUserId);
  }
}
