import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/health_log_model.dart';

class HealthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> saveHealthLog(HealthLog log) async {
    await _supabase.from('health_logs').insert(log.toMap());
  }

  Future<List<HealthLog>> getBloodPressureLogs(String userId) async {
    final response = await _supabase
        .from('health_logs')
        .select()
        .eq('user_id', userId)
        .not('systolic_bp', 'is', null)
        .order('log_date', ascending: false)
        .limit(30);
    return (response as List)
        .map((l) => HealthLog.fromMap(l as Map<String, dynamic>))
        .toList();
  }

  Future<List<HealthLog>> getBloodSugarLogs(String userId) async {
    final response = await _supabase
        .from('health_logs')
        .select()
        .eq('user_id', userId)
        .not('blood_sugar', 'is', null)
        .order('log_date', ascending: false)
        .limit(30);
    return (response as List)
        .map((l) => HealthLog.fromMap(l as Map<String, dynamic>))
        .toList();
  }

  Future<List<HealthLog>> getWeightLogs(String userId) async {
    final response = await _supabase
        .from('health_logs')
        .select()
        .eq('user_id', userId)
        .not('weight_kg', 'is', null)
        .order('log_date', ascending: false)
        .limit(30);
    return (response as List)
        .map((l) => HealthLog.fromMap(l as Map<String, dynamic>))
        .toList();
  }

  Future<double?> getUserHeightCm(String userId) async {
    final row = await _supabase
        .from('users')
        .select('height_cm')
        .eq('id', userId)
        .maybeSingle();
    return (row?['height_cm'] as num?)?.toDouble();
  }
}
