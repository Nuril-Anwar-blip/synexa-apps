
/// ====================================================================
/// File: quick_settings_sheet.dart
/// --------------------------------------------------------------------
/// Widget QuickSettingsSheet - Bottom Sheet Pengaturan Cepat
///
/// Dokumen ini berisi widget bottom sheet yang dapat diakses dari
/// tombol pengaturan (tune icon) di AppBar mana pun.
///
/// Fitur pengaturan:
/// 1. Theme Toggle - Switch antara mode Light/Dark
/// 2. Font Size - Slider untuk ukuran font (80% - 150%)
/// 3. Font Family - Pilihan jenis font (Poppins, Inter, Roboto, dll)
/// 4. Language - Pilihan bahasa (English, Indonesia, Melayu)
///
/// Cara Penggunaan:
///   QuickSettingsSheet.show(context);
///
/// Author: Tim Developer Synexa
/// ====================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';

/// Quick Settings Bottom Sheet - accessible from any screen's AppBar
class QuickSettingsSheet extends StatefulWidget {
  const QuickSettingsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QuickSettingsSheet(),
    );
  }

  @override
  State<QuickSettingsSheet> createState() => _QuickSettingsSheetState();
}

class _QuickSettingsSheetState extends State<QuickSettingsSheet> {
  final List<String> _fonts = [
    'Poppins',
    'Inter',
    'Roboto',
    'Lato',
    'Open Sans',
  ];
  final List<Map<String, String>> _languages = [
    {'code': 'id', 'name': 'Indonesia', 'flag': '🇮🇩'},
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'ms', 'name': 'Melayu', 'flag': '🇲🇾'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1C1E);
    final subTextColor = isDark ? Colors.white54 : Colors.black45;

    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, langProvider, _) {
        return Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 20,
            right: 20,
            top: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.teal.shade400, Colors.teal.shade700],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    langProvider.translate({
                      'id': 'Pengaturan Cepat',
                      'en': 'Quick Settings',
                      'ms': 'Tetapan Pantas',
                    }),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: subTextColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Theme Toggle ──
              _SectionLabel(
                label: langProvider.translate({
                  'id': 'Tema',
                  'en': 'Theme',
                  'ms': 'Tema',
                }),
                icon: Icons.palette_rounded,
                color: Colors.purple,
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _ThemeCard(
                    label: langProvider.translate({
                      'id': 'Terang',
                      'en': 'Light',
                      'ms': 'Cerah',
                    }),
                    icon: Icons.light_mode_rounded,
                    iconColor: Colors.amber,
                    isSelected: !themeProvider.isDarkMode,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _ThemeCard(
                    label: langProvider.translate({
                      'id': 'Gelap',
                      'en': 'Dark',
                      'ms': 'Gelap',
                    }),
                    icon: Icons.dark_mode_rounded,
                    iconColor: Colors.indigo,
                    isSelected: themeProvider.isDarkMode,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Font Size ──
              _SectionLabel(
                label: langProvider.translate({
                  'id': 'Ukuran Font',
                  'en': 'Font Size',
                  'ms': 'Saiz Fon',
                }),
                icon: Icons.format_size_rounded,
                color: Colors.green,
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [0.8, 1.0, 1.2, 1.4].map((size) {
                  final labels = {0.8: 'S', 1.0: 'M', 1.2: 'L', 1.4: 'XL'};
                  final isSelected = themeProvider.fontSize == size;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => themeProvider.setFontSize(size),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.teal
                              : (isDark
                                    ? Colors.white10
                                    : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.teal
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'A',
                              style: TextStyle(
                                fontSize: 10.0 * size + 4,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                          ? Colors.white70
                                          : Colors.black54),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              labels[size]!,
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected
                                    ? Colors.white70
                                    : (isDark
                                          ? Colors.white38
                                          : Colors.black38),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // ── Font Family ──
              _SectionLabel(
                label: langProvider.translate({
                  'id': 'Jenis Font',
                  'en': 'Font Style',
                  'ms': 'Gaya Fon',
                }),
                icon: Icons.font_download_rounded,
                color: Colors.blue,
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _fonts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final font = _fonts[index];
                    final isSelected = themeProvider.fontFamily == font;
                    return GestureDetector(
                      onTap: () => themeProvider.setFontFamily(font),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.teal
                              : (isDark
                                    ? Colors.white10
                                    : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isSelected
                                ? Colors.teal
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          font,
                          style: GoogleFonts.getFont(
                            font,
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // ── Language ──
              _SectionLabel(
                label: langProvider.translate({
                  'id': 'Bahasa',
                  'en': 'Language',
                  'ms': 'Bahasa',
                }),
                icon: Icons.language_rounded,
                color: Colors.orange,
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              Row(
                children: _languages.map((lang) {
                  final isSelected =
                      langProvider.currentLanguage == lang['code'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => langProvider.setLanguage(lang['code']!),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.teal
                              : (isDark
                                    ? Colors.white10
                                    : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.teal
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              lang['flag']!,
                              style: const TextStyle(fontSize: 22),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lang['name']!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                          ? Colors.white70
                                          : Colors.black54),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _SectionLabel({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ],
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _ThemeCard({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.teal.withOpacity(0.15)
                : (isDark ? Colors.white10 : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? Colors.teal : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.teal : iconColor, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Colors.teal
                      : (isDark ? Colors.white70 : Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
