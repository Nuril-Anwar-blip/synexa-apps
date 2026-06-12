import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/login_screen.dart';
import '../services/local/auth_local_service.dart';

/// Logout aman: bersihkan sesi Supabase + prefs, lalu ke layar login.
class AuthLogoutHelper {
  AuthLogoutHelper._();

  static Future<void> logout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      try {
        await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
      } catch (_) {}
    }

    await AuthLocalService.clearLogin();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pending_profile');
    } catch (_) {}

    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }
}
