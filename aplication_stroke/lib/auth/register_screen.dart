import 'package:flutter/material.dart';

import 'auth_layout.dart';
import 'login_screen.dart';
import 'widgets/auth_bottom_section.dart';
import 'widgets/register_form.dart';

/// Halaman registrasi pasien — form langsung tanpa pilih peran.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Buat Akun',
      desc: 'Daftar sebagai pasien untuk memulai perjalanan pemulihan Anda.',
      marginTop: 0,
      showBackButton: true,
      onBack: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      ),
      formField: const _RegisterContent(),
    );
  }
}

class _RegisterContent extends StatelessWidget {
  const _RegisterContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              'Sudah punya akun? ',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            GestureDetector(
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              child: const Text(
                'Masuk',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF0A7AC1),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const RegisterForm(),
        const SizedBox(height: 20),
        const AuthBottomSection(),
      ],
    );
  }
}
