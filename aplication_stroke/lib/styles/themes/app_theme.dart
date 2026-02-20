import 'package:flutter/material.dart';

import '../colors/app_color.dart';
import 'widgets/app_app_bar_theme.dart';
import 'widgets/app_elevated_button_theme.dart';
import 'widgets/app_outlined_button_theme.dart';
import 'widgets/app_progress_indicator_theme.dart';
import 'widgets/app_text_selection_theme.dart';
import 'widgets/app_input_decoration_theme.dart';

/// Konfigurasi tema aplikasi (Light & Dark Theme).
/// Mengatur tampilan komponen UI seperti tombol, input, dan app bar.
class AppTheme {
  const AppTheme._();

  /// Tema terang default.
  static ThemeData get data => ThemeData(
    primarySwatch: AppColor.primary,
    scaffoldBackgroundColor: AppColor.background,
    brightness: Brightness.light,
    appBarTheme: AppAppBarTheme.data,
    elevatedButtonTheme: AppElevatedButtonTheme.data,
    outlinedButtonTheme: AppOutlinedButtonTheme.data,
    progressIndicatorTheme: AppProgressIndicatorTheme.data,
    textSelectionTheme: AppTextSelectionTheme.data,
    inputDecorationTheme: AppInputDecorationTheme.data,
    splashFactory: InkRipple.splashFactory,
    dialogTheme: DialogThemeData(backgroundColor: AppColor.text),
  );

  /// Tema gelap (Dark Mode).
  static ThemeData get darkData => ThemeData(
    primarySwatch: AppColor.primary,
    scaffoldBackgroundColor: Colors.grey[900],
    brightness: Brightness.dark,
    appBarTheme: AppAppBarTheme.darkData,
    elevatedButtonTheme: AppElevatedButtonTheme.data,
    outlinedButtonTheme: AppOutlinedButtonTheme.data,
    progressIndicatorTheme: AppProgressIndicatorTheme.data,
    textSelectionTheme: AppTextSelectionTheme.data,
    inputDecorationTheme: AppInputDecorationTheme.darkData,
    splashFactory: InkRipple.splashFactory,
    dialogTheme: DialogThemeData(backgroundColor: Colors.grey[800]),
    cardColor: Colors.grey[800],
    dividerColor: Colors.grey[700],
  );
}

