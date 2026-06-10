import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboardStats {
  final int patients;
  final int pharmacists;
  final int doctors;
  final int activeChats;
  final int reminders;
  final int pendingPharmacistInvites;
  final int pendingDoctorInvites;

  const AdminDashboardStats({
    required this.patients,
    required this.pharmacists,
    required this.doctors,
    required this.activeChats,
    required this.reminders,
    required this.pendingPharmacistInvites,
    required this.pendingDoctorInvites,
  });
}

class AdminService {
  AdminService({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  Future<bool> isCurrentUserAdmin() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return false;
    final row = await _supabase
        .from('admins')
        .select('id')
        .eq('auth_id', uid)
        .maybeSingle();
    return row != null;
  }

  Future<String?> currentAdminId() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return null;
    final row = await _supabase
        .from('admins')
        .select('id')
        .eq('auth_id', uid)
        .maybeSingle();
    return row?['id']?.toString();
  }

  Future<AdminDashboardStats> loadStats() async {
    final patients = await _countWhere('users', 'role', 'patient');
    final pharmacists = await _countAll('pharmacists');
    final doctors = await _countAllSafe('doctors');
    final chats = await _countAllSafe('chat_rooms');
    final reminders = await _countAllSafe('medication_reminders');
    final pharmInv = await _countWhere('pharmacist_invitations', 'is_used', false);
    final docInv = await _countWhereSafe('doctor_invitations', 'is_used', false);

    return AdminDashboardStats(
      patients: patients,
      pharmacists: pharmacists,
      doctors: doctors,
      activeChats: chats,
      reminders: reminders,
      pendingPharmacistInvites: pharmInv,
      pendingDoctorInvites: docInv,
    );
  }

