import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/widgets/splash_screen.dart';

/// Ditampilkan jika akun admin mencoba masuk lewat aplikasi mobile.
class AdminMobileBlockedScreen extends StatelessWidget {
  const AdminMobileBlockedScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.desktop_windows_rounded,
                  size: 56,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Dashboard Admin\nHanya untuk Desktop',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Akun admin tidak dapat digunakan di perangkat mobile. '
                'Silakan buka aplikasi admin di Windows, macOS, atau Linux.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  height: 1.6,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: Text(
                  'Jalankan di desktop:\nflutter run -t lib/main_admin.dart -d windows',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.blue.shade900,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _logout(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0A7AC1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Keluar & Gunakan Akun Lain'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
