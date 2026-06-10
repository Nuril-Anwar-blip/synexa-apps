import 'package:flutter_background_service/flutter_background_service.dart';

import 'main.dart';
import 'services/remote/background_service.dart';

/// Class `Global` berfungsi sebagai pusat inisialisasi (service locator)
/// untuk berbagai layanan yang digunakan di aplikasi.
///
/// Dengan adanya `Global`, semua service penting seperti:
/// - Supabase (backend utama)
/// - Local Storage / Secure Storage
/// - Database lokal (contoh: chatDb, chatListDb)
/// - atau service lain (misal: API client, analytics, dll)
///
/// dapat diinisialisasi hanya sekali, lalu diakses secara global
/// lewat property static.
///
/// Pemanggilan dilakukan sekali saja saat aplikasi dijalankan pertama kali,
/// di dalam `main()`:
class Global {
  static Future init() async {
   
  //   // 🔔 Inisialisasi notifikasi sebelum service jalan
  //   await BackgroundService.initializeNotifications();

  //   await FlutterBackgroundService().configure(
  //     androidConfiguration: AndroidConfiguration(
  //       onStart: backgroundServiceEntryPoint, // ini callback kamu
  //       isForegroundMode: true,
  //       autoStart: false, // nanti kita nyalakan manual setelah login
  //     ),
  //     iosConfiguration: IosConfiguration(),
  //   );
  }
}
