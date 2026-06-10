import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../supabase/supabase_client.dart';
import '../local/auth_local_service.dart';

class BackgroundService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(initSettings);
  }

  static Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'fall_channel',
          'Fall Detection',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          fullScreenIntent: true,
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      0, // ID notifikasi
      title,
      body,
      platformDetails,
    );
  }

  @pragma('vm:entry-point')
  static Future<void> onStart(ServiceInstance service) async {
    // pastikan binding ready
    WidgetsFlutterBinding.ensureInitialized();

    // ✅ Load ulang .env di background isolate
    await dotenv.load(fileName: ".env");

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_PUBLISHABLE_KEY']!,
    );
    double lastAcc = 0;
    accelerometerEventStream().listen((event) {
      double acc = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      // Cek threshold + minimal delay
      if (acc > 25 && acc != lastAcc) {
        lastAcc = acc;

        // Jalankan async di "fire-and-forget" supaya listener tidak nge-block
        _handleFallDetection(acc);
      }
    });
  }

  static Future<void> _handleFallDetection(double acc) async {
    final session = await AuthLocalService.getSession();
    if (session == null) {
      debugPrint("User menolak izin lokasi");
      return;
    }
    try {
      Position pos = await Geolocator.getCurrentPosition();
      await SupabaseManager.client.from("events").insert({
        "user_id": session["userId"],
        "event": "fall_detected",
        "latitude": pos.latitude,
        "longitude": pos.longitude,
      });

      await showNotification(
        "⚠️ Deteksi Jatuh",
        "Lokasi: ${pos.latitude}, ${pos.longitude}",
      );
      debugPrint("⚠️ Fall detected & sent to Supabase with location");
    } catch (e) {
      debugPrint("Error saat upload data: $e");
    }
  }
}
