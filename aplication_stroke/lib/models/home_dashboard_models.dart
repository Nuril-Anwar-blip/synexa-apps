import 'package:flutter/material.dart';

/// Satu dosis obat yang dijadwalkan hari ini.
class TodayMedicationDose {
  final String? logId;
  final String reminderId;
  final String? userMedicationId;
  final String medicationName;
  final String dosage;
  final int doseAmount;
  final int? quantityRemaining;
  final TimeOfDay time;
  final String period;
  final DateTime scheduledAt;
  final bool taken;

  const TodayMedicationDose({
    this.logId,
    required this.reminderId,
    this.userMedicationId,
    required this.medicationName,
    required this.dosage,
    this.doseAmount = 1,
    this.quantityRemaining,
    required this.time,
    required this.period,
    required this.scheduledAt,
    required this.taken,
  });

  TodayMedicationDose copyWith({
    bool? taken,
    String? logId,
    int? quantityRemaining,
  }) {
    return TodayMedicationDose(
      logId: logId ?? this.logId,
      reminderId: reminderId,
      userMedicationId: userMedicationId,
      medicationName: medicationName,
      dosage: dosage,
      doseAmount: doseAmount,
      quantityRemaining: quantityRemaining ?? this.quantityRemaining,
      time: time,
      period: period,
      scheduledAt: scheduledAt,
      taken: taken ?? this.taken,
    );
  }
}

/// Latihan rehabilitasi yang direncanakan hari ini.
class TodayExercise {
  final String id;
  final String name;
  final String sessionPeriod;
  final String durationText;
  final bool completed;

  const TodayExercise({
    required this.id,
    required this.name,
    required this.sessionPeriod,
    required this.durationText,
    required this.completed,
  });

  TodayExercise copyWith({bool? completed}) {
    return TodayExercise(
      id: id,
      name: name,
      sessionPeriod: sessionPeriod,
      durationText: durationText,
      completed: completed ?? this.completed,
    );
  }
}

/// Status apoteker / dokter untuk kartu Tenaga Medis.
class StaffMemberStatus {
  final String id;
  final String name;
  final String staffType;
  final String? photoUrl;
  final String subtitle;
  final bool isOnline;
  final bool isOnDuty;

  const StaffMemberStatus({
    required this.id,
    required this.name,
    required this.staffType,
    this.photoUrl,
    required this.subtitle,
    required this.isOnline,
    required this.isOnDuty,
  });

  bool get isAvailable => isOnline || isOnDuty;
  bool get isPharmacist => staffType == 'pharmacist';
}
