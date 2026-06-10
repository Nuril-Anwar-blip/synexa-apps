import 'package:flutter/material.dart';

import 'auth_layout.dart';
import 'login_screen.dart';

/// Registrasi apoteker hanya melalui undangan admin.
class RegisterPharmacistScreen extends StatelessWidget {
  const RegisterPharmacistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Registrasi Apoteker',
      desc: 'Pendaftaran apoteker dilakukan melalui undangan dari admin.',
      marginTop: 60,
      showBackButton: true,
      formField: Column(
        children: [
          const Icon(Icons.vpn_key_rounded, size: 48, color: Color(0xFF0D9488)),
          const SizedBox(height: 16),
          const Text(
            'Hubungi admin untuk mendapatkan kode undangan, lalu gunakan kode tersebut saat registrasi di aplikasi mobile apoteker.',
            textAlign: TextAlign.center,
            style: TextStyle(height: 1.5),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
            child: const Text('Kembali ke Login'),
          ),
        ],
      ),
    );
  }
}
