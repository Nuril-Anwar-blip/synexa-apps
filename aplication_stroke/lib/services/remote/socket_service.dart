import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// SocketService — Layanan Singleton untuk koneksi Socket.io real-time.
///
/// Cara pakai:
///   1. Panggil `SocketService.instance.connect(userId)` setelah user login.
///   2. Pasang listener di Widget dengan `SocketService.instance.onMedicationUpdated(callback)`.
///   3. Panggil `SocketService.instance.disconnect()` saat user logout.
class SocketService {
  // ── Singleton ──────────────────────────────────────────────────────────────
  static final SocketService instance = SocketService._internal();
  SocketService._internal();

  IO.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  // ── URL backend dari .env ─────────────────────────────────────────────────
  String get _backendUrl =>
      dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:3000';

  // ── Connect ───────────────────────────────────────────────────────────────
  /// Hubungkan ke backend dan daftarkan userId ke room-nya.
  void connect(String userId) {
    if (isConnected) return;

    _socket = IO.io(
      _backendUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      // Daftarkan userId agar backend tahu harus emit ke room mana
      _socket!.emit('register_user', userId);
    });

    _socket!.onDisconnect((_) {
      // Reconnect otomatis sudah ditangani oleh library
    });

    _socket!.onConnectError((err) {
      // Bisa ditambahkan logging / error handling di sini
    });
  }

  // ── Disconnect ────────────────────────────────────────────────────────────
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  // ── Chat Room ─────────────────────────────────────────────────────────────
  void joinChatRoom(String roomId) => _socket?.emit('join_room', roomId);

  void sendChatMessage({
    required String roomId,
    required String senderId,
    required String content,
    required String senderName,
  }) {
    _socket?.emit('send_message', {
      'roomId': roomId,
      'senderId': senderId,
      'content': content,
      'senderName': senderName,
    });
  }

  /// Pasang listener untuk pesan chat yang masuk.
  void onReceiveMessage(Function(Map<String, dynamic>) callback) {
    _socket?.on('receive_message', (data) {
      if (data is Map<String, dynamic>) callback(data);
    });
  }

  // ── Medication Real-time ──────────────────────────────────────────────────
  /// Dipanggil saat pengingat obat ditambahkan atau di-take.
  void onMedicationUpdated(Function(Map<String, dynamic>) callback) {
    _socket?.on('medication_updated', (data) {
      if (data is Map<String, dynamic>) callback(data);
    });
  }

  void offMedicationUpdated() => _socket?.off('medication_updated');

  // ── Health Log Real-time ──────────────────────────────────────────────────
  /// Dipanggil saat log kesehatan baru ditambahkan.
  void onHealthUpdated(Function(Map<String, dynamic>) callback) {
    _socket?.on('health_updated', (data) {
      if (data is Map<String, dynamic>) callback(data);
    });
  }

  void offHealthUpdated() => _socket?.off('health_updated');

  // ── Community Real-time ───────────────────────────────────────────────────
  /// Dipanggil saat ada postingan, komentar, atau like baru.
  void onCommunityUpdated(Function(Map<String, dynamic>) callback) {
    _socket?.on('community_updated', (data) {
      if (data is Map<String, dynamic>) callback(data);
    });
  }

  void offCommunityUpdated() => _socket?.off('community_updated');

  // ── Emergency Alert Real-time ─────────────────────────────────────────────
  /// Dipanggil saat sinyal SOS dikirmkan atau statusnya berubah.
  void onEmergencyAlert(Function(Map<String, dynamic>) callback) {
    _socket?.on('emergency_alert', (data) {
      if (data is Map<String, dynamic>) callback(data);
    });
  }

  void offEmergencyAlert() => _socket?.off('emergency_alert');
}
