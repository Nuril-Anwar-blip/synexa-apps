import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/home_dashboard_models.dart';
import 'rehab_service.dart';
import 'staff_presence_service.dart';

class HomeDashboardService {
  HomeDashboardService._();
  static final instance = HomeDashboardService._();

  final _client = Supabase.instance.client;
  final _rehab = RehabService();

  // ── Obat hari ini ────────────────────────────────────────────

  Future<List<TodayMedicationDose>> loadTodayMedications(
    String patientId,
  ) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final todayDow = now.weekday % 7; // Mon=1..Sun=7 → Sun=0

    final reminders = await _client
        .from('medication_reminders')
        .select('*, user_medications(quantity_remaining, quantity_total)')
        .eq('user_id', patientId)
        .eq('is_active', true);

    final logs = await _client
        .from('medication_logs')
        .select()
        .eq('user_id', patientId)
        .gte('scheduled_time', todayStart.toUtc().toIso8601String())
        .lt('scheduled_time', todayEnd.toUtc().toIso8601String());

    final doses = <TodayMedicationDose>[];

    for (final row in reminders as List) {
      final map = Map<String, dynamic>.from(row as Map);
      final days = (map['days_of_week'] as List?)?.cast<int>() ??
          [0, 1, 2, 3, 4, 5, 6];
      if (!days.contains(todayDow)) continue;

      final reminderId = map['id'].toString();
      final userMedId = map['user_medication_id']?.toString();
      final medName = map['medication_name']?.toString() ?? 'Obat';
      final dosage = map['dosage']?.toString() ?? '';
      final doseAmount = _parseDoseAmount(dosage);
      final userMed = map['user_medications'];
      int? qtyRemaining;
      if (userMed is Map) {
        qtyRemaining = (userMed['quantity_remaining'] as num?)?.toInt();
      }
      final times = _parseReminderTimes(map['reminder_times']);

      for (final timeStr in times) {
        final parts = timeStr.split(':');
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
        final scheduledAt = DateTime(
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );

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

        final status = logMatch?['status']?.toString() ?? 'pending';
        doses.add(
          TodayMedicationDose(
            logId: logMatch?['id']?.toString(),
            reminderId: reminderId,
            userMedicationId: userMedId,
            medicationName: medName,
            dosage: dosage,
            doseAmount: doseAmount,
            quantityRemaining: qtyRemaining,
            time: TimeOfDay(hour: hour, minute: minute),
            period: _periodFromHour(hour),
            scheduledAt: scheduledAt,
            taken: status == 'taken',
          ),
        );
      }
    }

