import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/user_profile_helper.dart';

/// Heartbeat & langganan realtime status kehadiran tenaga medis.
class StaffPresenceService {
  StaffPresenceService._();
  static final instance = StaffPresenceService._();

  final _client = Supabase.instance.client;
  Timer? _heartbeatTimer;
  RealtimeChannel? _channel;

  static const _onlineThreshold = Duration(minutes: 5);

  /// Apoteker / dokter: kirim heartbeat setiap 60 detik saat app aktif.
  Future<void> startHeartbeat() async {
    await _sendHeartbeat();
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _sendHeartbeat(),
    );
  }

  void stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _setOffline();
  }

  Future<void> _sendHeartbeat() async {
    final pharmId = await UserProfileHelper.pharmacistProfileId();
    if (pharmId != null) {
      await _upsertPresence(staffId: pharmId, staffType: 'pharmacist');
      return;
    }
    final doctorId = await _doctorProfileId();
    if (doctorId != null) {
      await _upsertPresence(staffId: doctorId, staffType: 'doctor');
    }
  }

  Future<void> _setOffline() async {
    final pharmId = await UserProfileHelper.pharmacistProfileId();
    if (pharmId != null) {
      await _client.from('staff_presence').upsert({
        'staff_id': pharmId,
        'staff_type': 'pharmacist',
        'is_online': false,
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'staff_id,staff_type');
    }
  }

  Future<void> _upsertPresence({
    required String staffId,
    required String staffType,
  }) async {
    try {
      await _client.from('staff_presence').upsert({
        'staff_id': staffId,
        'staff_type': staffType,
        'is_online': true,
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'staff_id,staff_type');
    } catch (_) {}
  }

  Future<String?> _doctorProfileId() async {
    final authId = _client.auth.currentUser?.id;
    if (authId == null) return null;
    final row = await _client
        .from('doctors')
        .select('id')
        .eq('auth_id', authId)
        .maybeSingle();
    return row?['id']?.toString();
  }

  static bool isRecentlyOnline({
    required bool isOnlineFlag,
    required DateTime? lastSeen,
  }) {
    if (!isOnlineFlag || lastSeen == null) return false;
    return DateTime.now().toUtc().difference(lastSeen.toUtc()) <=
        _onlineThreshold;
  }

  /// Pasien: dengarkan perubahan presence secara realtime.
  RealtimeChannel subscribePresence(void Function() onChange) {
    _channel?.unsubscribe();
    _channel = _client
        .channel('staff_presence_home')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'staff_presence',
          callback: (_) => onChange(),
        )
        .subscribe();
    return _channel!;
  }

  void disposeChannel() {
    _channel?.unsubscribe();
    if (_channel != null) _client.removeChannel(_channel!);
    _channel = null;
  }
}
