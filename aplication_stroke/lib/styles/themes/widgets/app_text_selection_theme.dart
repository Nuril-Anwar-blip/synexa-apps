import 'package:flutter/material.dart';
import '../../colors/app_color.dart';

/**
 * Tujuannya adalah menyediakan palet warna yang konsisten
 * di seluruh aplikasi, sehingga memudahkan pengelolaan tema 
 * dan penyesuaian tampilan aplikasi
 *
 */

/// Tema untuk seleksi teks (kursor dan highlight).
class AppTextSelectionTheme {
  const AppTextSelectionTheme._();

  static TextSelectionThemeData get data => TextSelectionThemeData(
    cursorColor: AppColor.text,
    selectionColor: AppColor.primary.withValues(alpha: 0.8),
    selectionHandleColor: AppColor.primary,
  );
}

