import 'package:flutter/material.dart';
import '../../colors/app_color.dart';

/**
 * Tujuannya adalah menyediakan palet warna yang konsisten
 * di seluruh aplikasi, sehingga memudahkan pengelolaan tema 
 * dan penyesuaian tampilan aplikasi

 */

/// Tema AppBar aplikasi.
/// Menghilangkan elevasi dan mengatur warna background.
class AppAppBarTheme {
  const AppAppBarTheme._();

  /// Tema AppBar untuk Light Mode.
  static AppBarTheme get data => AppBarTheme(
    backgroundColor: AppColor.background,
    scrolledUnderElevation: 0,
    elevation: 0,
  );

  /// Tema AppBar untuk Dark Mode.
  static AppBarTheme get darkData => AppBarTheme(
    backgroundColor: Colors.grey[900],
    foregroundColor: Colors.white,
    scrolledUnderElevation: 0,
    elevation: 0,
  );
}

