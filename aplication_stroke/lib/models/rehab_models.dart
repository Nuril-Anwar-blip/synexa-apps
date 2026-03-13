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
  final String timeCategory; // 'pagi', 'siang', 'sore'
  final String? mediaUrl;

  RehabExercise({
    required this.id,
    required this.phaseId,
    required this.name,
    required this.instructions,
    required this.durationText,
    required this.durationSeconds,
    this.timeCategory = 'pagi',
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
      timeCategory: map['time_category']?.toString() ?? 'pagi',
      mediaUrl: map['media_url'] as String?,
    );
  }
}

class RehabProgress {
  final String userId;
  final int currentPhaseId;
  final DateTime phaseStartedAt;
  final int streakCount;
  final DateTime? lastQuizAt;

  RehabProgress({
    required this.userId,
    required this.currentPhaseId,
    required this.phaseStartedAt,
    this.streakCount = 0,
    this.lastQuizAt,
  });

  factory RehabProgress.fromMap(Map<String, dynamic> map) {
    return RehabProgress(
      userId: map['user_id'] as String,
      currentPhaseId: map['current_phase_id'] as int? ?? 1,
      phaseStartedAt: DateTime.parse(
        map['phase_started_at'] ?? DateTime.now().toIso8601String(),
      ),
      streakCount: map['streak_count'] as int? ?? 0,
      lastQuizAt: map['last_quiz_at'] != null
          ? DateTime.tryParse(map['last_quiz_at'].toString())
          : null,
    );
  }
}

class RehabQuizQuestion {
  final String id;
  final int fromPhaseId;
  final String questionText;
  final List<QuizOption> options;
  final int orderIndex;

  RehabQuizQuestion({
    required this.id,
    required this.fromPhaseId,
    required this.questionText,
    required this.options,
    this.orderIndex = 0,
  });

  factory RehabQuizQuestion.fromMap(Map<String, dynamic> map) {
    return RehabQuizQuestion(
      id: map['id'].toString(),
      fromPhaseId: map['from_phase_id'] as int,
      questionText: map['question_text']?.toString() ?? '',
      options: (map['options'] as List? ?? [])
          .map((o) => QuizOption.fromMap(o as Map<String, dynamic>))
          .toList(),
      orderIndex: map['order_index'] as int? ?? 0,
    );
  }
}

class QuizOption {
  final String text;
  final int score;

  QuizOption({required this.text, required this.score});

  factory QuizOption.fromMap(Map<String, dynamic> map) {
    return QuizOption(
      text: map['text']?.toString() ?? '',
      score: map['score'] as int? ?? 0,
    );
  }
}
