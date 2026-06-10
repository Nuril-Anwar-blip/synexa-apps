import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'global.dart';
import 'modules/dahsboard/dashboard_screen.dart';
import 'modules/pairing/pairing_screen.dart';
import 'services/local/auth_local_service.dart';
import 'services/remote/background_service.dart';
import 'styles/themes/app_theme.dart';

// Top-level function, bukan method class
// @pragma('vm:entry-point')
// void backgroundServiceEntryPoint(ServiceInstance service) async {
//   BackgroundService.onStart(service);
// }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_PUBLISHABLE_KEY']!,
  );
  await Global.init();

  final localSession = await AuthLocalService.getSession();
  final supabaseSession = Supabase.instance.client.auth.currentSession;

  String? userId;

  // Prioritas ambil dari Supabase session, kalau null pakai lokal
  if (supabaseSession?.user != null) {
    userId = supabaseSession!.user.id;
  } else if (localSession != null && localSession['user_id'] != null) {
    userId = localSession['user_id'] as String;
  }

  if (userId != null) {
    runApp(MyApp(home: DashboardScreen(userId: userId)));
  } else {
    runApp(MyApp(home: PairingScreen()));
  }
}

class MyApp extends StatelessWidget {
  final Widget home;
  const MyApp({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'IStroke', theme: AppTheme.data, home: home);
  }
}
