/// ====================================================================
/// File: settings_screen.dart
/// --------------------------------------------------------------------
/// Layar Pengaturan Aplikasi (Settings Page)
///
/// Dokumen ini berisi halaman pengaturan yang menampilkan:
/// - Profil pengguna (avatar, nama, email)
/// - Pengaturan: Dark Mode, Font Size, Language
/// - Tombol About dan Logout
///
/// Author: Tim Developer Synexa
/// ====================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import '../../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _supabase = Supabase.instance.client;
  String _userName = 'User';
  String _userEmail = 'user@example.com';
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      final data = await _supabase
          .from('users')
          .select('full_name, email, photo_url')
          .eq('id', userId)
          .maybeSingle();
      if (mounted && data != null) {
        setState(() {
          _userName = data['full_name']?.toString() ?? 'User';
          _userEmail = data['email']?.toString() ?? 'user@example.com';
          _photoUrl = data['photo_url']?.toString();
        });
      }
    } catch (_) {}
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await _supabase.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, langProvider, _) {
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // AppBar
              SliverAppBar(
                expandedHeight: 120,
                pinned: true,
                backgroundColor: isDark ? const Color(0xFF1E2A3A) : Colors.teal,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    langProvider.translate({
                      'id': 'Pengaturan',
                      'en': 'Settings',
                      'ms': 'Tetapan',
                    }),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [const Color(0xFF1E2A3A), const Color(0xFF0D47A1)]
                            : [Colors.teal.shade600, Colors.teal.shade400],
                      ),
                    ),
                  ),
                ),
              ),

              // Content
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad + 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Profile Card
                    _ProfileCard(
                      name: _userName,
                      email: _userEmail,
                      photoUrl: _photoUrl,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),

                    // Settings Card
                    _SettingsCard(
                      isDark: isDark,
                      children: [
                        // Dark Mode
                        _SettingsItem(
                          icon: Icons.dark_mode_rounded,
                          iconColor: Colors.indigo,
                          label: langProvider.translate({
                            'id': 'Mode Gelap',
                            'en': 'Dark Mode',
                            'ms': 'Mod Gelap',
                          }),
                          trailing: Switch(
                            value: themeProvider.isDarkMode,
                            onChanged: (value) {
                              themeProvider.setThemeMode(
                                value ? ThemeMode.dark : ThemeMode.light,
                              );
                            },
                            activeColor: Colors.teal,
                          ),
                          isDark: isDark,
                        ),
                        _Divider(isDark: isDark),

                        // Font Size
                        _SettingsItem(
                          icon: Icons.format_size_rounded,
                          iconColor: Colors.green,
                          label: langProvider.translate({
                            'id': 'Ukuran Font',
                            'en': 'Font Size',
                            'ms': 'Saiz Fon',
                          }),
                          trailing: Text(
                            '${(themeProvider.fontSize * 100).round()}%',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          isDark: isDark,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(56, 0, 8, 8),
                          child: Slider(
                            value: themeProvider.fontSize,
                            min: 0.8,
                            max: 1.5,
                            divisions: 7,
                            activeColor: Colors.teal,
                            onChanged: (value) {
                              themeProvider.setFontSize(value);
                            },
                          ),
                        ),
                        _Divider(isDark: isDark),

                        // Language
                        _SettingsItem(
                          icon: Icons.language_rounded,
                          iconColor: Colors.orange,
                          label: langProvider.translate({
                            'id': 'Bahasa',
                            'en': 'Language',
                            'ms': 'Bahasa',
                          }),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<String>(
                              value: langProvider.currentLanguage,
                              underline: const SizedBox(),
                              isDense: true,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 14,
                              ),
                              dropdownColor: isDark
                                  ? const Color(0xFF2D3A4A)
                                  : Colors.white,
                              items: const [
                                DropdownMenuItem(
                                  value: 'id',
                                  child: Text('Indonesia'),
                                ),
                                DropdownMenuItem(
                                  value: 'en',
                                  child: Text('English'),
                                ),
                                DropdownMenuItem(
                                  value: 'ms',
                                  child: Text('Melayu'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  langProvider.setLanguage(value);
                                }
                              },
                            ),
                          ),
                          isDark: isDark,
                        ),
                        _Divider(isDark: isDark),

                        // About
                        _SettingsItem(
                          icon: Icons.info_rounded,
                          iconColor: Colors.blue,
                          label: langProvider.translate({
                            'id': 'Tentang Aplikasi',
                            'en': 'About',
                            'ms': 'Tentang',
                          }),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: isDark ? Colors.white30 : Colors.black26,
                          ),
                          onTap: () {
                            showAboutDialog(
                              context: context,
                              applicationName: 'Synexa',
                              applicationVersion: '1.0.0',
                              applicationLegalese:
                                  '© 2024 Synexa - Stroke Recovery App',
                            );
                          },
                          isDark: isDark,
                        ),
                        _Divider(isDark: isDark),

                        // Logout
                        _SettingsItem(
                          icon: Icons.logout_rounded,
                          iconColor: Colors.red,
                          label: langProvider.translate({
                            'id': 'Keluar',
                            'en': 'Logout',
                            'ms': 'Log Keluar',
                          }),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: isDark ? Colors.white30 : Colors.black26,
                          ),
                          onTap: _logout,
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // App Version
                    Center(
                      child: Text(
                        'Synexa v1.0.0',
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black26,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Profile Card Widget
class _ProfileCard extends StatelessWidget {
  final String name;
  final String email;
  final String? photoUrl;
  final bool isDark;

  const _ProfileCard({
    required this.name,
    required this.email,
    this.photoUrl,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.teal.shade400, Colors.teal.shade600],
              ),
            ),
            padding: const EdgeInsets.all(3),
            child: ClipOval(
              child: photoUrl != null && photoUrl!.isNotEmpty
                  ? Image.network(
                      photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    )
                  : const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
            ),
          ),
          const SizedBox(width: 16),
          // Name & Email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Settings Card Container
class _SettingsCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;

  const _SettingsCard({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

/// Settings Item
class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDark;

  const _SettingsItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.trailing,
    this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            // Label
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            // Trailing
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

/// Divider
class _Divider extends StatelessWidget {
  final bool isDark;

  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 64,
      endIndent: 8,
      color: isDark ? Colors.white12 : Colors.black12,
    );
  }
}
