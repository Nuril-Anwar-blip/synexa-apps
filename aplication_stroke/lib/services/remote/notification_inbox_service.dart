import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/user_profile_helper.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.data,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    final rawData = map['data'];
    return AppNotification(
      id: map['id'].toString(),
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      type: map['type']?.toString() ?? 'system',
      isRead: map['is_read'] == true,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      data: rawData is Map ? Map<String, dynamic>.from(rawData) : null,
    );
  }
}

class NotificationInboxService {
  NotificationInboxService._();
  static final instance = NotificationInboxService._();

  final _client = Supabase.instance.client;

  Future<List<AppNotification>> loadInbox() async {
    final patientId = await UserProfileHelper.patientProfileId();
    if (patientId == null) return [];
    final rows = await _client
        .from('notifications')
        .select()
        .eq('user_id', patientId)
        .order('created_at', ascending: false)
        .limit(50);
    return (rows as List)
        .map((r) => AppNotification.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  Future<int> unreadCount() async {
    final patientId = await UserProfileHelper.patientProfileId();
    if (patientId == null) return 0;
    final rows = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', patientId)
        .eq('is_read', false);
    return (rows as List).length;
  }

  Future<void> markRead(String id) async {
    await _client.from('notifications').update({
      'is_read': true,
      'read_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> markAllRead() async {
    final patientId = await UserProfileHelper.patientProfileId();
    if (patientId == null) return;
    await _client
        .from('notifications')
        .update({
          'is_read': true,
          'read_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('user_id', patientId)
        .eq('is_read', false);
  }
}
