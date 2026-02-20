class HealthLog {
  final String? id;
  final String userId;
  final String logType; // blood_pressure, blood_sugar, weight
  final int? valueSystolic;
  final int? valueDiastolic;
  final double? valueNumeric;
  final String? note;
  final DateTime recordedAt;

  HealthLog({
    this.id,
    required this.userId,
    required this.logType,
    this.valueSystolic,
    this.valueDiastolic,
    this.valueNumeric,
    this.note,
    required this.recordedAt,
  });

  factory HealthLog.fromMap(Map<String, dynamic> map) {
    return HealthLog(
      id: map['id'] as String?,
      userId: map['user_id'] as String,
      logType: map['log_type'] as String,
      valueSystolic: map['value_systolic'] as int?,
      valueDiastolic: map['value_diastolic'] as int?,
      valueNumeric: (map['value_numeric'] as num?)?.toDouble(),
      note: map['note'] as String?,
      recordedAt: DateTime.parse(map['recorded_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'log_type': logType,
      'value_systolic': valueSystolic,
      'value_diastolic': valueDiastolic,
      'value_numeric': valueNumeric,
      'note': note,
      'recorded_at': recordedAt.toIso8601String(),
    };
  }
}
