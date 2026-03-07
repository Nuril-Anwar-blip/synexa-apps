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
    TimeOfDay time,
  ) async {
    final now = tz.TZDateTime.now(tz.local);
    final int baseId = reminderId.hashCode.abs() % 100000;

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

      // v18+: semua named parameters
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

  Future<void> cancelMedicationNotifications(String reminderId) async {
    final int baseId = reminderId.hashCode.abs() % 100000;
    for (int i = 0; i < 4; i++) {
      // v18+: named parameter 'id'
      await _notifPlugin.cancel(id: baseId + i);
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
