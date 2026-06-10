import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../modules/medication_reminder/medication_reminder_screen.dart';

/// Repository obat — membaca/menulis `medication_reminders` & `medication_logs`.
class MedicationReminderRepository {
  MedicationReminderRepository._();
  static final instance = MedicationReminderRepository._();

  final _db = Supabase.instance.client;

  Future<List<MedicationV2>> loadForPatient(String patientId) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final reminders = await _db
        .from('medication_reminders')
        .select('*, user_medications(quantity_remaining, quantity_total)')
        .eq('user_id', patientId)
        .order('created_at', ascending: false);

    final logs = await _db
        .from('medication_logs')
        .select()
        .eq('user_id', patientId)
        .gte('scheduled_time', todayStart.toUtc().toIso8601String())
        .lt('scheduled_time', todayEnd.toUtc().toIso8601String());

    final meds = <MedicationV2>[];

    for (final raw in reminders as List) {
      final map = Map<String, dynamic>.from(raw as Map);
      final reminderId = map['id'].toString();
      final isActive = map['is_active'] as bool? ?? true;
      final medName = map['medication_name']?.toString() ?? 'Obat';
      final dosage = map['dosage']?.toString() ?? '';
      final note = map['notes']?.toString() ?? '';
      final soundOn = map['sound_enabled'] as bool? ?? true;
      final userMedId = map['user_medication_id']?.toString();
      final userMed = map['user_medications'];
      int stock = 0;
      int totalStock = 0;
      if (userMed is Map) {
        stock = (userMed['quantity_remaining'] as num?)?.toInt() ?? 0;
        totalStock = (userMed['quantity_total'] as num?)?.toInt() ?? stock;
      }
      final times = _parseReminderTimes(map['reminder_times']);

      for (final timeStr in times) {
        final parts = timeStr.split(':');
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
        final scheduledAt = DateTime(now.year, now.month, now.day, hour, minute);

        Map<String, dynamic>? logMatch;
        for (final log in logs as List) {
          final lm = Map<String, dynamic>.from(log as Map);
          if (lm['reminder_id']?.toString() != reminderId) continue;
          final st = DateTime.tryParse(lm['scheduled_time']?.toString() ?? '');
          if (st != null && st.hour == hour && st.minute == minute) {
            logMatch = lm;
            break;
          }
        }

        final taken = logMatch?['status']?.toString() == 'taken';
        meds.add(
          MedicationV2(
            id: '${reminderId}_${hour}_$minute',
            reminderId: reminderId,
            logId: logMatch?['id']?.toString(),
            userMedicationId: userMedId,
            scheduledAt: scheduledAt,
            name: medName,
            dose: dosage,
            note: note,
            time: TimeOfDay(hour: hour, minute: minute),
            period: _periodFromHour(hour),
            taken: taken,
            isActive: isActive,
            alarmSound: soundOn ? 'default' : 'silent',
            stock: stock,
            totalStock: totalStock > 0 ? totalStock : stock,
          ),
        );
      }
    }

