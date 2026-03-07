/// ====================================================================
/// File: settings_screen.dart
/// --------------------------------------------------------------------
/// Layar Pengaturan Aplikasi (Settings Page)
/// 
/// Dokumen ini berisi halaman pengaturan lengkap yang dapat diakses
/// dari menu profil atau tombol pengaturan.
/// 
/// Fitur yang tersedia:
/// 
/// 1. Tema (Theme):
///    - Pilihan mode Light/Dark
///    - Toggle switch untuk mengubah tema
/// 
/// 2. Bahasa (Language):
///    - Pilihan bahasa: English, Indonesia, Melayu
///    - Dropdown/radio button untuk memilih bahasa
/// 
/// 3. Ukuran Font (Font Size):
///    - Slider untuk mengatur ukuran font (80% - 150%)
///    - Preview ukuran font
/// 
/// 4. Jenis Font (Font Family):
///    - Pilihan: Default, Roboto, Poppins, Montserrat, Serif
/// 
/// 5. Informasi Akun:
///    - Nama pengguna
///    - Email
///    - Tombol logout
/// 
/// Menggunakan:
/// - Consumer2<ThemeProvider, LanguageProvider> untuk akses data
/// - SliverAppBar dengan efek expandable
/// - Section cards untuk pengaturan
/// 
/// Author: Tim Developer Synexa
/// ====================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, langProvider, _) {
        final isDark = themeProvider.isDarkMode;
        final theme = Theme.of(context);

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // ── Beautiful SliverAppBar ──
              SliverAppBar(
                expandedHeight: 160,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                  title: Text(
                    langProvider.translate({
                      'id': 'Pengaturan',
                      'en': 'Settings',
                      'ms': 'Tetapan',
                    }),
                    style: const TextStyle(
                      fontSize: 22,
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
                            ? [const Color(0xFF1A237E), const Color(0xFF00695C)]
                            : [Colors.teal.shade600, Colors.teal.shade300],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -30,
                          top: -30,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 60,
                          bottom: -20,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.06),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 24, top: 20),
                            child: Icon(
                              Icons.settings_rounded,
                              size: 64,
                              color: Colors.white.withOpacity(0.15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Body Content ──
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Appearance Section ──
                    _SectionHeader(
                      label: langProvider.translate({
                        'id': 'Tampilan',
                        'en': 'Appearance',
                        'ms': 'Penampilan',
                      }),
                    ),
                    const SizedBox(height: 8),

                    // Theme Toggle Cards
                    _SettingsCard(
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SettingsTileHeader(
                            icon: Icons.palette_rounded,
                            iconBg: Colors.purple.shade400,
                            label: langProvider.translate({
                              'id': 'Mode Tema',
                              'en': 'Theme Mode',
                              'ms': 'Mod Tema',
                            }),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _ThemeModeCard(
                                title: langProvider.translate({
                                  'id': 'Terang',
                                  'en': 'Light',
                                  'ms': 'Cerah',
                                }),
                                icon: Icons.light_mode_rounded,
                                gradient: const [
                                  Color(0xFFFFF176),
                                  Color(0xFFFFCA28),
                                ],
                                isSelected: !themeProvider.isDarkMode,
                                onTap: () =>
                                    themeProvider.setThemeMode(ThemeMode.light),
                              ),
                              const SizedBox(width: 12),
                              _ThemeModeCard(
                                title: langProvider.translate({
                                  'id': 'Gelap',
                                  'en': 'Dark',
                                  'ms': 'Gelap',
                                }),
                                icon: Icons.dark_mode_rounded,
                                gradient: const [
                                  Color(0xFF3949AB),
                                  Color(0xFF1A237E),
                                ],
                                isSelected: themeProvider.isDarkMode,
                                onTap: () =>
                                    themeProvider.setThemeMode(ThemeMode.dark),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Typography Section ──
                    _SectionHeader(
                      label: langProvider.translate({
                        'id': 'Tipografi',
                        'en': 'Typography',
                        'ms': 'Tipografi',
                      }),
                    ),
                    const SizedBox(height: 8),

                    _SettingsCard(
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Font Family
                          _SettingsTileHeader(
                            icon: Icons.font_download_rounded,
                            iconBg: Colors.blue.shade400,
                            label: langProvider.translate({
                              'id': 'Jenis Font',
                              'en': 'Font Family',
                              'ms': 'Keluarga Fon',
                            }),
                          ),
                          const SizedBox(height: 12),
                          _FontFamilyPicker(
                            themeProvider: themeProvider,
                            isDark: isDark,
                          ),

                          Divider(
                            height: 28,
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),

                          // Font Size
                          _SettingsTileHeader(
                            icon: Icons.format_size_rounded,
                            iconBg: Colors.green.shade500,
                            label: langProvider.translate({
                              'id': 'Ukuran Font',
                              'en': 'Font Size',
                              'ms': 'Saiz Fon',
                            }),
                          ),
                          const SizedBox(height: 12),
                          _FontSizePicker(
                            themeProvider: themeProvider,
                            isDark: isDark,
                            langProvider: langProvider,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Language Section ──
                    _SectionHeader(
                      label: langProvider.translate({
                        'id': 'Bahasa',
                        'en': 'Language',
                        'ms': 'Bahasa',
                      }),
                    ),
                    const SizedBox(height: 8),

                    _SettingsCard(
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SettingsTileHeader(
                            icon: Icons.language_rounded,
                            iconBg: Colors.orange.shade400,
                            label: langProvider.translate({
                              'id': 'Pilih Bahasa',
                              'en': 'Select Language',
                              'ms': 'Pilih Bahasa',
                            }),
                          ),
                          const SizedBox(height: 12),
                          _LanguagePicker(
                            langProvider: langProvider,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Preview card
                    _SettingsCard(
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SettingsTileHeader(
                            icon: Icons.preview_rounded,
                            iconBg: Colors.teal.shade500,
                            label: langProvider.translate({
                              'id': 'Pratinjau',
                              'en': 'Preview',
                              'ms': 'Pratonton',
                            }),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  langProvider.translate({
                                    'id': 'Judul Contoh',
                                    'en': 'Sample Title',
                                    'ms': 'Tajuk Contoh',
                                  }),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  langProvider.translate({
                                    'id':
                                        'Ini adalah contoh teks dengan pengaturan tipografi yang telah Anda pilih.',
                                    'en':
                                        'This is sample text with your selected typography settings.',
                                    'ms':
                                        'Ini adalah teks contoh dengan tetapan tipografi yang anda pilih.',
                                  }),
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
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

// ─────────────────────────────────────────────────────────────────────────────
// Helper Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Colors.teal.shade600,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _SettingsCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SettingsTileHeader extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String label;
  const _SettingsTileHeader({
    required this.icon,
    required this.iconBg,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBg.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconBg),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleMedium?.color,
          ),
        ),
      ],
    );
  }
}

class _ThemeModeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Color> gradient;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeModeCard({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : Colors.grey.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: isSelected ? Colors.white : Colors.grey,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey,
                  fontSize: 13,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Active',
                    style: TextStyle(fontSize: 11, color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FontFamilyPicker extends StatelessWidget {
  final ThemeProvider themeProvider;
  final bool isDark;
  const _FontFamilyPicker({required this.themeProvider, required this.isDark});

  static const _fonts = ['Poppins', 'Inter', 'Roboto', 'Lato', 'Open Sans'];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _fonts.map((font) {
        final isSelected = themeProvider.fontFamily == font;
        return GestureDetector(
          onTap: () => themeProvider.setFontFamily(font),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [Colors.teal.shade400, Colors.teal.shade700],
                    )
                  : null,
              color: isSelected
                  ? null
                  : (isDark ? Colors.white10 : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              font,
              style: GoogleFonts.getFont(
                font,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FontSizePicker extends StatelessWidget {
  final ThemeProvider themeProvider;
  final LanguageProvider langProvider;
  final bool isDark;

  const _FontSizePicker({
    required this.themeProvider,
    required this.langProvider,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final sizes = [
      {'value': 0.8, 'id': 'Kecil', 'en': 'Small', 'ms': 'Kecil'},
      {'value': 1.0, 'id': 'Normal', 'en': 'Normal', 'ms': 'Normal'},
      {'value': 1.2, 'id': 'Besar', 'en': 'Large', 'ms': 'Besar'},
      {
        'value': 1.4,
        'id': 'Sangat Besar',
        'en': 'X-Large',
        'ms': 'Sangat Besar',
      },
    ];

    return Row(
      children: sizes.map((s) {
        final sizeVal = s['value'] as double;
        final isSelected = themeProvider.fontSize == sizeVal;
        final label = s[langProvider.currentLanguage] ?? s['id'];
        return Expanded(
          child: GestureDetector(
            onTap: () => themeProvider.setFontSize(sizeVal),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [Colors.green.shade400, Colors.teal.shade600],
                      )
                    : null,
                color: isSelected
                    ? null
                    : (isDark ? Colors.white10 : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'A',
                    style: TextStyle(
                      fontSize: 10.0 + sizeVal * 8,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white54 : Colors.black45),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label as String,
                    style: TextStyle(
                      fontSize: 9,
                      color: isSelected
                          ? Colors.white70
                          : (isDark ? Colors.white38 : Colors.black38),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _LanguagePicker extends StatelessWidget {
  final LanguageProvider langProvider;
  final bool isDark;

  const _LanguagePicker({required this.langProvider, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final langs = [
      {
        'code': 'id',
        'name': 'Indonesia',
        'flag': '🇮🇩',
        'native': 'Bahasa Indonesia',
      },
      {'code': 'en', 'name': 'English', 'flag': '🇺🇸', 'native': 'English'},
      {
        'code': 'ms',
        'name': 'Malay',
        'flag': '🇲🇾',
        'native': 'Bahasa Melayu',
      },
    ];

    return Column(
      children: langs.map((lang) {
        final isSelected = langProvider.currentLanguage == lang['code'];
        return GestureDetector(
          onTap: () => langProvider.setLanguage(lang['code']!),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.teal.withOpacity(0.12)
                  : (isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey.shade50),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? Colors.teal : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Text(lang['flag']!, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang['name']!,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isSelected
                            ? Colors.teal
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                    Text(
                      lang['native']!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.teal,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
