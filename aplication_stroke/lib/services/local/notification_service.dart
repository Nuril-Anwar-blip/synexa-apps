/// ====================================================================
/// File: notification_service.dart
/// --------------------------------------------------------------------
/// Layanan Notifikasi Lokal (Local Notification Service)
///
/// Dokumen ini berisi layanan untuk mengirim notifikasi lokal ke perangkat.
/// Menggunakan Flutter Local Notifications.
///
/// Fitur:
/// - Notifikasi pengingat obat (terjadwal)
/// - Notifikasi untuk appointment
/// - Notifikasi untuk exercise/rehab
/// - Mendukung Android notification channels
/// - Menggunakan timezone untuk penjadwalan
///
/// Cara Penggunaan:
///   final notif = NotificationService();
///   await notif.init();
///   await notif.showMedicationReminder(...);
///
/// Author: Tim Developer Synexa
/// ====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifPlugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _medChannel =
      AndroidNotificationChannel(
        'medication_channel',
        'Pengingat Obat',
        description: 'Notifikasi untuk pengingat minum obat',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        sound: RawResourceAndroidNotificationSound('alarm_sound'),
      );

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    // v18+: pakai named parameter 'settings'
    await _notifPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    tz.initializeTimeZones();

    final androidImpl = _notifPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImpl != null) {
      await androidImpl.createNotificationChannel(_medChannel);
      try {
        await androidImpl.requestNotificationsPermission();
      } catch (_) {}
      try {
        await androidImpl.requestExactAlarmsPermission();
      } catch (_) {}
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<void> scheduleMedicationNotification(
    String reminderId,
    String name,
    TimeOfDay time, {
    int timeIndex = 0,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    // baseId unik per pengingat + per jam minum (timeIndex)
    final int baseId = (reminderId.hashCode.abs() + timeIndex) % 100000;

    for (int i = 0; i < 4; i++) {
      final snoozeMinutes = i * 5;

      var scheduledTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute + snoozeMinutes,
      );

      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      final androidDetails = AndroidNotificationDetails(
        _medChannel.id,
        _medChannel.name,
        channelDescription: _medChannel.description,
        importance: _medChannel.importance,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        sound: const RawResourceAndroidNotificationSound('alarm_sound'),
        ticker: 'MedicationReminder',
      );

      final details = NotificationDetails(android: androidDetails);

      await _notifPlugin.zonedSchedule(
        id: baseId + i,
        title: i == 0
            ? 'Waktunya minum obat!'
            : 'Pengingat: Belum minum obat ($snoozeMinutes mnt)',
        body: 'Minum obat: $name sekarang!',
        scheduledDate: scheduledTime,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  /// Menjadwalkan semua waktu minum obat sekaligus
  Future<void> scheduleAllReminders(dynamic reminder) async {
    // Parameter dynamic untuk menghindari circular dependency jika perlu, 
    // tapi kita berasumsi ini model MedicationReminder yang memiliki .times dan .isActive
    if (!reminder.isActive) return;

    await cancelMedicationNotifications(reminder.id);

    for (int i = 0; i < reminder.times.length; i++) {
      await scheduleMedicationNotification(
        reminder.id,
        reminder.name,
        reminder.times[i],
        timeIndex: i * 10, // Beri jarak ID antar jam minum
      );
    }
  }

  Future<void> cancelMedicationNotifications(String reminderId) async {
    // Kita hapus semua slot ID yang mungkin (asumsi maks 10 waktu minum)
    for (int t = 0; t < 10; t++) {
      final int baseId = (reminderId.hashCode.abs() + (t * 10)) % 100000;
      for (int i = 0; i < 4; i++) {
        await _notifPlugin.cancel(id: baseId + i);
      }
    }
  }

  Future<void> testAlarmNow() async {
    final androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Tes Alarm',
      channelDescription: 'Coba suara alarm sekarang',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      sound: const RawResourceAndroidNotificationSound('alarm_sound'),
    );
    final details = NotificationDetails(android: androidDetails);

    // v18+: named parameters
    await _notifPlugin.show(
      id: 999,
      title: 'Tes Alarm',
      body: 'Alarm berbunyi sekarang',
      notificationDetails: details,
    );
  }
}
