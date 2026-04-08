// ====================================================================
// File: debug_preview.dart
// Debug Preview — Menampilkan semua screen utama untuk review
// ====================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'styles/themes/app_theme.dart';

// Import semua screen yang ingin di-preview
import 'modules/exercise/exercise_screen.dart';
import 'modules/medication_reminder/medication_reminder_screen.dart';
import 'modules/dashboard/widgets/enhanced_home_tab.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _DebugApp());
}

class _DebugApp extends StatelessWidget {
  const _DebugApp();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (_, themeP, langP, __) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Debug Preview',
          theme: AppTheme.getTheme(
            isDark: false,
            fontFamily: themeP.fontFamily,
            fontSizeScale: themeP.fontSize,
          ),
          darkTheme: AppTheme.getTheme(
            isDark: true,
            fontFamily: themeP.fontFamily,
            fontSizeScale: themeP.fontSize,
          ),
          themeMode: themeP.themeMode,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(themeP.fontSize)),
            child: child!,
          ),
          home: const _DebugHome(),
        ),
      ),
    );
  }
}

class _DebugHome extends StatefulWidget {
  const _DebugHome();

  @override
  State<_DebugHome> createState() => _DebugHomeState();
}

class _DebugHomeState extends State<_DebugHome> {
  int _currentIndex = 0;

  final _pages = const [
    _PreviewHomePage(),
    _PreviewExercisePage(),
    _PreviewMedicationPage(),
    _PreviewSettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final themeP = context.watch<ThemeProvider>();
    final isDark = themeP.isDarkMode;

    return Scaffold(
      extendBody: true,
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        margin: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.of(context).padding.bottom + 12,
        ),
        height: 62,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            _navItem(0, Icons.home_rounded, 'Home', isDark),
            _navItem(1, Icons.fitness_center_rounded, 'Exercise', isDark),
            _navItem(2, Icons.medication_rounded, 'Obat', isDark),
            _navItem(3, Icons.settings_rounded, 'Settings', isDark),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label, bool isDark) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    colors: [Color(0xFF009688), Color(0xFF00695C)],
                  )
                : null,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive
                    ? Colors.white
                    : (isDark ? Colors.white38 : Colors.grey.shade400),
              ),
              if (isActive)
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Preview wrappers
class _PreviewHomePage extends StatelessWidget {
  const _PreviewHomePage();
  @override
  Widget build(BuildContext context) => const EnhancedHomeTab();
}

class _PreviewExercisePage extends StatelessWidget {
  const _PreviewExercisePage();
  @override
  Widget build(BuildContext context) => const ExerciseScreenV2(isPreview: true);
}

class _PreviewMedicationPage extends StatelessWidget {
  const _PreviewMedicationPage();
  @override
  Widget build(BuildContext context) =>
      const MedicationReminderScreenV2(isPreview: true);
}

class _PreviewSettingsPage extends StatelessWidget {
  const _PreviewSettingsPage();
  @override
  Widget build(BuildContext context) {
    final themeP = context.watch<ThemeProvider>();
    final langP = context.watch<LanguageProvider>();
    final isDark = themeP.isDarkMode;
    final fs = themeP.fontSize;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0F1E)
          : const Color(0xFFF0F4FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '⚙️ Pengaturan',
                style: TextStyle(
                  fontSize: 28 * fs,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 24),

              // Theme
              _SettingCard(
                title: 'Tema Aplikasi',
                icon: Icons.palette_rounded,
                color: Colors.purple,
                isDark: isDark,
                child: Row(
                  children: [
                    _ThemeBtn(
                      label: 'Terang',
                      icon: Icons.light_mode_rounded,
                      selected: !isDark,
                      onTap: () => themeP.setThemeMode(ThemeMode.light),
                    ),
                    const SizedBox(width: 10),
                    _ThemeBtn(
                      label: 'Gelap',
                      icon: Icons.dark_mode_rounded,
                      selected: isDark,
                      onTap: () => themeP.setThemeMode(ThemeMode.dark),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Font Size
              _SettingCard(
                title: 'Ukuran Font',
                icon: Icons.format_size_rounded,
                color: Colors.green,
                isDark: isDark,
                child: Row(
                  children: [
                    for (final entry in {
                      0.85: 'Kecil',
                      1.0: 'Normal',
                      1.2: 'Besar',
                      1.4: 'XL',
                    }.entries)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => themeP.setFontSize(entry.key),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: (themeP.fontSize - entry.key).abs() < 0.05
                                  ? Colors.teal
                                  : (isDark
                                        ? Colors.white10
                                        : Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'A',
                                  style: TextStyle(
                                    fontSize: 10 + entry.key * 6,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        (themeP.fontSize - entry.key).abs() <
                                            0.05
                                        ? Colors.white
                                        : Colors.grey,
                                  ),
                                ),
                                Text(
                                  entry.value,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color:
                                        (themeP.fontSize - entry.key).abs() <
                                            0.05
                                        ? Colors.white70
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Font Family
              _SettingCard(
                title: 'Jenis Font',
                icon: Icons.font_download_rounded,
                color: Colors.blue,
                isDark: isDark,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['Poppins', 'Inter', 'Roboto', 'Lato', 'Open Sans']
                      .map(
                        (f) => GestureDetector(
                          onTap: () => themeP.setFontFamily(f),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: themeP.fontFamily == f
                                  ? Colors.teal
                                  : (isDark
                                        ? Colors.white10
                                        : Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              f,
                              style: TextStyle(
                                fontSize: 13,
                                color: themeP.fontFamily == f
                                    ? Colors.white
                                    : (isDark
                                          ? Colors.white70
                                          : Colors.black54),
                                fontWeight: themeP.fontFamily == f
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 14),

              // Language
              _SettingCard(
                title: 'Bahasa',
                icon: Icons.language_rounded,
                color: Colors.orange,
                isDark: isDark,
                child: Row(
                  children: [
                    for (final l in [
                      {'code': 'id', 'flag': '🇮🇩', 'name': 'Indonesia'},
                      {'code': 'en', 'flag': '🇬🇧', 'name': 'English'},
                      {'code': 'ms', 'flag': '🇲🇾', 'name': 'Melayu'},
                    ])
                      Expanded(
                        child: GestureDetector(
                          onTap: () => langP.setLanguage(l['code']!),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: langP.currentLanguage == l['code']
                                  ? Colors.teal
                                  : (isDark
                                        ? Colors.white10
                                        : Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  l['flag']!,
                                  style: const TextStyle(fontSize: 22),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l['name']!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: langP.currentLanguage == l['code']
                                        ? Colors.white
                                        : Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  const _SettingCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.child,
  });
  final String title;
  final IconData icon;
  final Color color;
  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ThemeBtn extends StatelessWidget {
  const _ThemeBtn({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? Colors.teal : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : Colors.grey,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
