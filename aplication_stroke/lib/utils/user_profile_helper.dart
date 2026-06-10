import 'package:supabase_flutter/supabase_flutter.dart';

/// Resolves `users.id` / `pharmacists.id` from Supabase Auth `auth.users.id`.
class UserProfileHelper {
  UserProfileHelper._();

  static final _client = Supabase.instance.client;

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

  static Future<String?> pharmacistProfileId() async {
    final authId = _client.auth.currentUser?.id;
    if (authId == null) return null;
    final row = await _client
        .from('pharmacists')
        .select('id')
        .eq('auth_id', authId)
        .maybeSingle();
    return row?['id']?.toString();
  }

  static Future<String?> doctorProfileId() async {
    final authId = _client.auth.currentUser?.id;
    if (authId == null) return null;
    final row = await _client
        .from('doctors')
        .select('id')
        .eq('auth_id', authId)
        .maybeSingle();
    return row?['id']?.toString();
  }

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
