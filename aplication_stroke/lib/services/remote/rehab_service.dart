import 'dart:async';
import '../remote/backend_api_service.dart';
import '../remote/socket_service.dart';
import '../../models/rehab_models.dart';

class RehabService {
  final BackendApiService _apiService = BackendApiService.instance;
  final SocketService _socketService = SocketService.instance;

  // ─── One-shot Fetches ──────────────────────────────────────────────────────

  /// Mengambil data progress fase pengguna saat ini.
  Future<RehabProgress?> getUserProgress(String userId) async {
    final data = await _apiService.getRehabProgress(userId);
    if (data == null) return null;
    return RehabProgress.fromMap(data);
  }

  /// Mengambil detail fase berdasarkan ID.
  Future<RehabPhase> getPhaseDetail(int phaseId) async {
    final phases = await _apiService.getRehabPhases();
    final phase = phases.firstWhere(
      (p) => p['id'] == phaseId,
      orElse: () => throw Exception('Phase not found'),
    );
    return RehabPhase.fromMap(phase);
  }

  /// Mengambil daftar latihan untuk fase tertentu.
  Future<List<RehabExercise>> getExercises(int phaseId) async {
    final data = await _apiService.getExercisesByPhase(phaseId);
    return data.map((e) => RehabExercise.fromMap(e)).toList();
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
    late StreamController<List<Map<String, dynamic>>> controller;
    List<Map<String, dynamic>> currentData = [];

    controller = StreamController<List<Map<String, dynamic>>>(
      onListen: () async {
        // Initial load
        try {
          final data = await _apiService.getRehabProgress(userId);
          if (data != null) {
            currentData = [data];
          }
          controller.add(currentData);
        } catch (e) {
          controller.addError(e);
        }

        // Listen for real-time updates
        _socketService.onRehabUpdated((updateData) {
          final action = updateData['action'];
          final rehabData = updateData['data'];

          if (action == 'progress_updated') {
            currentData = [rehabData];
            controller.add(currentData);
          }
        });
      },
      onCancel: () {
        _socketService.offRehabUpdated();
      },
    );

    return controller.stream;
  }

  /// Stream log latihan pengguna — otomatis tampil saat latihan baru dicatat.
  Stream<List<Map<String, dynamic>>> streamExerciseLogs(String userId) {
    late StreamController<List<Map<String, dynamic>>> controller;
    List<Map<String, dynamic>> currentData = [];

    controller = StreamController<List<Map<String, dynamic>>>(
      onListen: () async {
        // Initial load
        try {
          final data = await _apiService.getExerciseLogs(userId);
          currentData = data;
          controller.add(currentData);
        } catch (e) {
          controller.addError(e);
        }

        // Listen for real-time updates
        _socketService.onRehabUpdated((updateData) {
          final action = updateData['action'];
          final rehabData = updateData['data'];

          if (action == 'exercise_logged') {
            currentData.insert(0, rehabData);
            controller.add(currentData);
          }
        });
      },
      onCancel: () {
        _socketService.offRehabUpdated();
      },
    );

    return controller.stream;
  }

  // ─── Writes ────────────────────────────────────────────────────────────────

  /// Mencatat log aktivitas terakhir.
  Future<void> logActivity(String userId) async {
    await _apiService.updateRehabProgress(
      userId: userId,
      streakCount: null, // Will be calculated on backend
    );
  }

  /// Mencatat penyelesaian sesi latihan ke log latihan.
  Future<void> logExerciseCompletion({
    required String userId,
    required String exerciseId,
    required int durationActualSeconds,
    bool isAborted = false,
    String? abortReason,
  }) async {
    await _apiService.logExercise(
      exerciseId: exerciseId,
      durationSeconds: durationActualSeconds,
      isAborted: isAborted,
      abortReason: abortReason,
    );

    // Update last activity
    await logActivity(userId);
  }

  // ─── Quiz & Phase Transition ─────────────────────────────────────────────

  /// Mengambil daftar pertanyaan quiz untuk transisi dari fase tertentu.
  Future<List<RehabQuizQuestion>> getQuizQuestions(int phaseFrom) async {
    // Note: Backend doesn't have quiz questions endpoint yet
    // Return empty list for now
    return [];
  }

  /// Mencatat percobaan kuis.
  Future<void> submitQuizAttempt({
    required String userId,
    required int phaseFrom,
    required int score,
    required bool passed,
  }) async {
    // Note: Backend doesn't have quiz attempt endpoint yet
    // This will be implemented when backend supports it
    if (passed) {
      await updatePhase(userId, phaseFrom + 1);
    }
  }

  /// Memperbaharui fase pengguna.
  Future<void> updatePhase(String userId, int newPhaseId) async {
    await _apiService.updateRehabProgress(
      userId: userId,
      currentPhaseId: newPhaseId,
    );
  }
}
