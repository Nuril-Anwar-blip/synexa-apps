/// ====================================================================
/// File: login_screen.dart
/// --------------------------------------------------------------------
/// Layar Login Pengguna
/// 
/// Dokumen ini berisi halaman login untuk autentikasi pengguna.
/// Menggunakan AuthLayout sebagai container dan LoginForm untuk input.
/// 
/// Author: Tim Developer Synexa
/// ====================================================================

import 'package:flutter/material.dart';
import 'widgets/login_form.dart';
import 'auth_layout.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthLayout(
      title: "Login",
      desc: "Masukkan email dan password Anda!",
      formField: LoginForm(),
      marginTop: 0, // tidak dipakai di layout baru
    );
  }
}
