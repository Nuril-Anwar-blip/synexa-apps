import 'package:flutter/material.dart';
import '../../colors/app_color.dart';

/**
 * Tujuannya adalah menyediakan palet warna yang konsisten
 * di seluruh aplikasi, sehingga memudahkan pengelolaan tema 
 * dan penyesuaian tampilan aplikasi
 * 
 */

/// Tema global untuk OutlinedButton.
/// Mengatur border side, padding, dan bentuk tombol.
class AppOutlinedButtonTheme {
  const AppOutlinedButtonTheme._();

  static OutlinedButtonThemeData get data => OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      splashFactory: InkRipple.splashFactory,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      backgroundColor: AppColor.background, // warna background
      foregroundColor: AppColor.text, // warna teks & icon
      side: BorderSide(color: AppColor.outlined), // warna outline
    ),
  );

  /// Tema Outlined Button untuk Dark Mode.
  static OutlinedButtonThemeData get darkData => OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      splashFactory: InkRipple.splashFactory,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      side: const BorderSide(color: Colors.white24),
    ),
  );
}

