import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/user_model.dart';
import '../../supabase/supabase_client.dart';
import '../local/auth_local_service.dart';

class AuthService {
  final _client = SupabaseManager.client;

  /// Simpan session hasil pairing dari HP
  Future<bool> saveSessionFromPairing({
    required String refreshToken,
    required String userId,
    String? email,
  }) async {
    try {
      // Set session di supabase client
      await _client.auth.setSession(refreshToken);

      // Simpan juga ke lokal
      await AuthLocalService.saveSession(
        refreshToken: refreshToken,
        userId: userId,
        email: email,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Restore session dari lokal (auto login smartwatch)
  Future<bool> restoreSession() async {
    final session = await AuthLocalService.getSession();
    if (session == null) return false;

    try {
      await _client.auth.setSession(session['refresh_token']!);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Ambil data user dari tabel users
  Future<UserModel?> getUserById(String userId) async {
    final response = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return UserModel.fromMap(response);
  }

  /// Logout smartwatch
  Future<void> signOut() async {
    await _client.auth.signOut();
    await AuthLocalService.clearSession();
  }
}
