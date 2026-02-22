import 'dart:convert';

class RehabPhase {
  final int id;
  final String name;
  final int weeksMin;
  final int weeksMax;
  final String targetDescription;
  final String dailyDurationMinutes;
  final List<String> safetyNotes;

  RehabPhase({
    required this.id,
    required this.name,
    required this.weeksMin,
    required this.weeksMax,
    required this.targetDescription,
    required this.dailyDurationMinutes,
    required this.safetyNotes,
  });

  factory RehabPhase.fromMap(Map<String, dynamic> map) {
    return RehabPhase(
      id: map['id'] as int,
      name: map['name'] as String? ?? '',
      weeksMin: map['duration_weeks_min'] as int? ?? 0,
      weeksMax: map['duration_weeks_max'] as int? ?? 0,
      targetDescription: map['target_description'] as String? ?? '',
      dailyDurationMinutes: map['daily_duration_minutes'] as String? ?? '',
      safetyNotes: List<String>.from(map['safety_notes'] ?? []),
    );
  }
}

class RehabExercise {
  final String id;
  final int phaseId;
  final String timeCategory; // pagi, siang, sore
  final String name;
  final List<String> instructions;
  final String durationText;
  final int durationSeconds;
  final bool isRepetition;
  final String? mediaUrl;

  RehabExercise({
    required this.id,
    required this.phaseId,
    required this.timeCategory,
    required this.name,
    required this.instructions,
    required this.durationText,
    required this.durationSeconds,
    required this.isRepetition,
    this.mediaUrl,
  });

  factory RehabExercise.fromMap(Map<String, dynamic> map) {
    return RehabExercise(
      id: map['id'] as String,
      phaseId: map['phase_id'] as int,
      timeCategory: map['time_category'] as String? ?? 'pagi',
      name: map['name'] as String? ?? '',
      instructions: List<String>.from(map['instructions'] ?? []),
      durationText: map['duration_text'] as String? ?? '',
      durationSeconds: map['duration_seconds'] as int? ?? 0,
      isRepetition: map['is_repetition'] as bool? ?? false,
      mediaUrl: map['media_url'] as String?,
    );
  }
}

class RehabProgress {
  final String userId;
  final int currentPhaseId;
  final DateTime phaseStartedAt;
  final DateTime? lastQuizAt;
  final int streakCount;

  RehabProgress({
    required this.userId,
    required this.currentPhaseId,
    required this.phaseStartedAt,
    this.lastQuizAt,
    this.streakCount = 0,
  });

  factory RehabProgress.fromMap(Map<String, dynamic> map) {
    return RehabProgress(
      userId: map['user_id'] as String,
      currentPhaseId: map['current_phase_id'] as int? ?? 1,
      phaseStartedAt: DateTime.parse(map['phase_started_at']),
      lastQuizAt: map['last_quiz_at'] != null ? DateTime.parse(map['last_quiz_at']) : null,
      streakCount: map['streak_count'] as int? ?? 0,
    );
  }
}

class RehabQuizQuestion {
  final String id;
  final int fromPhaseId;
  final String questionText;
  final bool isCritical;
  final int orderIndex;

  RehabQuizQuestion({
    required this.id,
    required this.fromPhaseId,
    required this.questionText,
    required this.isCritical,
    required this.orderIndex,
  });

  factory RehabQuizQuestion.fromMap(Map<String, dynamic> map) {
    return RehabQuizQuestion(
      id: map['id'] as String,
      fromPhaseId: map['from_phase_id'] as int,
      questionText: map['question_text'] as String? ?? '',
      isCritical: map['is_critical'] as bool? ?? false,
      orderIndex: map['order_index'] as int? ?? 0,
    );
  }
}
