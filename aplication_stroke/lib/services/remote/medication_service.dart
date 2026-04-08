// ============================================================
// FILE: lib/services/medication_service.dart
// ============================================================

import 'package:supabase_flutter/supabase_flutter.dart';

// ── Model: data induk obat dari tabel medications ────────────
class MedicationMaster {
  final String id;
  final String name;
  final String? genericName;
  final String category;
  final String? subCategory;
  final String? form;
  final String? strength;
  final String? unit;
  final String? description;
  final bool isCommon;

  const MedicationMaster({
    required this.id,
    required this.name,
    this.genericName,
    required this.category,
    this.subCategory,
    this.form,
    this.strength,
    this.unit,
    this.description,
    this.isCommon = true,
  });

  factory MedicationMaster.fromMap(Map<String, dynamic> m) => MedicationMaster(
    id: m['id'].toString(),
    name: (m['name'] ?? '').toString(),
    genericName: m['generic_name']?.toString(),
    category: (m['category'] ?? 'Lainnya').toString(),
    subCategory: m['sub_category']?.toString(),
    form: m['form']?.toString(),
    strength: m['strength']?.toString(),
    unit: m['unit']?.toString(),
    description: m['description']?.toString(),
    isCommon: m['is_common'] as bool? ?? true,
  );

  // Dosis default: "20 mg", "500 mg", dll
  String get defaultDose => strength ?? '';

  String get doseWithUnit {
    if (defaultDose.isEmpty) return '';
    if (unit == null || unit!.isEmpty || unit == '—') return defaultDose;
    return '$defaultDose $unit';
  }
}

// ── Model: obat rutin milik pasien ───────────────────────────
class UserMedication {
  final String id;
  final String userId;
  final String? medicationId;
  final String medicationName;
  final String category;
  final String? subCategory;
  final String dose;
  final String unit;
  final String? note;
  final String frequency;
  final bool isActive;
  final DateTime createdAt;

  const UserMedication({
    required this.id,
    required this.userId,
    this.medicationId,
    required this.medicationName,
    required this.category,
    this.subCategory,
    required this.dose,
    this.unit = 'mg',
    this.note,
    this.frequency = '1x sehari',
    this.isActive = true,
    required this.createdAt,
  });

