/// Entry point khusus dashboard admin desktop (Windows / macOS / Linux).
///
/// Jalankan:
///   flutter run -t lib/main_admin.dart -d windows
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'global.dart';
import 'modules/admin/admin_desktop_shell.dart';
import 'modules/admin/admin_login_screen.dart';
import 'modules/admin/services/admin_service.dart';
import 'utils/platform_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await Global.init(initNotifications: false);
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Stroke Admin',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A7AC1),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: const AdminBootstrap(),
    );
  }
}

class AdminBootstrap extends StatefulWidget {
  const AdminBootstrap({super.key});

  @override
  State<AdminBootstrap> createState() => _AdminBootstrapState();
}

class _AdminBootstrapState extends State<AdminBootstrap> {
  bool _checking = true;
  Widget? _screen;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    if (!PlatformLayout.isDesktop) {
      setState(() {
        _screen = const _DesktopOnlyGate();
        _checking = false;
      });
      return;
    }

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      setState(() {
        _screen = const AdminLoginScreen();
        _checking = false;
      });
      return;
    }

    final isAdmin = await AdminService().isCurrentUserAdmin();
    if (!mounted) return;
    setState(() {
      _screen = isAdmin
          ? const AdminDesktopShell()
          : const AdminLoginScreen();
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _screen!;
  }
}

class _DesktopOnlyGate extends StatelessWidget {
  const _DesktopOnlyGate();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.desktop_windows_rounded,
                  size: 64,
                  color: Color(0xFF0F172A),
                ),
                const SizedBox(height: 24),
                Text(
                  'Admin Console — Desktop Only',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Jalankan aplikasi admin di Windows, macOS, atau Linux.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
