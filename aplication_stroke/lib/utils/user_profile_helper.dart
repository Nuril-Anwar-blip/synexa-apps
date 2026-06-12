import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AppRole { admin, pharmacist, doctor, patient }

/// Resolves `users.id` / `pharmacists.id` from Supabase Auth `auth.users.id`.
class UserProfileHelper {
  UserProfileHelper._();

  static final _client = Supabase.instance.client;

  static AppRole _parseRole(String? raw) {
    switch (raw?.toLowerCase().trim()) {
      case 'admin':
        return AppRole.admin;
      case 'pharmacist':
        return AppRole.pharmacist;
      case 'doctor':
        return AppRole.doctor;
      default:
        return AppRole.patient;
    }
  }

  /// Tentukan peran login: RPC database dulu, lalu fallback query client.
  static Future<AppRole> resolveAppRole() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return AppRole.patient;

    try {
      final rpc = await _client.rpc('resolve_my_app_role');
      final role = _parseRole(rpc?.toString());
      if (role != AppRole.patient) return role;
    } catch (e) {
      debugPrint('UserProfileHelper: RPC resolve_my_app_role gagal — $e');
    }

    try {
      final admin = await _client
          .from('admins')
          .select('id')
          .eq('auth_id', uid)
          .maybeSingle();
      if (admin != null) return AppRole.admin;
    } catch (e) {
      debugPrint('UserProfileHelper: cek admin gagal — $e');
    }

    try {
      if (await pharmacistProfileId() != null) return AppRole.pharmacist;
    } catch (e) {
      debugPrint('UserProfileHelper: cek apoteker gagal — $e');
    }

    try {
      if (await doctorProfileId() != null) return AppRole.doctor;
    } catch (e) {
      debugPrint('UserProfileHelper: cek dokter gagal — $e');
    }

    return AppRole.patient;
  }

  static Future<String?> _staffProfileId(String table) async {
    final authId = _client.auth.currentUser?.id;
    if (authId == null) return null;

    try {
      var row = await _client
          .from(table)
          .select('id')
          .eq('auth_id', authId)
          .maybeSingle();
      if (row != null) return row['id']?.toString();
    } catch (e) {
      debugPrint('UserProfileHelper: lookup $table by auth_id gagal — $e');
    }

    final email = _client.auth.currentUser?.email?.trim().toLowerCase();
    if (email == null || email.isEmpty) return null;

    try {
      final rows = await _client
          .from(table)
          .select('id')
          .ilike('email', email)
          .limit(1);
      if (rows.isEmpty) return null;

      final row = rows.first;
      final id = row['id']?.toString();
      if (id == null) return null;

      try {
        await _client.from(table).update({'auth_id': authId}).eq('id', id);
      } catch (e) {
        debugPrint('UserProfileHelper: gagal link auth_id ke $table — $e');
      }
      return id;
    } catch (e) {
      debugPrint('UserProfileHelper: lookup $table by email gagal — $e');
      return null;
    }
  }

  static Future<String?> patientProfileId() async {
    final authId = _client.auth.currentUser?.id;
    if (authId == null) return null;
    final row = await _client
        .from('users')
        .select('id')
        .eq('auth_id', authId)
        .maybeSingle();
    return row?['id']?.toString();
  }

  static Future<String?> pharmacistProfileId() =>
      _staffProfileId('pharmacists');

  static Future<String?> doctorProfileId() => _staffProfileId('doctors');

  /// ID profil untuk chat: pasien / apoteker / dokter.
  static Future<({String id, String role})?> chatProfile() async {
    final pharmId = await pharmacistProfileId();
    if (pharmId != null) {
      return (id: pharmId, role: 'pharmacist');
    }
    final doctorId = await doctorProfileId();
    if (doctorId != null) {
      return (id: doctorId, role: 'doctor');
    }
    final patientId = await patientProfileId();
    if (patientId != null) {
      return (id: patientId, role: 'patient');
    }
    return null;
  }
}
