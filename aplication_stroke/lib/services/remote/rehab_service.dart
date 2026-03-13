import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/rehab_models.dart';

class RehabService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ─── One-shot Fetches ──────────────────────────────────────────────────────

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

  // ─── Realtime Streams ──────────────────────────────────────────────────────

  /// Stream progress rehab pengguna — otomatis update saat data berubah di DB.
  /// Gunakan dengan StreamBuilder di widget untuk tampilan yang selalu segar.
  ///
  /// Contoh di widget:
  /// ```dart
  /// StreamBuilder<List<Map<String, dynamic>>>(
  ///   stream: RehabService().streamUserProgress(userId),
  ///   builder: (context, snapshot) {
  ///     if (!snapshot.hasData) return CircularProgressIndicator();
  ///     final data = snapshot.data!.firstOrNull;
  ///     return Text('Fase: ${data?['current_phase_id']}');
  ///   },
  /// );
  /// ```
  Stream<List<Map<String, dynamic>>> streamUserProgress(String userId) {
    return _supabase
        .from('rehab_user_progress')
        .stream(primaryKey: ['user_id'])  // primaryKey wajib diisi
        .eq('user_id', userId);           // filter hanya data user ini
  }

  /// Stream log latihan pengguna — otomatis tampil saat latihan baru dicatat.
  Stream<List<Map<String, dynamic>>> streamExerciseLogs(String userId) {
    return _supabase
        .from('rehab_exercise_logs')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId);
  }

  // ─── Writes ────────────────────────────────────────────────────────────────

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

    // Update last activity
    await logActivity(userId);
  }

  // ─── Quiz & Phase Transition ─────────────────────────────────────────────

  /// Mengambil daftar pertanyaan quiz untuk transisi dari fase tertentu.
  Future<List<RehabQuizQuestion>> getQuizQuestions(int phaseFrom) async {
    final response = await _supabase
        .from('rehab_quiz_questions')
        .select()
        .eq('from_phase_id', phaseFrom)
        .order('order_index');
    
    return (response as List)
        .map((e) => RehabQuizQuestion.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Mencatat percobaan kuis.
  Future<void> submitQuizAttempt({
    required String userId,
    required int phaseFrom,
    required int score,
    required bool passed,
  }) async {
    await _supabase.from('rehab_quiz_attempts').insert({
      'user_id': userId,
      'from_phase_id': phaseFrom,
      'score': score,
      'passed': passed,
      'responses': {}, // JSONB responses
    });

    if (passed) {
      await updatePhase(userId, phaseFrom + 1);
    }

    // Update last quiz date
    await _supabase.from('rehab_user_progress').update({
      'last_quiz_at': DateTime.now().toIso8601String(),
    }).eq('user_id', userId);
  }

  /// Memperbaharui fase pengguna.
  Future<void> updatePhase(String userId, int newPhaseId) async {
    await _supabase.from('rehab_user_progress').update({
      'current_phase_id': newPhaseId,
      'phase_started_at': DateTime.now().toIso8601String(),
    }).eq('user_id', userId);
  }
}

