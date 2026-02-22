import 'package:flutter/material.dart';
import '../../colors/app_color.dart';

/**
 * Tujuannya adalah menyediakan palet warna yang konsisten
 * di seluruh aplikasi, sehingga memudahkan pengelolaan tema 
 * dan penyesuaian tampilan aplikasi
 */

/// Tema global untuk ElevatedButton.
/// Mengatur padding, bentuk sudut (rounded), dan warna.
class AppElevatedButtonTheme {
  const AppElevatedButtonTheme._();

  static ElevatedButtonThemeData get data => ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      splashFactory: InkRipple.splashFactory,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      foregroundColor: AppColor.onPrimary,
      elevation: 0,
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      backgroundColor: AppColor.primary,
    ),
  );

  /// Tema Elevated Button untuk Dark Mode.
  static ElevatedButtonThemeData get darkData => ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      splashFactory: InkRipple.splashFactory,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      foregroundColor: Colors.white,
      elevation: 0,
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      backgroundColor: AppColor.primary,
    ),
  );
}
