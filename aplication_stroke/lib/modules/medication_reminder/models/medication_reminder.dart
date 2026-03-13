/// ====================================================================
/// File: medication_reminder.dart
/// --------------------------------------------------------------------
/// Model Pengingat Obat (Medication Reminder)
///
/// Dokumen ini mendefinisikan struktur data untuk pengingat obat
/// yang akan dikirimkan kepada pengguna.
///
/// Properties:
/// - id: ID unik pengingat obat
/// - userId: ID pengguna
/// - name: Nama obat
/// - dose: Dosis obat (contoh: "500mg")
/// - quantity: Jumlah obat saat ini (stok)
/// - timesPerDay: Berapa kali minum obat per hari
/// - times: Jam pemberian obat (list TimeOfDay)
/// - takenTimes: Jumlah obat yang sudah diminum hari ini
/// - isActive: Status aktif/nonaktif alarm
/// - alarmType: Tipe alarm (medicine/exercise)
/// - createdAt: Tanggal dibuat
/// - updatedAt: Tanggal diperbarui
///
/// Backward Compatibility Properties:
/// - taken: Alias untuk takenTimes > 0
/// - time: Alias untuk times[0] (waktu pertama)
/// - period: Alias untuk menentukan periode (pagi/siang/sore/malam)
/// - note: Catatan tambahan
///
/// Author: Tim Developer Synexa
/// ====================================================================

import 'package:flutter/material.dart';

enum AlarmType { medicine, exercise }

class MedicationReminder {
  final String id;
  final String? userId;
  final String name;
  final String? dose;
  final int quantity;
  final int timesPerDay;
  final List<TimeOfDay> times;
  final int takenTimes;
  final bool isActive;
  final AlarmType alarmType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Backward compatibility
  final String? note;
  final String period;

  const MedicationReminder({
    required this.id,
    this.userId,
    required this.name,
    this.dose,
    this.quantity = 0,
    this.timesPerDay = 1,
    this.times = const [],
    this.takenTimes = 0,
    this.isActive = true,
    this.alarmType = AlarmType.medicine,
    this.createdAt,
    this.updatedAt,
    this.note,
    this.period = 'Semua',
  });

  /// Compliance percentage (kepatuhan pasien)
  double get complianceRate {
    if (timesPerDay == 0) return 0;
    return (takenTimes / timesPerDay * 100).clamp(0, 100);
  }

  /// Remaining quantity after taking medicine
  int get remainingQuantity => quantity - takenTimes;

  /// Check if all doses taken today
  bool get isAllTaken => takenTimes >= timesPerDay;

  /// Backward compatibility - taken is true if takenTimes > 0
  bool get taken => takenTimes > 0;

  /// Backward compatibility - time is first time in list
  TimeOfDay get time =>
      times.isNotEmpty ? times.first : const TimeOfDay(hour: 0, minute: 0);

  factory MedicationReminder.fromMap(Map<String, dynamic> map) {
    // Parse times from string format "HH:mm,HH:mm,..."
    List<TimeOfDay> parsedTimes = [];
    final timesStr = map['times']?.toString() ?? '';
    if (timesStr.isNotEmpty) {
      final timeParts = timesStr.split(',');
      for (var t in timeParts) {
        final parts = t.trim().split(':');
        if (parts.length == 2) {
          final hour = int.tryParse(parts[0]) ?? 0;
          final minute = int.tryParse(parts[1]) ?? 0;
          parsedTimes.add(TimeOfDay(hour: hour, minute: minute));
        }
      }
    }

    // Determine period based on first time
    String period = 'Semua';
    if (parsedTimes.isNotEmpty) {
      final hour = parsedTimes.first.hour;
      if (hour >= 5 && hour < 12) {
        period = 'Pagi';
      } else if (hour >= 12 && hour < 15) {
        period = 'Siang';
      } else if (hour >= 15 && hour < 18) {
        period = 'Sore';
      } else {
        period = 'Malam';
      }
    }

    return MedicationReminder(
      id: map['id'].toString(),
      userId: map['user_id']?.toString(),
      name: map['name']?.toString() ?? '',
      dose: map['dose']?.toString(),
      quantity: map['quantity'] as int? ?? 0,
      timesPerDay: map['times_per_day'] as int? ?? 1,
      times: parsedTimes,
      takenTimes: map['taken_times'] as int? ?? 0,
      isActive: map['is_active'] as bool? ?? true,
      alarmType: map['alarm_type'] == 'exercise'
          ? AlarmType.exercise
          : AlarmType.medicine,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
      // Backward compatibility
      note: map['note']?.toString(),
      period: period,
    );
  }

  Map<String, dynamic> toMap() {
    final timesStr = times
        .map(
          (t) =>
              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
        )
        .join(',');

    return {
      'user_id': userId,
      'name': name,
      'dose': dose,
      'quantity': quantity,
      'times_per_day': timesPerDay,
      'times': timesStr,
      'taken_times': takenTimes,
      'is_active': isActive,
      'alarm_type': alarmType == AlarmType.exercise ? 'exercise' : 'medicine',
      'note': note,
    };
  }

  MedicationReminder copyWith({
    String? id,
    String? userId,
    String? name,
    String? dose,
    int? quantity,
    int? timesPerDay,
    List<TimeOfDay>? times,
    int? takenTimes,
    bool? isActive,
    AlarmType? alarmType,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? note,
    String? period,
  }) {
    return MedicationReminder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      dose: dose ?? this.dose,
      quantity: quantity ?? this.quantity,
      timesPerDay: timesPerDay ?? this.timesPerDay,
      times: times ?? this.times,
      takenTimes: takenTimes ?? this.takenTimes,
      isActive: isActive ?? this.isActive,
      alarmType: alarmType ?? this.alarmType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      note: note ?? this.note,
      period: period ?? this.period,
    );
  }
}
