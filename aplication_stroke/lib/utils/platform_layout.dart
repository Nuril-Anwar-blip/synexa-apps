import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PlatformLayout {
  const PlatformLayout._();

  static bool get isDesktop {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  static bool isWideEnough(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 900;

  static bool canRunAdminDashboard(BuildContext context) =>
      isDesktop && isWideEnough(context);
}
