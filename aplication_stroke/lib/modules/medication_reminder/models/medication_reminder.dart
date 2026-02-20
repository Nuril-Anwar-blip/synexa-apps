import 'package:flutter/material.dart';

class MedicationReminder {
  final String id;
  final String name;
  final String? dose;
  final String? note;
  final TimeOfDay time;
  final String period;
  final bool taken;
  final bool isActive;
  final int currentStock;
  final int totalStock;

  const MedicationReminder({
    required this.id,
    required this.name,
    required this.dose,
    required this.note,
    required this.time,
    required this.period,
    required this.taken,
    this.isActive = true,
    this.currentStock = 0,
    this.totalStock = 0,
  });

  factory MedicationReminder.fromMap(Map<String, dynamic> map) {
    final timeString = map['time']?.toString() ?? '00:00:00';
    final parts = timeString.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return MedicationReminder(
      id: map['id'].toString(),
      name: map['name']?.toString() ?? '',
      dose: map['dose']?.toString(),
      note: map['note']?.toString(),
      time: TimeOfDay(hour: hour, minute: minute),
      period: map['period']?.toString() ?? 'Semua',
      taken: map['taken'] as bool? ?? false,
      isActive: map['is_active'] as bool? ?? true,
      currentStock: map['current_stock'] as int? ?? 0,
      totalStock: map['total_stock'] as int? ?? 0,
    );
  }
}

