import 'package:aplication_stroke/modules/admin/admin_dashboard_screen.dart';
import 'package:aplication_stroke/modules/dashboard/dashboard_screen.dart';
import 'package:aplication_stroke/modules/pharmacist/apoteker_dashboard_screen.dart';

import '../login_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    // jeda agar tidak terlalu cepat
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      // akhiri sesi jika tidak ada, masuk ke menu login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    try {
      // ambil data profile
      final response = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('id', session.user.id)
          .maybeSingle();

      final role = response == null ? null : response['role'] as String?;

      if (!mounted) return;

      if (role == 'apoteker') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ApotekerDashboardScreen()),
        );
      } else if (role == 'pasien') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      } else {
        // dashboard pasien
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      // jika gagal mengambil profile, arahkan ke dashboard default
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
