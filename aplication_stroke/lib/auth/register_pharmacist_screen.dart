import 'package:flutter/material.dart';

import 'auth_layout.dart';
import 'widgets/register_form.dart';

/// Halaman Pendaftaran Apoteker
///
/// Halaman ini digunakan untuk mendaftar sebagai apoteker baru.
/// Pengguna harus memvalidasi data profesional untuk membantu pasien secara daring.
/// Halaman pendaftaran khusus untuk pengguna Apoteker.
class RegisterPharmacistScreen extends StatelessWidget {
  const RegisterPharmacistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Daftar Apoteker',
      desc:
          'Validasi data profesional Anda untuk membantu pasien secara daring.',
      formField: const RegisterForm(role: RegisterRole.pharmacist),
      marginTop: 60,
    );
  }
}

