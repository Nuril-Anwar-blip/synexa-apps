import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/rehab_models.dart';

class RehabService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Mengambil data progress fase pengguna saat ini.
  Future<RehabProgress?> getUserProgress(String userId) async {
    final response = await _supabase
        .from('rehab_user_progress')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    
    if (response == null) return null;
    return RehabProgress.fromMap(response);
  }

  /// Mengambil detail fase berdasarkan ID.
  Future<RehabPhase> getPhaseDetail(int phaseId) async {
    final response = await _supabase
        .from('rehab_phases')
        .select()
        .eq('id', phaseId)
        .single();
    return RehabPhase.fromMap(response);
  }

  /// Mengambil daftar latihan untuk fase tertentu.
  Future<List<RehabExercise>> getExercises(int phaseId) async {
    final response = await _supabase
        .from('rehab_exercises')
        .select()
        .eq('phase_id', phaseId)
        .order('name');
    
    return (response as List)
        .map((e) => RehabExercise.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Mencatat log aktivitas terakhir.
  Future<void> logActivity(String userId) async {
    await _supabase.from('rehab_user_progress').update({
      'phase_started_at': DateTime.now().toIso8601String(),
    }).eq('user_id', userId);
  }

  /// Mencatat penyelesaian sesi latihan ke log latihan.
  Future<void> logExerciseCompletion({
    required String userId,
    required String exerciseId,
    required int durationActualSeconds,
    bool isAborted = false,
    String? abortReason,
  }) async {
    await _supabase.from('rehab_exercise_logs').insert({
      'user_id': userId,
      'exercise_id': exerciseId,
      'duration_actual_seconds': durationActualSeconds,
      'is_aborted': isAborted,
      'abort_reason': abortReason,
      'completed_at': DateTime.now().toIso8601String(),
    });
  }
}