  factory UserMedication.fromMap(Map<String, dynamic> m) {
    // join dari medications (Supabase nested select)
    final med = m['medications'];
    final masterName = med is Map ? med['name']?.toString() : null;
    final masterCategory = med is Map ? med['category']?.toString() : null;
    final masterStrength = med is Map ? med['strength']?.toString() : null;
    final masterUnit = med is Map ? med['unit']?.toString() : null;

    final rawDose = m['dose']?.toString() ?? '';
    final resolvedDose = rawDose.isNotEmpty ? rawDose : (masterStrength ?? '');

    return UserMedication(
      id: m['id'].toString(),
      userId: (m['user_id'] ?? '').toString(),
      medicationId: m['medication_id']?.toString(),
      medicationName:
          masterName ??
          m['custom_name']?.toString() ??
          m['medication_name']?.toString() ??
          'Obat',
      category: m['category']?.toString() ?? masterCategory ?? 'Lainnya',
      subCategory: m['sub_category']?.toString(),
      dose: resolvedDose,
      unit: m['unit']?.toString() ?? masterUnit ?? 'mg',
      note: m['note']?.toString(),
      frequency: m['frequency']?.toString() ?? '1x sehari',
      isActive: m['is_active'] as bool? ?? true,
      createdAt:
          DateTime.tryParse(m['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  String get doseLabel {
    if (dose.isEmpty && unit.isEmpty) return '-';
    if (unit.isEmpty || unit == 'mg' && dose.endsWith('mg')) return dose;
    return '$dose $unit'.trim();
  }
}

// ── Singleton Service ─────────────────────────────────────────
class MedicationService {
  MedicationService._();
  static final MedicationService instance = MedicationService._();

  final SupabaseClient _db = Supabase.instance.client;

  // In-memory cache agar tidak fetch berulang per session
  List<MedicationMaster>? _masterCache;
  Map<String, List<MedicationMaster>>? _byCategoryCache;

  // ════════════════════════════════════════════════════════════
  // MASTER OBAT (tabel: medications)
  // ════════════════════════════════════════════════════════════

  Future<List<MedicationMaster>> fetchMedicationMaster({
    bool forceRefresh = false,
  }) async {
    if (_masterCache != null && !forceRefresh) return _masterCache!;

    final rows = await _db
        .from('medications')
        .select(
          'id, name, generic_name, category, sub_category, form, strength, unit, description, is_common',
        )
        .order('category')
        .order('name');

    _masterCache = List<Map<String, dynamic>>.from(
      rows,
    ).map((r) => MedicationMaster.fromMap(r)).toList();

    _byCategoryCache = {};
    for (final med in _masterCache!) {
      _byCategoryCache!.putIfAbsent(med.category, () => []).add(med);
    }

    return _masterCache!;
  }

  Future<List<String>> fetchCategories() async {
    await fetchMedicationMaster();
    return (_byCategoryCache?.keys.toList() ?? [])..sort();
  }

  Future<List<MedicationMaster>> searchMedications(String query) async {
    await fetchMedicationMaster();
    if (query.trim().isEmpty) return _masterCache ?? [];

    final q = query.toLowerCase().trim();
    return (_masterCache ?? [])
        .where(
          (m) =>
              m.name.toLowerCase().contains(q) ||
              (m.genericName?.toLowerCase().contains(q) ?? false) ||
              m.category.toLowerCase().contains(q) ||
              (m.subCategory?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  // Cari/buat obat di master jika belum ada (untuk input manual)
  Future<String> ensureMedicationExists({
    required String name,
    String category = 'Lainnya',
    String form = 'Tablet',
    String? strength,
    String? unit,
    String? description,
  }) async {
    // Cek apakah sudah ada (case-insensitive)
    final existing = await _db
        .from('medications')
        .select('id')
        .ilike('name', name.trim())
        .maybeSingle();

    if (existing != null) return existing['id'].toString();

    // Belum ada → insert baru
    final inserted = await _db
        .from('medications')
        .insert({
          'name': name.trim(),
          'category': category,
          'form': form,
          'strength': strength,
          'unit': unit ?? 'mg',
          'description': description,
        })
        .select('id')
        .single();

    // Invalidate cache
    _masterCache = null;
    _byCategoryCache = null;

    return inserted['id'].toString();
  }

  void clearCache() {
    _masterCache = null;
    _byCategoryCache = null;
  }

  // ════════════════════════════════════════════════════════════
  // USER MEDICATIONS (tabel: user_medications)
  // Obat rutin milik pasien — tidak perlu input ulang
  // ════════════════════════════════════════════════════════════

  Future<List<UserMedication>> fetchUserMedications(String userId) async {
    final rows = await _db
        .from('user_medications')
        .select('''
          id,
          user_id,
          medication_id,
          custom_name,
          dose,
          unit,
          note,
          frequency,
          is_active,
          created_at,
          medications (
            id,
            name,
            category,
            sub_category,
            strength,
            unit
          )
        ''')
        .eq('user_id', userId)
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(
      rows,
    ).map((r) => UserMedication.fromMap(r)).toList();
  }

  Future<UserMedication> saveUserMedication({
    required String userId,
    String? medicationId,
    String? customName,
    String? dose,
    String? unit,
    String? note,
    String frequency = '1x sehari',
  }) async {
    final payload = {
      'user_id': userId,
      'medication_id': medicationId,
      'custom_name': medicationId == null ? customName : null,
      'dose': dose ?? '',
      'unit': unit ?? 'mg',
      'note': note,
      'frequency': frequency,
      'is_active': true,
    };

    final inserted = await _db.from('user_medications').insert(payload).select(
      '''
          id, user_id, medication_id, custom_name,
          dose, unit, note, frequency, is_active, created_at,
          medications ( id, name, category, sub_category, strength, unit )
        ''',
    ).single();

    return UserMedication.fromMap(Map<String, dynamic>.from(inserted));
  }

  Future<void> deactivateUserMedication(String id) async {
    await _db
        .from('user_medications')
        .update({
          'is_active': false,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  // ════════════════════════════════════════════════════════════
  // MEDICATION REMINDERS (tabel: medication_reminders)
  // ════════════════════════════════════════════════════════════

  // Buat reminder dari obat rutin (1 klik dari "Obat Saya")
  Future<Map<String, dynamic>> createReminderFromUserMed({
    required String userId,
    required UserMedication userMed,
    required String time, // "HH:mm:00"
    required String period, // Pagi/Siang/Sore/Malam
  }) async {
    final payload = {
      'user_id': userId,
      'user_medication_id': userMed.id,
      'medication_id': userMed.medicationId,
      'name': userMed.medicationName,
      'dose': userMed.dose,
      'note': userMed.note ?? '',
      'time': time,
      'period': period,
      'taken': false,
      'is_active': true,
    };

    final inserted = await _db
        .from('medication_reminders')
        .insert(payload)
        .select()
        .single();

    return Map<String, dynamic>.from(inserted);
  }

  // Buat reminder manual (dari tab "Obat Baru")
  Future<Map<String, dynamic>> createReminderManual({
    required String userId,
    required String name,
    required String time,
    required String period,
    String? dose,
    String? unit,
    String? note,
    String? medicationId,
    bool saveAsUserMedication = true,
    String defaultCategory = 'Lainnya',
    String defaultForm = 'Tablet',
  }) async {
    // Auto-create atau find di medication master
    String? finalMedId = medicationId;
    if (finalMedId == null || finalMedId.isEmpty) {
      finalMedId = await ensureMedicationExists(
        name: name,
        category: defaultCategory,
        form: defaultForm,
        strength: dose,
        unit: unit,
      );
    }

    final reminder = await _db
        .from('medication_reminders')
        .insert({
          'user_id': userId,
          'medication_id': finalMedId,
          'name': name,
          'dose': dose ?? '',
          'note': note ?? '',
          'time': time,
          'period': period,
          'taken': false,
          'is_active': true,
        })
        .select()
        .single();

    if (saveAsUserMedication) {
      await saveUserMedication(
        userId: userId,
        medicationId: finalMedId,
        dose: dose,
        unit: unit,
        note: note,
      );
    }

    return Map<String, dynamic>.from(reminder);
  }

  Future<List<Map<String, dynamic>>> getReminders(String userId) async {
    final rows = await _db
        .from('medication_reminders')
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .order('time');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> markReminderTaken(dynamic id, bool taken) async {
    await _db
        .from('medication_reminders')
        .update({
          'taken': taken,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<void> deleteReminder(dynamic id) async {
    await _db.from('medication_reminders').delete().eq('id', id);
  }
}
