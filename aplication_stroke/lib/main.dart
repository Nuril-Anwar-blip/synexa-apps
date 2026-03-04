import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:aplication_stroke/global.dart';
import 'package:aplication_stroke/providers/theme_provider.dart';
import 'package:aplication_stroke/providers/language_provider.dart';
import 'package:aplication_stroke/styles/themes/app_theme.dart';
import 'package:aplication_stroke/auth/widgets/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi localization untuk format tanggal (id_ID)
  try {
    await initializeDateFormatting('id_ID', null);
  } catch (e) {
    debugPrint('Intl initialization error: $e');
  }

  // Inisialisasi layanan global (Supabase, Env, dll)
  try {
    await Global.init();
  } catch (e) {
    debugPrint('Initialization error: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, languageProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Integrated Stroke', // Changed title
          theme: AppTheme.getTheme(
            isDark: false,
            fontFamily: themeProvider.fontFamily,
            fontSizeScale: themeProvider.fontSize,
          ),
          darkTheme: AppTheme.getTheme(
            isDark: true,
            fontFamily: themeProvider.fontFamily,
            fontSizeScale: themeProvider.fontSize,
          ),
          themeMode: themeProvider.themeMode,
          locale:
              languageProvider.locale, // Used languageProvider from Consumer2
          supportedLocales: const [Locale('en'), Locale('id'), Locale('ms')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home:
              const SplashScreen(), // Kept SplashScreen as it handles login check
        );
      },
    );
  }
}
