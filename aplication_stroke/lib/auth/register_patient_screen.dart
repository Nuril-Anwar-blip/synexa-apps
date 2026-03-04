import 'package:flutter/material.dart';

import 'auth_layout.dart';
import 'widgets/register_form.dart';

/// Halaman Pendaftaran Pasien
///
/// Halaman ini digunakan untuk mendaftar sebagai pasien baru.
/// Pengguna harus mengisi data diri lengkap untuk memulai perjalanan pemulihan.
/// Halaman pendaftaran khusus untuk pengguna Pasien.
class RegisterPatientScreen extends StatelessWidget {
  const RegisterPatientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Daftar Pasien',
      desc: 'Isi data diri lengkap untuk memulai perjalanan pemulihan Anda.',
      formField: const RegisterForm(role: RegisterRole.patient),
      marginTop: 60,
    );
  }
}

