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

  /// Mengambil daftar latihan untuk fase dan kategori waktu tertentu.
  Future<List<RehabExercise>> getExercises(int phaseId, String timeCategory) async {
    final response = await _supabase
        .from('rehab_exercises')
        .select()
        .eq('phase_id', phaseId)
        .eq('time_category', timeCategory);
    
    return (response as List)
        .map((e) => RehabExercise.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Mencatat log penyelesaian latihan.
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
    });
  }

  /// Mengambil pertanyaan quiz untuk transisi dari phaseId tertentu.
  Future<List<RehabQuizQuestion>> getQuizQuestions(int phaseId) async {
    final response = await _supabase
        .from('rehab_quiz_questions')
        .select()
        .eq('from_phase_id', phaseId)
        .order('order_index');
    
    return (response as List)
        .map((q) => RehabQuizQuestion.fromMap(q as Map<String, dynamic>))
        .toList();
  }

  /// Mengirim hasil quiz dan mengupdate progress jika lulus.
  Future<void> submitQuizResult({
    required String userId,
    required int fromPhaseId,
    required int score,
    required bool passed,
    required Map<String, dynamic> responses,
  }) async {
    await _supabase.from('rehab_quiz_attempts').insert({
      'user_id': userId,
      'from_phase_id': fromPhaseId,
      'score': score,
      'passed': passed,
      'responses': responses,
    });

    if (passed) {
      // Update ke fase berikutnya
      await _supabase.from('rehab_user_progress').update({
        'current_phase_id': fromPhaseId + 1,
        'phase_started_at': DateTime.now().toIso8601String(),
        'last_quiz_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId);
    }
  }
}
