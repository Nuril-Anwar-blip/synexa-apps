import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/**
 * Class `Global` berfungsi sebagai pusat inisialisasi (service locator)
 * untuk berbagai layanan yang digunakan di aplikasi
 * 
 * Dengan adanya `Global`, semua service penting, seperti:
 *  - Supabase (backend utama)
 *  - Local Storage / Secure Storage
 *  - Database lokal atau service lain dapat diinisialisasi hanya sekali, lalu diakses secara global
 * lewat property static
 * 
 * Pemanggilan dilakukan sekali saja saat aplikasi dijalankan pertama kali
 * di dalam `main()`:
 */

class Global {
  static Future init() async {
    await dotenv.load(fileName: ".env");
    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? dotenv.env['SUPABASE_PUBLISHABLE_KEY'];
    
    if (url == null || anonKey == null) {
      throw Exception('SUPABASE_URL or SUPABASE_ANON_KEY/PUBLISHABLE_KEY not found in .env');
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }
}

