class RehabPhase {
  final String id;
  final int phaseNumber;
  final String name;
  final String? description;
  final int? durationWeeks;
  final int requiredScore;

  RehabPhase({
    required this.id,
    required this.phaseNumber,
    required this.name,
    this.description,
    this.durationWeeks,
    this.requiredScore = 0,
  });

  factory RehabPhase.fromMap(Map<String, dynamic> map) {
    return RehabPhase(
      id: map['id'].toString(),
      phaseNumber: map['phase_number'] as int? ?? 1,
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      durationWeeks: map['duration_weeks'] as int?,
      requiredScore: map['required_score'] as int? ?? 0,
    );
  }
}

class RehabExercise {
  final String id;
  final String phaseId;
  final int phaseNumber;
  final String name;
  final List<String> instructions;
  final String durationText;
  final int durationSeconds;
  final int? repetitions;
  final String? sessionPeriod;
  final String? mediaUrl;

  RehabExercise({
    required this.id,
    required this.phaseId,
    required this.phaseNumber,
    required this.name,
    required this.instructions,
    required this.durationText,
    required this.durationSeconds,
    this.repetitions,
    this.sessionPeriod,
    this.mediaUrl,
  });

  factory RehabExercise.fromMap(Map<String, dynamic> map) {
    final rawInstructions = map['instructions'];
    final instructions = <String>[];
    if (rawInstructions is List) {
      for (final item in rawInstructions) {
        final text = item?.toString().trim() ?? '';
        if (text.isNotEmpty) instructions.add(text);
      }
    } else if (rawInstructions != null) {
      for (final line in rawInstructions.toString().split('\n')) {
        final text = line.trim();
        if (text.isNotEmpty) instructions.add(text);
      }
    }
    if (instructions.isEmpty) {
      instructions.add('Ikuti petunjuk latihan sesuai kondisi Anda.');
    }

    final seconds = map['duration_seconds'] as int? ?? 600;
    return RehabExercise(
      id: map['id'].toString(),
      phaseId: map['phase_id'].toString(),
      phaseNumber: map['phase_number'] as int? ?? 1,
      name: map['name'] as String? ?? '',
      instructions: instructions,
      durationText:
          map['duration_text']?.toString() ??
          '${(seconds / 60).round()} menit',
      durationSeconds: seconds,
      repetitions: map['repetitions'] as int?,
      sessionPeriod: map['session_period'] as String?,
      mediaUrl: map['video_url'] as String? ?? map['media_url'] as String?,
    );
  }
}

class RehabProgress {
  final String userId;
  final String currentPhaseId;
  final int currentPhaseNumber;
  final DateTime startedAt;
  final DateTime? lastSessionDate;

  RehabProgress({
    required this.userId,
    required this.currentPhaseId,
    required this.currentPhaseNumber,
    required this.startedAt,
    this.lastSessionDate,
  });

  factory RehabProgress.fromMap(Map<String, dynamic> map) {
    final phase = map['rehab_phases'];
    final phaseNumber = phase is Map
        ? phase['phase_number'] as int? ?? 1
        : map['current_phase_number'] as int? ?? 1;

    return RehabProgress(
      userId: map['user_id'] as String,
      currentPhaseId: map['current_phase_id'].toString(),
      currentPhaseNumber: phaseNumber,
      startedAt: DateTime.tryParse(map['started_at']?.toString() ?? '') ??
          DateTime.now(),
      lastSessionDate: map['last_session_date'] != null
          ? DateTime.tryParse(map['last_session_date'].toString())
          : null,
    );
  }
}
