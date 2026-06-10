import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/user_profile_helper.dart';
import '../local/notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// Sinkronisasi FCM token + handler pesan push.
class PushNotificationService {
  PushNotificationService._();
  static final instance = PushNotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _client = Supabase.instance.client;
  bool _initialized = false;

  static bool get isSupported {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  Future<void> init() async {
    if (!isSupported || _initialized) return;
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await _messaging.getToken();
      if (token != null) await _saveToken(token);

      _messaging.onTokenRefresh.listen(_saveToken);

      FirebaseMessaging.onMessage.listen((message) {
        final title = message.notification?.title ?? 'Smart Stroke';
        final body = message.notification?.body ?? '';
        if (body.isNotEmpty) {
          NotificationService().showInstantNotification(title, body);
        }
      });

      _initialized = true;
    } catch (e) {
      debugPrint('PushNotificationService init error: $e');
    }
  }

  Future<void> syncTokenIfLoggedIn() async {
    if (!isSupported || !_initialized) return;
    try {
      final token = await _messaging.getToken();
      if (token != null) await _saveToken(token);
    } catch (_) {}
  }

  Future<void> _saveToken(String token) async {
    if (_client.auth.currentUser == null) return;
    try {
      final pharmId = await UserProfileHelper.pharmacistProfileId();
      if (pharmId != null) {
        await _client.from('pharmacists').update({'fcm_token': token}).eq('id', pharmId);
        return;
      }
      final doctorId = await UserProfileHelper.doctorProfileId();
      if (doctorId != null) {
        await _client.from('doctors').update({'fcm_token': token}).eq('id', doctorId);
        return;
      }
      final patientId = await UserProfileHelper.patientProfileId();
      if (patientId != null) {
        await _client.from('users').update({'fcm_token': token}).eq('id', patientId);
      }
    } catch (e) {
      debugPrint('FCM token save error: $e');
    }
  }
}
