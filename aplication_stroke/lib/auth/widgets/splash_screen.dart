import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../onboarding_screen.dart';
import '../../utils/app_route_transitions.dart';
import '../../utils/auth_role_navigation.dart';
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
    } catch (e) {
      debugPrint('SplashScreen push sync error: $e');
    }

    if (!mounted) return;
    try {
      await AuthRoleNavigation.replaceWithRoleHome(context);
    } catch (e) {
      debugPrint('SplashScreen redirect error: $e');
      if (!mounted) return;
      await AuthRoleNavigation.replaceWithRoleHome(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
