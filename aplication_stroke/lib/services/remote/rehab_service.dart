import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/rehab_models.dart';

class RehabService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String?> _phaseIdByNumber(int phaseNumber) async {
    final response = await _supabase
        .from('rehab_phases')
        .select('id')
        .eq('phase_number', phaseNumber)
        .maybeSingle();
    return response?['id']?.toString();
  }

  /// Mengambil data progress fase pengguna saat ini.
  Future<RehabProgress?> getUserProgress(String userId) async {
    final response = await _supabase
        .from('rehab_user_progress')
        .select('*, rehab_phases(phase_number)')
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return RehabProgress.fromMap(response);
  }

  /// Mengambil detail fase berdasarkan nomor fase (1, 2, 3).
  Future<RehabPhase> getPhaseDetail(int phaseNumber) async {
    final response = await _supabase
        .from('rehab_phases')
        .select()
        .eq('phase_number', phaseNumber)
        .single();
    return RehabPhase.fromMap(response);
  }

  /// Mengambil daftar latihan untuk fase tertentu.
  Future<List<RehabExercise>> getExercises(int phaseNumber) async {
    final phaseId = await _phaseIdByNumber(phaseNumber);
    if (phaseId == null) return [];

    final response = await _supabase
        .from('rehab_exercises')
        .select()
        .eq('phase_id', phaseId)
        .eq('is_active', true)
        .order('order_index');

    return (response as List)
        .map(
          (e) => RehabExercise.fromMap({
            ...Map<String, dynamic>.from(e as Map),
            'phase_number': phaseNumber,
          }),
        )
        .toList();
  }

  /// Memulai program rehabilitasi fase 1 untuk pengguna.
  Future<void> startInitialProgram(String userId) async {
    final phaseId = await _phaseIdByNumber(1);
    if (phaseId == null) {
      throw Exception('Data fase rehabilitasi belum tersedia di database.');
    }

    await _supabase.from('rehab_user_progress').upsert({
      'user_id': userId,
      'current_phase_id': phaseId,
      'started_at': DateTime.now().toIso8601String(),
      'total_score': 0,
      'total_sessions': 0,
      'total_minutes': 0,
      'streak_days': 0,
    }, onConflict: 'user_id');
  }

  /// Mencatat penyelesaian sesi latihan ke log latihan.
  Future<void> logExerciseCompletion({
    required String userId,
    required String exerciseId,
    required int durationActualSeconds,
    bool isCompleted = true,
    String? notes,
  }) async {
    await _supabase.from('rehab_exercise_logs').insert({
      'user_id': userId,
      'exercise_id': exerciseId,
      'session_date': DateTime.now().toIso8601String().split('T').first,
      'duration_seconds': durationActualSeconds,
      'is_completed': isCompleted,
      'notes': notes,
    });

    await _supabase.from('rehab_user_progress').update({
      'last_session_date': DateTime.now().toIso8601String().split('T').first,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('user_id', userId);
  }
}
