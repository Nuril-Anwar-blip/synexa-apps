import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/health_log_model.dart';

class HealthService {
  final SupabaseClient _supabase = Supabase.instance.client;

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

  /// Mengambil data master obat untuk dropdown/autocomplete di UI.
  Future<List<Map<String, dynamic>>> getMedicationMaster() async {
    final response = await _supabase
        .from('medication_master')
        .select()
        .order('name');
    return List<Map<String, dynamic>>.from(response);
  }
}