  Future<int> _countAll(String table) async {
    try {
      final rows = await _supabase.from(table).select('id');
      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _countAllSafe(String table) async {
    try {
      final rows = await _supabase.from(table).select('id');
      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _countWhere(String table, String column, Object value) async {
    try {
      final rows = await _supabase.from(table).select('id').eq(column, value);
      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _countWhereSafe(String table, String column, Object value) async {
    try {
      final rows = await _supabase.from(table).select('id').eq(column, value);
      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _ensureAdmin() async {
    if (!await isCurrentUserAdmin()) {
      throw Exception(
        'Akun admin tidak terhubung. Pastikan auth_id admin sudah di-set di tabel admins.',
      );
    }
  }

  Future<List<Map<String, dynamic>>> listPatients() async {
    await _ensureAdmin();
    try {
      final rows = await _supabase
          .from('users')
          .select('id, name, email, phone, profile_picture, created_at')
          .eq('role', 'patient')
          .order('name');
      return _mapList(rows);
    } on PostgrestException catch (e) {
      throw Exception('Gagal memuat pasien: ${e.message}');
    }
  }

  Future<List<Map<String, dynamic>>> listPharmacists() async {
    final rows = await _supabase
        .from('pharmacists')
        .select(
          'id, name, email, phone, license_number, pharmacy_name, is_verified, created_at',
        )
        .order('name');
    return _mapList(rows);
  }

  Future<List<Map<String, dynamic>>> listDoctors() async {
    final rows = await _safeSelect(
      'doctors',
      'id, name, email, phone, license_number, specialization, hospital_name, is_verified, created_at',
    );
    rows.sort(
      (a, b) => (a['name']?.toString() ?? '').compareTo(
        b['name']?.toString() ?? '',
      ),
    );
    return rows;
  }

  Future<List<Map<String, dynamic>>> listPharmacistInvitations() async {
    await _ensureAdmin();
    try {
      final rows = await _supabase
          .from('pharmacist_invitations')
          .select(
            'id, token, email, name, license_number, pharmacy_name, is_used, created_at, expires_at',
          )
          .order('created_at', ascending: false);
      return _mapList(rows);
    } on PostgrestException catch (e) {
      if (e.code == '42703') {
        final rows = await _supabase
            .from('pharmacist_invitations')
            .select('id, token, email, is_used, created_at, expires_at')
            .order('created_at', ascending: false);
        return _mapList(rows);
      }
      throw Exception('Gagal memuat undangan apoteker: ${e.message}');
    }
  }

  Future<List<Map<String, dynamic>>> listDoctorInvitations() async {
    await _ensureAdmin();
    try {
      final rows = await _supabase
          .from('doctor_invitations')
          .select(
            'id, token, email, name, license_number, specialization, hospital_name, is_used, created_at, expires_at',
          )
          .order('created_at', ascending: false);
      return _mapList(rows);
    } on PostgrestException catch (e) {
      if (e.code == '42703') {
        final rows = await _supabase
            .from('doctor_invitations')
            .select('id, token, email, is_used, created_at, expires_at')
            .order('created_at', ascending: false);
        return _mapList(rows);
      }
      throw Exception('Gagal memuat undangan dokter: ${e.message}');
    }
  }

  Future<String> createPharmacistInvitation({
    required String name,
    required String email,
    String? phone,
    String? licenseNumber,
    String? pharmacyName,
  }) async {
    await _ensureAdmin();
    final adminId = await currentAdminId();
    if (adminId == null) {
      throw Exception('Akun admin tidak ditemukan.');
    }
    final token = _generateToken();
    try {
      await _supabase.from('pharmacist_invitations').insert({
        'token': token,
        'email': email.trim().toLowerCase(),
        'name': name.trim(),
        'license_number': licenseNumber?.trim(),
        'pharmacy_name': pharmacyName?.trim(),
        'created_by': adminId,
        'is_used': false,
      });
    } on PostgrestException catch (e) {
      if (e.code == '42703') {
        await _supabase.from('pharmacist_invitations').insert({
          'token': token,
          'email': email.trim().toLowerCase(),
          'created_by': adminId,
          'is_used': false,
        });
      } else {
        throw Exception('Gagal membuat undangan: ${e.message}');
      }
    }
    return token;
  }

  Future<String> createDoctorInvitation({
    required String name,
    required String email,
    String? phone,
    String? licenseNumber,
    String? specialization,
    String? hospitalName,
  }) async {
    await _ensureAdmin();
    final adminId = await currentAdminId();
    if (adminId == null) {
      throw Exception('Akun admin tidak ditemukan.');
    }
    final token = _generateToken();
    try {
      await _supabase.from('doctor_invitations').insert({
        'token': token,
        'email': email.trim().toLowerCase(),
        'name': name.trim(),
        'license_number': licenseNumber?.trim(),
        'specialization': specialization?.trim(),
        'hospital_name': hospitalName?.trim(),
        'created_by': adminId,
        'is_used': false,
      });
    } on PostgrestException catch (e) {
      if (e.code == '42703') {
        await _supabase.from('doctor_invitations').insert({
          'token': token,
          'email': email.trim().toLowerCase(),
          'created_by': adminId,
          'is_used': false,
        });
      } else {
        throw Exception('Gagal membuat undangan: ${e.message}');
      }
    }
    return token;
  }

  Future<void> revokePharmacistInvitation(String id) async {
    await _ensureAdmin();
    await _supabase
        .from('pharmacist_invitations')
        .update({'is_used': true})
        .eq('id', id);
  }

  Future<void> revokeDoctorInvitation(String id) async {
    await _ensureAdmin();
    await _supabase
        .from('doctor_invitations')
        .update({'is_used': true})
        .eq('id', id);
  }

  String _generateToken() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  List<Map<String, dynamic>> _mapList(dynamic rows) =>
      (rows as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();

  Future<List<Map<String, dynamic>>> _safeSelect(
    String table,
    String columns,
  ) async {
    try {
      final rows = await _supabase.from(table).select(columns);
      return _mapList(rows);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _safeSelectWhere(
    String table,
    String columns,
    String column,
    Object value,
  ) async {
    try {
      final rows = await _supabase
          .from(table)
          .select(columns)
          .eq(column, value);
      return _mapList(rows);
    } catch (_) {
      return [];
    }
  }
}
