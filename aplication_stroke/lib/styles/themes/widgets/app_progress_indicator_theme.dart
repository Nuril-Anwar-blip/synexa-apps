import 'package:flutter/material.dart';
import '../../colors/app_color.dart';

/**
 * Tujuannya adalah menyediakan palet warna yang konsisten
 * di seluruh aplikasi, sehingga memudahkan pengelolaan tema 
 * dan penyesuaian tampilan aplikasi
 *
 */

/// Tema global untuk CircularProgressIndicator dan LinearProgressIndicator.
class AppProgressIndicatorTheme {
  const AppProgressIndicatorTheme._();

  static ProgressIndicatorThemeData get data => ProgressIndicatorThemeData(
    color: AppColor.primary,
    linearTrackColor: AppColor.primary,
    strokeWidth: 1,
    trackGap: 2,
    refreshBackgroundColor: AppColor.background,
    circularTrackPadding: const EdgeInsets.all(10),
    circularTrackColor: Colors.transparent,
  );
}

