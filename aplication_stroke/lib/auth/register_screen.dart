import 'package:flutter/material.dart';

import 'auth_layout.dart';
import 'register_patient_screen.dart';
import 'register_pharmacist_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Buat Akun',
      desc: 'Pilih peran Anda dan mulai perjalanan kesehatan bersama kami.',
      marginTop: 80,
      showBackButton: true,
      onBack: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      ),
      formField: const _RegisterRoleSelector(),
    );
  }
}

class _RegisterRoleSelector extends StatefulWidget {
  const _RegisterRoleSelector();

  @override
  State<_RegisterRoleSelector> createState() => _RegisterRoleSelectorState();
}

class _RegisterRoleSelectorState extends State<_RegisterRoleSelector>
    with TickerProviderStateMixin {
  int? _selectedIndex;
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnims;

  final _roles = const [
    _RoleData(
      icon: Icons.health_and_safety_rounded,
      title: 'Pasien',
      description:
          'Catat terapi, pantau pengingat obat, dan terhubung dengan komunitas kesehatan.',
      color: Color(0xFF0A7AC1),
      bgColor: Color(0xFFE3F2FD),
      badgeLabel: 'Pengguna Umum',
      badgeIcon: Icons.person_rounded,
      features: ['Pengingat obat', 'Riwayat terapi', 'Komunitas'],
    ),
    _RoleData(
      icon: Icons.local_pharmacy_rounded,
      title: 'Apoteker',
      description:
          'Akses dashboard konsultan dan bantu pasien secara realtime.',
      color: Color(0xFF0D9488),
      bgColor: Color(0xFFE0F2F1),
      badgeLabel: 'Tenaga Medis',
      badgeIcon: Icons.medical_services_rounded,
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
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTap(BuildContext context, int index) {
    final role = _roles[index];
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
      children: [
        // Header teks
        const Text(
          'Daftar Sebagai',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A2E),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Pilih peran yang sesuai dengan Anda',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 20),

        // Role cards
        ...List.generate(_roles.length, (i) {
          final role = _roles[i];
          final isSelected = _selectedIndex == i;

          return Padding(
            padding: EdgeInsets.only(bottom: i < _roles.length - 1 ? 14 : 0),
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
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isSelected ? role.bgColor : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? role.color : Colors.grey.shade200,
                      width: isSelected ? 2.0 : 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? role.color.withOpacity(0.18)
                            : Colors.black.withOpacity(0.05),
                        blurRadius: isSelected ? 20 : 10,
                        offset: const Offset(0, 6),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Ikon dalam lingkaran
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? role.color
                                  : role.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              role.icon,
                              color: isSelected ? Colors.white : role.color,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Badge label
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: role.color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        role.badgeIcon,
                                        size: 10,
                                        color: role.color,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        role.badgeLabel,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: role.color,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  role.title,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected
                                        ? role.color
                                        : const Color(0xFF1A1A2E),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Arrow
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? role.color
                                  : Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 13,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Deskripsi
                      Text(
                        role.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Feature chips
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: role.features
                            .map(
                              (f) => _FeatureChip(
                                label: f,
                                color: role.color,
                                active: isSelected,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 20),

        // Divider dengan teks
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade200)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Sudah punya akun?',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey.shade200)),
          ],
        ),
        const SizedBox(height: 14),

        // Tombol Login
        OutlinedButton(
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            side: const BorderSide(color: Color(0xFF0A7AC1), width: 1.5),
            foregroundColor: const Color(0xFF0A7AC1),
          ),
          child: const Text(
            'Masuk ke Akun',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({
    required this.label,
    required this.color,
    required this.active,
  });

  final String label;
  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? color.withOpacity(0.12) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 11,
            color: active ? color : Colors.grey.shade400,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: active ? color : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleData {
  const _RoleData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.bgColor,
    required this.badgeLabel,
    required this.badgeIcon,
    required this.features,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final Color bgColor;
  final String badgeLabel;
  final IconData badgeIcon;
  final List<String> features;
}
