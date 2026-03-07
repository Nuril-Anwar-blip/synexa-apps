import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  /// Menampilkan dialog untuk memilih jenis font
  void _showFontDialog(BuildContext context, ThemeProvider themeProvider) {
    final fonts = ['Poppins', 'Inter', 'Roboto', 'Lato', 'Open Sans'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Jenis Font'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: fonts
              .map(
                (font) => ListTile(
                  title: Text(font, style: GoogleFonts.getFont(font)),
                  trailing: themeProvider.fontFamily == font
                      ? const Icon(Icons.check, color: Colors.teal)
                      : null,
                  onTap: () {
                    themeProvider.setFontFamily(font);
                    Navigator.pop(context);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  /// Menampilkan dialog untuk mengatur ukuran font
  void _showFontSizeDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Ukuran Teks'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Sesuaikan kenyamanan membaca Anda'),
                const SizedBox(height: 20),
                Slider(
                  value: themeProvider.fontSize,
                  min: 0.8,
                  max: 1.4,
                  divisions: 3,
                  label: themeProvider.fontSize == 0.8
                      ? 'Kecil'
                      : (themeProvider.fontSize == 1.0
                          ? 'Normal'
                          : (themeProvider.fontSize == 1.2
                              ? 'Besar'
                              : 'Sangat Besar')),
                  onChanged: (val) {
                    themeProvider.setFontSize(val);
                    setDialogState(() {});
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('A', style: TextStyle(fontSize: 12)),
                    Text('A', style: TextStyle(fontSize: 16)),
                    Text('A', style: TextStyle(fontSize: 20)),
                    Text('A', style: TextStyle(fontSize: 24)),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Menampilkan dialog untuk memilih bahasa
  void _showLanguageDialog(BuildContext context, LanguageProvider langProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Bahasa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption(
              context,
              langProvider,
              code: 'id',
              name: 'Bahasa Indonesia',
              flag: '🇮🇩',
            ),
            _buildLanguageOption(
              context,
              langProvider,
              code: 'en',
              name: 'English',
              flag: '🇺🇸',
            ),
            _buildLanguageOption(
              context,
              langProvider,
              code: 'ms',
              name: 'Melayu',
              flag: '🇲🇾',
            ),
          ],
        ),
      ),
    );
  }

  /// Widget pembantu untuk opsi bahasa dalam dialog
  Widget _buildLanguageOption(
    BuildContext context,
    LanguageProvider langProvider, {
    required String code,
    required String name,
    required String flag,
  }) {
    final isSelected = langProvider.currentLanguage == code;
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(name),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.teal) : null,
      onTap: () {
        langProvider.setLanguage(code);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bahasa diubah ke $name')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<LanguageProvider>(
          builder: (context, lang, _) => Text(
            lang.translate({
              'id': 'Pengaturan Aplikasi',
              'en': 'App Settings',
              'ms': 'Tetapan Aplikasi',
            }),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Column(
              children: [
                Consumer<LanguageProvider>(
                  builder: (context, langProvider, _) {
                    return ListTile(
                      leading: const Icon(
                        Icons.language_rounded,
                        color: Colors.orange,
                      ),
                      title: Text(langProvider.translate({
                        'id': 'Bahasa',
                        'en': 'Language',
                        'ms': 'Bahasa',
                      })),
                      subtitle: Text(langProvider.languageName),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showLanguageDialog(context, langProvider),
                    );
                  },
                ),
                const Divider(height: 1),
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) {
                    return Column(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.font_download_rounded,
                            color: Colors.blue,
                          ),
                          title: const Text('Jenis Font'),
                          subtitle: Text(themeProvider.fontFamily),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showFontDialog(context, themeProvider),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.format_size_rounded,
                            color: Colors.green,
                          ),
                          title: const Text('Ukuran Teks'),
                          subtitle: Text(
                            themeProvider.fontSize == 0.8
                                ? 'Kecil'
                                : (themeProvider.fontSize == 1.0
                                    ? 'Normal'
                                    : (themeProvider.fontSize == 1.2
                                        ? 'Besar'
                                        : 'Sangat Besar')),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showFontSizeDialog(context, themeProvider),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          secondary: Icon(
                            themeProvider.isDarkMode
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            color: themeProvider.isDarkMode
                                ? Colors.purple
                                : Colors.amber,
                          ),
                          title: Text(
                            themeProvider.isDarkMode
                                ? 'Mode Gelap'
                                : 'Mode Terang',
                          ),
                          value: themeProvider.isDarkMode,
                          onChanged: (val) => themeProvider.toggleTheme(),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
