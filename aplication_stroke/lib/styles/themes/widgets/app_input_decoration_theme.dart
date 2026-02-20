import 'package:flutter/material.dart';
import '../../colors/app_color.dart';

/**
 * Tujuannya adalah menyediakan palet warna yang konsisten
 * di seluruh aplikasi, sehingga memudahkan pengelolaan tema 
 * dan penyesuaian tampilan aplikasi
 *
 */

/// Tema global untuk InputDecoration (TextField).
/// Mengatur border, padding, dan warna error.
class AppInputDecorationTheme {
  const AppInputDecorationTheme._();

  /// Tema Input untuk Light Mode.
  static InputDecorationTheme get data => InputDecorationTheme(
    errorMaxLines: 3,
    contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
    hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
    helperStyle: TextStyle(fontSize: 14),
    errorStyle: TextStyle(fontSize: 12, color: AppColor.error),
    fillColor: Colors.transparent,
    labelStyle: TextStyle(fontSize: 16),
    filled: true,
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(width: 0.8, color: AppColor.error),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(width: 0.8, color: AppColor.error),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(width: 0.8, color: AppColor.outlined),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(width: 1, color: AppColor.text),
    ),
  );

  /// Tema Input untuk Dark Mode.
  static InputDecorationTheme get darkData => InputDecorationTheme(
    errorMaxLines: 3,
    contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
    hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
    helperStyle: TextStyle(fontSize: 14, color: Colors.grey[300]),
    errorStyle: TextStyle(fontSize: 12, color: AppColor.error),
    fillColor: Colors.grey[800],
    labelStyle: TextStyle(fontSize: 16, color: Colors.grey[300]),
    filled: true,
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(width: 0.8, color: AppColor.error),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(width: 0.8, color: AppColor.error),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(width: 0.8, color: Colors.grey[600]!),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(width: 1, color: AppColor.primary),
    ),
  );
}

