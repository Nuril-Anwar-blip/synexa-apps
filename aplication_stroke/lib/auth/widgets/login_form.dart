import 'dart:developer';
import 'package:flutter/material.dart';

import '../../../../services/remote/auth_service.dart';
import '../../../../utils/input_validator.dart';
import 'splash_screen.dart';
import 'auth_redirect_text.dart';
import 'auth_bottom_section.dart';
import 'password_form_field_with_label.dart';
import 'text_form_field_with_label.dart';
import '../register_screen.dart';

/// Form Login — desain baru tanpa perlu scroll
class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _isLoading = false;

  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    try {
      final response = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (response.session != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SplashScreen()),
        );
      } else {
        _showSnackBar("Email atau password salah.");
      }
    } catch (e) {
      log(e.toString());
      if (mounted) _showSnackBar("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Judul form ───────────────────────────────────
          const Text(
            'Masuk ke Akun',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Belum punya akun? ',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, anim, __) => FadeTransition(
                      opacity: anim,
                      child: const RegisterScreen(),
                    ),
                    transitionDuration: const Duration(milliseconds: 280),
                  ),
                ),
                child: const Text(
                  'Daftar sekarang',
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

          // ── Email ────────────────────────────────────────
          TextFormFieldWithLabel(
            label: "Email",
            controller: _emailController,
            fieldType: InputFieldType.email,
            validator: (v) => InputValidator.email(v),
          ),

          const SizedBox(height: 12),

          // ── Password ─────────────────────────────────────
          PasswordFormFieldWithLabel(
            controller: _passwordController,
            validator: (v) => InputValidator.minLength(v, "Password", 8),
          ),

          // ── Lupa Password ────────────────────────────────
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // TODO: navigasi ke halaman lupa password
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                foregroundColor: const Color(0xFF0A7AC1),
              ),
              child: const Text(
                'Lupa password?',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Tombol Login ─────────────────────────────────
          SizedBox(
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0A7AC1), Color(0xFF0E5FAF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0A7AC1).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isLoading ? null : _handleLogin,
                  borderRadius: BorderRadius.circular(14),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                'Masuk',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.login_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Divider + Social Login ───────────────────────
          const AuthBottomSection(),
        ],
      ),
    );
  }
}
