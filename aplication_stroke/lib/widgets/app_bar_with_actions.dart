import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../modules/settings/settings_screen.dart';

class AppBarWithActions extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showThemeToggle;
  final bool showLanguageToggle;

  const AppBarWithActions({
    super.key,
    required this.title,
    this.actions,
    this.showThemeToggle = true,
    this.showLanguageToggle = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      title: Text(title),
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          tooltip: 'Pengaturan',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
        if (actions != null) ...actions!,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
