import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/health_log_model.dart';

class HealthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ─── One-shot Fetches ──────────────────────────────────────────────────────

  /// Mencatat log kesehatan baru (Tensi, Gula Darah, atau Berat Badan).
  Future<void> saveHealthLog(HealthLog log) async {
    await _supabase.from('health_logs').insert(log.toMap());
  }

  /// Mengambil riwayat log kesehatan pengguna berdasarkan tipe.
  Future<List<HealthLog>> getHealthLogs(String userId, String logType) async {
    final response = await _supabase
        .from('health_logs')
        .select()
        .eq('user_id', userId)
        .eq('log_type', logType)
        .order('recorded_at', ascending: false);
    
    return (response as List)
        .map((l) => HealthLog.fromMap(l as Map<String, dynamic>))
        .toList();
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
    return _supabase
        .from('health_logs')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('recorded_at', ascending: false);
    // Catatan: filter .eq('log_type') tidak tersedia di stream(),
    // filter di sisi Dart setelah data diterima jika diperlukan.
  }

  // ─── Medication Master ────────────────────────────────────────────────────

  /// Mengambil data master obat untuk dropdown/autocomplete di UI.
  Future<List<Map<String, dynamic>>> getMedicationMaster() async {
    final response = await _supabase
        .from('medication_master')
        .select()
        .order('name');
    return List<Map<String, dynamic>>.from(response);
  }
}

