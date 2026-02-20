import 'package:flutter/material.dart';
import 'widgets/login_form.dart';

import 'auth_layout.dart';

/// Halaman Login
///
/// Halaman ini digunakan untuk masuk ke aplikasi dengan menggunakan email dan password.
/// Pengguna harus memasukkan kredensial yang valid untuk mengakses fitur aplikasi.
/// Halaman Login untuk masuk ke aplikasi.
/// Mempilkan form login yang dibungkus dengan [AuthLayout].
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return const AuthLayout(
      title: "Login",
      desc: "Masukkan email dan password Anda!",
      formField: LoginForm(),
      marginTop: 120,
    );
  }
}