    doses.sort(
      (a, b) => a.scheduledAt.compareTo(b.scheduledAt),
    );
    return doses;
  }

  Future<void> toggleMedicationDose(
    TodayMedicationDose dose,
    String patientId,
    bool taken,
  ) async {
    final payload = {
      'status': taken ? 'taken' : 'pending',
      'taken_at': taken ? DateTime.now().toUtc().toIso8601String() : null,
    };

    if (dose.logId != null) {
      await _client
          .from('medication_logs')
          .update(payload)
          .eq('id', dose.logId!);
    } else {
      await _client.from('medication_logs').insert({
        'user_id': patientId,
        'reminder_id': dose.reminderId,
        'medication_name': dose.medicationName,
        'scheduled_time': dose.scheduledAt.toUtc().toIso8601String(),
        ...payload,
      });
    }

    if (taken && dose.userMedicationId != null) {
      await _decrementMedicationStock(
        dose.userMedicationId!,
        dose.doseAmount,
      );
    } else if (!taken && dose.userMedicationId != null) {
      await _incrementMedicationStock(
        dose.userMedicationId!,
        dose.doseAmount,
      );
    }
  }

  Future<void> _decrementMedicationStock(String userMedId, int amount) async {
    try {
      final row = await _client
          .from('user_medications')
          .select('quantity_remaining')
          .eq('id', userMedId)
          .maybeSingle();
      if (row == null || row['quantity_remaining'] == null) return;
      final current = (row['quantity_remaining'] as num).toInt();
      await _client
          .from('user_medications')
          .update({'quantity_remaining': (current - amount).clamp(0, 9999)})
          .eq('id', userMedId);
    } catch (_) {}
  }

  Future<void> _incrementMedicationStock(String userMedId, int amount) async {
    try {
      final row = await _client
          .from('user_medications')
          .select('quantity_remaining, quantity_total')
          .eq('id', userMedId)
          .maybeSingle();
      if (row == null || row['quantity_remaining'] == null) return;
      final current = (row['quantity_remaining'] as num).toInt();
      final total = (row['quantity_total'] as num?)?.toInt() ?? current + amount;
      await _client.from('user_medications').update({
        'quantity_remaining': (current + amount).clamp(0, total),
      }).eq('id', userMedId);
    } catch (_) {}
  }

  Future<void> toggleExercise(
    TodayExercise exercise,
    String patientId,
    bool completed,
  ) async {
    final today = DateTime.now().toIso8601String().split('T').first;

    if (completed) {
      final existing = await _client
          .from('rehab_exercise_logs')
          .select('id')
          .eq('user_id', patientId)
          .eq('exercise_id', exercise.id)
          .eq('session_date', today)
          .maybeSingle();

      if (existing != null) {
        await _client
            .from('rehab_exercise_logs')
            .update({'is_completed': true})
            .eq('id', existing['id']);
      } else {
        await _rehab.logExerciseCompletion(
          userId: patientId,
          exerciseId: exercise.id,
          durationActualSeconds: 60,
          isCompleted: true,
          notes: 'Absen dari home',
        );
      }
    } else {
      await _client
          .from('rehab_exercise_logs')
          .update({'is_completed': false})
          .eq('user_id', patientId)
          .eq('exercise_id', exercise.id)
          .eq('session_date', today);
    }
  }

  // ── Latihan hari ini ─────────────────────────────────────────

  Future<List<TodayExercise>> loadTodayExercises(String patientId) async {
    final progress = await _rehab.getUserProgress(patientId);
    if (progress == null) return [];

    final exercises = await _rehab.getExercises(progress.currentPhaseNumber);
    if (exercises.isEmpty) return [];

    final today = DateTime.now().toIso8601String().split('T').first;
    final logs = await _client
        .from('rehab_exercise_logs')
        .select('exercise_id, is_completed')
        .eq('user_id', patientId)
        .eq('session_date', today);

    final completedIds = <String>{};
    for (final log in logs as List) {
      final m = Map<String, dynamic>.from(log as Map);
      if (m['is_completed'] == true) {
        completedIds.add(m['exercise_id'].toString());
      }
    }

    return exercises
        .map(
          (e) => TodayExercise(
            id: e.id,
            name: e.name,
            sessionPeriod: e.sessionPeriod ?? 'umum',
            durationText: e.durationText,
            completed: completedIds.contains(e.id),
          ),
        )
        .toList();
  }

  // ── Tenaga medis jaga / online ───────────────────────────────

  Future<List<StaffMemberStatus>> loadStaffStatus({
    String? pairedPharmacistId,
  }) async {
    final now = DateTime.now();
    final todayDow = now.weekday % 7;
    final currentMinutes = now.hour * 60 + now.minute;

    List<dynamic> pharmacists = [];
    List<dynamic> doctors = [];
    List<dynamic> presenceRows = [];
    List<dynamic> shiftRows = [];

    try {
      pharmacists = await _client
          .from('pharmacists')
          .select('id, name, profile_picture, pharmacy_name')
          .eq('is_active', true);
    } catch (_) {}

    try {
      doctors = await _client
          .from('doctors')
          .select('id, name, profile_picture, specialization, hospital_name')
          .eq('is_active', true);
    } catch (_) {}

    try {
      presenceRows = await _client.from('staff_presence').select();
    } catch (_) {}

    try {
      shiftRows = await _client
          .from('staff_duty_shifts')
          .select()
          .eq('is_active', true)
          .eq('day_of_week', todayDow);
    } catch (_) {}

    final presenceMap = <String, Map<String, dynamic>>{};
    for (final p in presenceRows) {
      final m = Map<String, dynamic>.from(p as Map);
      final key = '${m['staff_type']}_${m['staff_id']}';
      presenceMap[key] = m;
    }

    bool isOnDuty(String staffId, String staffType) {
      for (final s in shiftRows) {
        final m = Map<String, dynamic>.from(s as Map);
        if (m['staff_id']?.toString() != staffId) continue;
        if (m['staff_type']?.toString() != staffType) continue;
        final start = _parseTimeMinutes(m['start_time']?.toString() ?? '');
        final end = _parseTimeMinutes(m['end_time']?.toString() ?? '');
        if (start == null || end == null) continue;
        if (end > start) {
          if (currentMinutes >= start && currentMinutes < end) return true;
        } else {
          // shift melewati tengah malam
          if (currentMinutes >= start || currentMinutes < end) return true;
        }
      }
      return false;
    }

    bool isOnline(String staffId, String staffType) {
      final p = presenceMap['${staffType}_$staffId'];
      if (p == null) return false;
      final lastSeen = DateTime.tryParse(p['last_seen_at']?.toString() ?? '');
      return StaffPresenceService.isRecentlyOnline(
        isOnlineFlag: p['is_online'] == true,
        lastSeen: lastSeen,
      );
    }

    final result = <StaffMemberStatus>[];

    for (final row in pharmacists) {
      final m = Map<String, dynamic>.from(row as Map);
      final id = m['id'].toString();
      result.add(
        StaffMemberStatus(
          id: id,
          name: m['name']?.toString() ?? 'Apoteker',
          staffType: 'pharmacist',
          photoUrl: m['profile_picture']?.toString(),
          subtitle: m['pharmacy_name']?.toString() ?? 'Apoteker Klinis',
          isOnline: isOnline(id, 'pharmacist'),
          isOnDuty: isOnDuty(id, 'pharmacist'),
        ),
      );
    }

    for (final row in doctors) {
      final m = Map<String, dynamic>.from(row as Map);
      final id = m['id'].toString();
      final spec = m['specialization']?.toString() ?? 'Dokter';
      final hospital = m['hospital_name']?.toString();
      result.add(
        StaffMemberStatus(
          id: id,
          name: m['name']?.toString() ?? 'Dokter',
          staffType: 'doctor',
          photoUrl: m['profile_picture']?.toString(),
          subtitle: hospital != null ? '$spec · $hospital' : spec,
          isOnline: isOnline(id, 'doctor'),
          isOnDuty: isOnDuty(id, 'doctor'),
        ),
      );
    }

    result.sort((a, b) {
      if (pairedPharmacistId != null) {
        final aPaired = a.id == pairedPharmacistId;
        final bPaired = b.id == pairedPharmacistId;
        if (aPaired != bPaired) return aPaired ? -1 : 1;
      }
      final aScore = a.isAvailable ? 0 : 1;
      final bScore = b.isAvailable ? 0 : 1;
      if (aScore != bScore) return aScore.compareTo(bScore);
      return a.name.compareTo(b.name);
    });

    return result;
  }

  RealtimeChannel subscribeMedicationLogs(
    String patientId,
    void Function() onChange,
  ) {
    return _client
        .channel('home_med_logs_$patientId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'medication_logs',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: patientId,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  RealtimeChannel subscribeExerciseLogs(
    String patientId,
    void Function() onChange,
  ) {
    return _client
        .channel('home_rehab_logs_$patientId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'rehab_exercise_logs',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: patientId,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  // ── Helpers ──────────────────────────────────────────────────

  List<String> _parseReminderTimes(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        return [raw];
      }
    }
    return [];
  }

  int _parseDoseAmount(String dosage) {
    final match = RegExp(r'(\d+)').firstMatch(dosage);
    return int.tryParse(match?.group(1) ?? '') ?? 1;
  }

  String _periodFromHour(int hour) {
    if (hour >= 5 && hour < 11) return 'pagi';
    if (hour >= 11 && hour < 15) return 'siang';
    if (hour >= 15 && hour < 21) return 'sore';
    return 'malam';
  }

  int? _parseTimeMinutes(String raw) {
    final parts = raw.split(':');
    if (parts.isEmpty) return null;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    return h * 60 + m;
  }
}
