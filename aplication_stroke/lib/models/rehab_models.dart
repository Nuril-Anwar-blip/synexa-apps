class RehabPhase {
  final int id;
  final String name;

  RehabPhase({
    required this.id,
    required this.name,
  });

  factory RehabPhase.fromMap(Map<String, dynamic> map) {
    return RehabPhase(
      id: map['id'] as int,
      name: map['name'] as String? ?? '',
    );
  }
}

class RehabExercise {
  final String id;
  final int phaseId;
  final String name;
  final List<String> instructions;
  final String durationText;
  final int durationSeconds;
  final String? mediaUrl;

  RehabExercise({
    required this.id,
    required this.phaseId,
    required this.name,
    required this.instructions,
    required this.durationText,
    required this.durationSeconds,
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
      final text = rawInstructions.toString().trim();
      if (text.isNotEmpty) instructions.add(text);
    }
    if (instructions.isEmpty) {
      instructions.add('Ikuti petunjuk latihan sesuai kondisi Anda.');
    }

    final seconds = map['duration_seconds'] as int? ?? 600;
    return RehabExercise(
      id: map['id'].toString(),
      phaseId: map['phase_id'] as int,
      name: map['name'] as String? ?? '',
      instructions: instructions,
      durationText: map['duration_text']?.toString() ?? '${(seconds / 60).round()} menit',
      durationSeconds: seconds,
      mediaUrl: map['media_url'] as String?,
    );
  }
}

class RehabProgress {
  final String userId;
  final int currentPhaseId;
  final DateTime phaseStartedAt;
  final DateTime? lastQuizAt;

  RehabProgress({
    required this.userId,
    required this.currentPhaseId,
    required this.phaseStartedAt,
    this.lastQuizAt,
  });

  factory RehabProgress.fromMap(Map<String, dynamic> map) {
    return RehabProgress(
      userId: map['user_id'] as String,
      currentPhaseId: map['current_phase_id'] as int? ?? 1,
      phaseStartedAt: DateTime.parse(
        map['phase_started_at'] ?? DateTime.now().toIso8601String(),
      ),
      lastQuizAt: map['last_quiz_at'] != null
          ? DateTime.tryParse(map['last_quiz_at'].toString())
          : null,
    );
  }
}
