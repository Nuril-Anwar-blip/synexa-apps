import 'package:flutter/material.dart';

import '../auth/widgets/splash_screen.dart';
import '../modules/admin/admin_mobile_blocked_screen.dart';
import '../modules/dashboard/unified_main_screen.dart';
import '../modules/doctor/doctor_dashboard_screen.dart';
import '../modules/pharmacist/apoteker_dashboard_screen.dart';
import 'app_route_transitions.dart';
import 'user_profile_helper.dart';

/// Navigasi ke home screen sesuai peran login.
class AuthRoleNavigation {
  AuthRoleNavigation._();

  static Widget homeForRole(AppRole role) {
    return switch (role) {
      AppRole.admin => const AdminMobileBlockedScreen(),
      AppRole.pharmacist => const ApotekerDashboardScreen(),
      AppRole.doctor => const DoctorDashboardScreen(),
      AppRole.patient => const UnifiedMainScreen(),
    };
  }

  static Future<void> replaceWithRoleHome(BuildContext context) async {
    final role = await UserProfileHelper.resolveAppRole();
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      AppRouteTransitions.fadeSlide(homeForRole(role)),
    );
  }

  /// Setelah login: lewati splash jika peran sudah diketahui.
  static Future<void> afterLogin(BuildContext context) async {
    final role = await UserProfileHelper.resolveAppRole();
    if (!context.mounted) return;
    if (role == AppRole.patient) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SplashScreen()),
      );
      return;
    }
    Navigator.pushReplacement(
      context,
      AppRouteTransitions.fadeSlide(homeForRole(role)),
    );
  }
}
