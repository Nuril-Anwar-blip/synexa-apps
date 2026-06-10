class HealthLog {
  final String? id;
  final String userId;
  final DateTime logDate;
  final int? systolicBp;
  final int? diastolicBp;
  final double? bloodSugar;
  final double? weightKg;
  final String? notes;

  HealthLog({
    this.id,
    required this.userId,
    required this.logDate,
    this.systolicBp,
    this.diastolicBp,
    this.bloodSugar,
    this.weightKg,
    this.notes,
  });

  String get logType {
    if (systolicBp != null || diastolicBp != null) return 'blood_pressure';
    if (bloodSugar != null) return 'blood_sugar';
    return 'weight';
  }

  factory HealthLog.fromMap(Map<String, dynamic> map) {
    return HealthLog(
      id: map['id']?.toString(),
      userId: map['user_id'].toString(),
      logDate: DateTime.tryParse(map['log_date']?.toString() ?? '') ??
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      systolicBp: (map['systolic_bp'] as num?)?.toInt(),
      diastolicBp: (map['diastolic_bp'] as num?)?.toInt(),
      bloodSugar: (map['blood_sugar'] as num?)?.toDouble(),
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      notes: map['notes']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'log_date': logDate.toIso8601String().split('T').first,
      if (systolicBp != null) 'systolic_bp': systolicBp,
      if (diastolicBp != null) 'diastolic_bp': diastolicBp,
      if (bloodSugar != null) 'blood_sugar': bloodSugar,
      if (weightKg != null) 'weight_kg': weightKg,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}
