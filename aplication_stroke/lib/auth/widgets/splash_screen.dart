import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aplication_stroke/modules/admin/admin_mobile_blocked_screen.dart';
import 'package:aplication_stroke/modules/admin/services/admin_service.dart';
import 'package:aplication_stroke/modules/dashboard/unified_main_screen.dart';
import 'package:aplication_stroke/modules/pharmacist/apoteker_dashboard_screen.dart';
import 'package:aplication_stroke/modules/doctor/doctor_dashboard_screen.dart';
import '../onboarding_screen.dart';
import '../../utils/app_route_transitions.dart';
import '../../services/remote/push_notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      Navigator.pushReplacement(
        context,
        AppRouteTransitions.fadeSlide(const OnboardingScreen()),
      );
      return;
    }

    try {
      await PushNotificationService.instance.syncTokenIfLoggedIn();

      final isAdmin = await AdminService().isCurrentUserAdmin();
      if (!mounted) return;

      if (isAdmin) {
        Navigator.pushReplacement(
          context,
          AppRouteTransitions.fadeSlide(const AdminMobileBlockedScreen()),
        );
        return;
      }

      final client = Supabase.instance.client;
      final uid = session.user.id;

      final pharmacist = await client
          .from('pharmacists')
          .select('id')
          .eq('auth_id', uid)
          .maybeSingle();

      if (!mounted) return;

      if (pharmacist != null) {
        Navigator.pushReplacement(
          context,
          AppRouteTransitions.fadeSlide(const ApotekerDashboardScreen()),
        );
        return;
      }

      final doctor = await client
          .from('doctors')
          .select('id')
          .eq('auth_id', uid)
          .maybeSingle();

      if (!mounted) return;

      if (doctor != null) {
        Navigator.pushReplacement(
          context,
          AppRouteTransitions.fadeSlide(const DoctorDashboardScreen()),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        AppRouteTransitions.fadeSlide(const UnifiedMainScreen()),
      );
    } catch (e) {
      Navigator.pushReplacement(
        context,
        AppRouteTransitions.fadeSlide(const UnifiedMainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
