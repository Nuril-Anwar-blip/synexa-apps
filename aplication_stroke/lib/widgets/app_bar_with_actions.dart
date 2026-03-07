import 'package:flutter/material.dart';
import 'quick_settings_sheet.dart';

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
    return AppBar(
      title: Text(title),
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.tune_rounded),
          tooltip: 'Quick Settings',
          onPressed: () => QuickSettingsSheet.show(context),
        ),
        if (actions != null) ...actions!,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
