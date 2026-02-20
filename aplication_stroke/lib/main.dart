import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:aplication_stroke/global.dart';
import 'package:aplication_stroke/providers/theme_provider.dart';
import 'package:aplication_stroke/modules/auth/widgets/splash_screen.dart';

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
        // Tambahkan provider lain di sini jika ada di masa depan
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Stroke Care',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          primary: Colors.blue.shade700,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
      ),
      darkTheme: ThemeData.dark(useMaterial3: true),
      // SplashScreen menangani pengecekan login dan redirect
      home: const SplashScreen(),
    );
  }
}
