import 'package:flutter/material.dart';
import 'modules/rehab/rehab_dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _DebugApp());
}

class _DebugApp extends StatelessWidget {
  const _DebugApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Preview Rehab Dashboard',
      home: RehabDashboardScreen(),
    );
  }
}
