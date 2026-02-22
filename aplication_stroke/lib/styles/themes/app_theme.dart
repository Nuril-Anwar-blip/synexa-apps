import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  /// Mengambil konfigurasi tema (ThemeData) berdasarkan preferensi pengguna.
  /// 
  /// [isDark] menentukan apakah menggunakan tema gelap.
  /// [fontFamily] nama font dari Google Fonts.
  /// [fontSizeScale] faktor pengali ukuran font (e.g. 1.0, 1.2).
  static ThemeData getTheme({
    required bool isDark,
    required String fontFamily,
    required double fontSizeScale,
  }) {
    // 1. Tentukan Font Family yang efektif (fallback ke Poppins jika gagal)
    String? effectiveFontFamily;
    try {
      effectiveFontFamily = GoogleFonts.getFont(fontFamily).fontFamily;
    } catch (_) {
      effectiveFontFamily = GoogleFonts.poppins().fontFamily;
    }

    // 2. Dapatkan basis data tema (Light/Dark)
    final baseData = isDark ? _getDarkData(effectiveFontFamily) : _getData(effectiveFontFamily);

    // 3. Konfigurasi TextTheme dengan Google Fonts
    TextTheme textTheme = GoogleFonts.getTextTheme(
      fontFamily,
      baseData.textTheme,
    );

    // 4. Perbaikan Assertion Error: Gunakan helper untuk scaling font yang aman
    // Kita menghindari .apply(fontSizeFactor) karena akan crash jika ada TextStyle dengan fontSize null
    textTheme = _scaleTextTheme(textTheme, fontSizeScale);

    // 5. Sesuaikan warna teks berdasarkan kecerahan tema
    final color = isDark ? Colors.white : AppColor.text;
    textTheme = textTheme.apply(
      bodyColor: color,
      displayColor: color,
    );

    return baseData.copyWith(
      textTheme: textTheme,
      primaryColor: AppColor.primary,
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: AppColor.primary,
        brightness: isDark ? Brightness.dark : Brightness.light,
      ).copyWith(
        surface: isDark ? AppColor.darkSurface : AppColor.background,
        onSurface: isDark ? AppColor.darkText : AppColor.text,
      ),
    );
  }

  /// Helper untuk melakukan scaling (perbesaran/pengecilan) ukuran font secara aman.
  /// Menghindari crash 'fontSize != null' pada aplikasi Flutter.
  static TextTheme _scaleTextTheme(TextTheme base, double factor) {
    if (factor == 1.0) return base;
    
    return base.copyWith(
      displayLarge: _safeScale(base.displayLarge, factor),
      displayMedium: _safeScale(base.displayMedium, factor),
      displaySmall: _safeScale(base.displaySmall, factor),
      headlineLarge: _safeScale(base.headlineLarge, factor),
      headlineMedium: _safeScale(base.headlineMedium, factor),
      headlineSmall: _safeScale(base.headlineSmall, factor),
      titleLarge: _safeScale(base.titleLarge, factor),
      titleMedium: _safeScale(base.titleMedium, factor),
      titleSmall: _safeScale(base.titleSmall, factor),
      bodyLarge: _safeScale(base.bodyLarge, factor),
      bodyMedium: _safeScale(base.bodyMedium, factor),
      bodySmall: _safeScale(base.bodySmall, factor),
      labelLarge: _safeScale(base.labelLarge, factor),
      labelMedium: _safeScale(base.labelMedium, factor),
      labelSmall: _safeScale(base.labelSmall, factor),
    );
  }

  static TextStyle? _safeScale(TextStyle? style, double factor) {
    if (style == null || style.fontSize == null) return style;
    return style.copyWith(fontSize: style.fontSize! * factor);
  }

  /// Konfigurasi basis untuk Tema Terang (Light Mode).
  static ThemeData _getData(String? fontFamily) => ThemeData(
    useMaterial3: true,
    fontFamily: fontFamily,
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
    dialogTheme: DialogThemeData(
      backgroundColor: AppColor.background,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColor.outlined, width: 0.5),
      ),
      color: Colors.white,
    ),
  );

  /// Konfigurasi basis untuk Tema Gelap (Dark Mode).
  static ThemeData _getDarkData(String? fontFamily) => ThemeData(
    useMaterial3: true,
    fontFamily: fontFamily,
    primarySwatch: AppColor.primary,
    scaffoldBackgroundColor: AppColor.darkBackground,
    brightness: Brightness.dark,
    appBarTheme: AppAppBarTheme.darkData,
    elevatedButtonTheme: AppElevatedButtonTheme.darkData,
    outlinedButtonTheme: AppOutlinedButtonTheme.darkData,
    progressIndicatorTheme: AppProgressIndicatorTheme.darkData,
    textSelectionTheme: AppTextSelectionTheme.darkData,
    inputDecorationTheme: AppInputDecorationTheme.darkData,
    splashFactory: InkRipple.splashFactory,
    dialogTheme: DialogThemeData(
      backgroundColor: AppColor.darkSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    cardColor: AppColor.darkSurface,
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: AppColor.darkSurface,
    ),
    dividerColor: Colors.white12,
  );
}
