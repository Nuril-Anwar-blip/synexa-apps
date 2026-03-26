import 'dart:async';
import '../remote/backend_api_service.dart';
import '../remote/socket_service.dart';
import '../../models/health_log_model.dart';

class HealthService {
  final BackendApiService _apiService = BackendApiService.instance;
  final SocketService _socketService = SocketService.instance;

  // ─── One-shot Fetches ──────────────────────────────────────────────────────

  /// Mencatat log kesehatan baru (Tensi, Gula Darah, atau Berat Badan).
  Future<void> saveHealthLog(HealthLog log) async {
    await _apiService.addHealthLog(
      logType: log.logType,
      systolic: log.valueSystolic,
      diastolic: log.valueDiastolic,
      value: log.valueNumeric,
      note: log.note,
    );
  }

  /// Mengambil riwayat log kesehatan pengguna berdasarkan tipe.
  Future<List<HealthLog>> getHealthLogs(String userId, String logType) async {
    final data = await _apiService.getHealthLogs(userId, type: logType);
    return data.map((l) => HealthLog.fromMap(l)).toList();
  }

  // ─── Realtime Streams ──────────────────────────────────────────────────────

  /// Stream log kesehatan — otomatis update saat ada catatan baru ditambahkan.
  ///
  /// Contoh pemakaian di widget:
  /// ```dart
  /// StreamBuilder<List<Map<String, dynamic>>>(
  ///   stream: HealthService().streamHealthLogs(userId, 'blood_pressure'),
  ///   builder: (context, snapshot) {
  ///     if (!snapshot.hasData) return CircularProgressIndicator();
  ///     final logs = snapshot.data!;
  ///     return ListView.builder(
  ///       itemCount: logs.length,
  ///       itemBuilder: (ctx, i) => Text(logs[i]['value_systolic'].toString()),
  ///     );
  ///   },
  /// );
  /// ```
  Stream<List<Map<String, dynamic>>> streamHealthLogs(
    String userId,
    String logType,
  ) {
    // Create a stream controller
    late StreamController<List<Map<String, dynamic>>> controller;
    List<Map<String, dynamic>> currentData = [];

    controller = StreamController<List<Map<String, dynamic>>>(
      onListen: () async {
        // Initial load
        try {
          final data = await _apiService.getHealthLogs(userId, type: logType);
          currentData = data;
          controller.add(currentData);
        } catch (e) {
          controller.addError(e);
        }

        // Listen for real-time updates
        _socketService.onHealthUpdated((updateData) {
          final action = updateData['action'];
          final healthData = updateData['data'];

          if (action == 'created') {
            // Add new health log to the list
            currentData.insert(0, healthData);
            controller.add(currentData);
          }
        });
      },
      onCancel: () {
        _socketService.offHealthUpdated();
      },
    );

    return controller.stream;
  }

  // ─── Medication Master ────────────────────────────────────────────────────

  /// Mengambil data master obat untuk dropdown/autocomplete di UI.
  Future<List<Map<String, dynamic>>> getMedicationMaster() async {
    // Note: Backend doesn't have medication master endpoint yet
    // Return empty list for now
    return [];
  }
}