    meds.sort((a, b) {
      final aMin = a.time.hour * 60 + a.time.minute;
      final bMin = b.time.hour * 60 + b.time.minute;
      return aMin.compareTo(bMin);
    });
    return meds;
  }

  Future<void> toggleTaken(MedicationV2 med, String patientId) async {
    if (med.reminderId == null || med.scheduledAt == null) return;
    final taken = !med.taken;
    final payload = {
      'status': taken ? 'taken' : 'pending',
      'taken_at': taken ? DateTime.now().toUtc().toIso8601String() : null,
    };

    if (med.logId != null) {
      await _db.from('medication_logs').update(payload).eq('id', med.logId!);
    } else {
      final inserted = await _db
          .from('medication_logs')
          .insert({
            'user_id': patientId,
            'reminder_id': med.reminderId,
            'medication_name': med.name,
            'scheduled_time': med.scheduledAt!.toUtc().toIso8601String(),
            ...payload,
          })
          .select('id')
          .single();
      med.logId = inserted['id']?.toString();
    }

    if (taken && med.userMedicationId != null) {
      await _adjustStock(med.userMedicationId!, -_parseDoseAmount(med.dose));
    } else if (!taken && med.userMedicationId != null) {
      await _adjustStock(med.userMedicationId!, _parseDoseAmount(med.dose));
    }
    med.taken = taken;
  }

  Future<void> setActive(String reminderId, bool active) async {
    await _db
        .from('medication_reminders')
        .update({'is_active': active})
        .eq('id', reminderId);
  }

  Future<void> deleteReminder(String reminderId) async {
    await _db.from('medication_reminders').delete().eq('id', reminderId);
  }

  Future<void> updateReminder({
    required String reminderId,
    String? medicationName,
    String? dosage,
    String? notes,
    List<String>? reminderTimes,
    bool? soundEnabled,
  }) async {
    final payload = <String, dynamic>{
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (medicationName != null) payload['medication_name'] = medicationName;
    if (dosage != null) payload['dosage'] = dosage;
    if (notes != null) payload['notes'] = notes;
    if (reminderTimes != null) payload['reminder_times'] = reminderTimes;
    if (soundEnabled != null) payload['sound_enabled'] = soundEnabled;
    await _db.from('medication_reminders').update(payload).eq('id', reminderId);
  }

  Future<void> createFromDialog({
    required String patientId,
    required String name,
    required String dose,
    required String note,
    required List<TimeOfDay> times,
    String? stockStr,
    String alarmSound = 'default',
  }) async {
    final timesJson = times
        .map(
          (t) =>
              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
        )
        .toList();

    int? qty;
    final parsedStock = int.tryParse(stockStr ?? '');
    if (parsedStock != null && parsedStock > 0) qty = parsedStock;

    String? userMedId;
    final medRow = await _db
        .from('medications')
        .select('id')
        .ilike('name', name.trim())
        .maybeSingle();

    String medicationId;
    if (medRow != null) {
      medicationId = medRow['id'].toString();
    } else {
      final inserted = await _db
          .from('medications')
          .insert({
            'name': name.trim(),
            'category': 'Lainnya',
            'form': 'Tablet',
            'strength': dose,
          })
          .select('id')
          .single();
      medicationId = inserted['id'].toString();
    }

    final userMedPayload = <String, dynamic>{
      'user_id': patientId,
      'medication_id': medicationId,
      'dose': dose,
      'note': note,
      'frequency': '${times.length}x sehari',
      'is_active': true,
    };
    if (qty != null) {
      userMedPayload['quantity_total'] = qty;
      userMedPayload['quantity_remaining'] = qty;
    }

    final userMed = await _db
        .from('user_medications')
        .insert(userMedPayload)
        .select('id')
        .single();
    userMedId = userMed['id']?.toString();

    await _db.from('medication_reminders').insert({
      'user_id': patientId,
      'user_medication_id': userMedId,
      'medication_name': name.trim(),
      'dosage': dose.isEmpty ? '1 tablet' : dose,
      'reminder_times': timesJson,
      'notes': note,
      'is_active': true,
      'sound_enabled': alarmSound != 'silent',
      'vibration_enabled': true,
    });
  }

  Future<void> _adjustStock(String userMedId, int delta) async {
    try {
      final row = await _db
          .from('user_medications')
          .select('quantity_remaining, quantity_total')
          .eq('id', userMedId)
          .maybeSingle();
      if (row == null || row['quantity_remaining'] == null) return;
      final current = (row['quantity_remaining'] as num).toInt();
      final total = (row['quantity_total'] as num?)?.toInt() ?? current;
      final next = (current + delta).clamp(0, total);
      await _db
          .from('user_medications')
          .update({'quantity_remaining': next})
          .eq('id', userMedId);
    } catch (_) {}
  }

  List<String> _parseReminderTimes(dynamic raw) {
    if (raw == null) return ['08:00'];
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
      return [raw];
    }
    return ['08:00'];
  }

  String _periodFromHour(int hour) {
    if (hour >= 18) return 'Malam';
    if (hour >= 15) return 'Sore';
    if (hour >= 11) return 'Siang';
    return 'Pagi';
  }

  int _parseDoseAmount(String dosage) {
    final match = RegExp(r'(\d+)').firstMatch(dosage);
    return int.tryParse(match?.group(1) ?? '') ?? 1;
  }
}
