import 'package:flutter/material.dart';

import 'auth_layout.dart';
import 'register_patient_screen.dart';
import 'register_pharmacist_screen.dart';
import 'login_screen.dart';
import 'widgets/auth_bottom_section.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Buat Akun',
      desc: 'Pilih peran Anda untuk memulai.',
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

class _RegisterContent extends StatefulWidget {
  const _RegisterContent();

  @override
  State<_RegisterContent> createState() => _RegisterContentState();
}

class _RegisterContentState extends State<_RegisterContent>
    with TickerProviderStateMixin {
  int? _selectedIndex;
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnims;

  static const _roles = [
    _RoleData(
      icon: Icons.health_and_safety_rounded,
      title: 'Pasien',
      subtitle: 'Pengguna Umum',
      subtitleIcon: Icons.person_rounded,
      description:
          'Catat terapi, pantau pengingat obat, dan terhubung dengan komunitas kesehatan.',
      color: Color(0xFF0A7AC1),
      bgColor: Color(0xFFE3F2FD),
      features: ['Pengingat obat', 'Riwayat terapi', 'Komunitas'],
    ),
    _RoleData(
      icon: Icons.local_pharmacy_rounded,
      title: 'Apoteker',
      subtitle: 'Tenaga Medis',
      subtitleIcon: Icons.medical_services_rounded,
      description:
          'Akses dashboard konsultan dan bantu pasien secara realtime.',
      color: Color(0xFF0D9488),
      bgColor: Color(0xFFE0F2F1),
      features: ['Dashboard pasien', 'Konsultasi live', 'Laporan terapi'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _roles.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 120),
      ),
    );
    _scaleAnims = _controllers
        .map(
          (c) => Tween<double>(
            begin: 1.0,
            end: 0.97,
          ).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)),
        )
        .toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  void _onTap(BuildContext context, int index) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => FadeTransition(
          opacity: anim,
          child: index == 0
              ? const RegisterPatientScreen()
              : const RegisterPharmacistScreen(),
        ),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Judul ────────────────────────────────────────
        const Text(
          'Daftar Sebagai',
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

        // ── Role Cards ───────────────────────────────────
        ...List.generate(_roles.length, (i) {
          final role = _roles[i];
          final isSelected = _selectedIndex == i;

          return Padding(
            padding: EdgeInsets.only(bottom: i < _roles.length - 1 ? 12 : 0),
            child: AnimatedBuilder(
              animation: _scaleAnims[i],
              builder: (_, child) =>
                  Transform.scale(scale: _scaleAnims[i].value, child: child),
              child: GestureDetector(
                onTapDown: (_) {
                  setState(() => _selectedIndex = i);
                  _controllers[i].forward();
                },
                onTapUp: (_) {
                  _controllers[i].reverse();
                  _onTap(context, i);
                },
                onTapCancel: () {
                  _controllers[i].reverse();
                  setState(() => _selectedIndex = null);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? role.bgColor : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? role.color : Colors.grey.shade200,
                      width: isSelected ? 2.0 : 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? role.color.withOpacity(0.15)
                            : Colors.black.withOpacity(0.04),
                        blurRadius: isSelected ? 18 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Ikon
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? role.color
                              : role.color.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          role.icon,
                          color: isSelected ? Colors.white : role.color,
                          size: 26,
                        ),
                      ),

                      const SizedBox(width: 14),

                      // Teks
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Badge subtitle
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: role.color.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    role.subtitleIcon,
                                    size: 10,
                                    color: role.color,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    role.subtitle,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: role.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              role.title,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? role.color
                                    : const Color(0xFF1A1A2E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              role.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Arrow
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: isSelected ? role.color : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 20),

        // ── Social Login ─────────────────────────────────
        const AuthBottomSection(),
      ],
    );
  }
}

class _RoleData {
  final IconData icon;
  final String title;
  final String subtitle;
  final IconData subtitleIcon;
  final String description;
  final Color color;
  final Color bgColor;
  final List<String> features;

  const _RoleData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.subtitleIcon,
    required this.description,
    required this.color,
    required this.bgColor,
    required this.features,
  });
}
