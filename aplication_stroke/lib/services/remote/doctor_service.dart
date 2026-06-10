import 'package:supabase_flutter/supabase_flutter.dart';

class DoctorPatientSummary {
  const DoctorPatientSummary({
    required this.id,
    required this.name,
    this.phone,
    this.profilePicture,
    this.lastBp,
    this.lastBpDate,
  });

  final String id;
  final String name;
  final String? phone;
  final String? profilePicture;
  final String? lastBp;
  final DateTime? lastBpDate;
}

class DoctorService {
  DoctorService._();
  static final instance = DoctorService._();

  final _client = Supabase.instance.client;

  Future<Map<String, dynamic>?> currentDoctor() async {
    final authId = _client.auth.currentUser?.id;
    if (authId == null) return null;
    final row = await _client
        .from('doctors')
        .select('id, name, specialization, hospital_name, profile_picture')
        .eq('auth_id', authId)
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row as Map);
  }

  Future<List<DoctorPatientSummary>> loadPatients() async {
    final patients = await _client
        .from('users')
        .select('id, name, phone, profile_picture')
        .eq('role', 'patient')
        .order('name');

    final summaries = <DoctorPatientSummary>[];
    for (final raw in patients as List) {
      final p = Map<String, dynamic>.from(raw as Map);
      final id = p['id']?.toString() ?? '';
      String? lastBp;
      DateTime? lastBpDate;
      try {
        final log = await _client
            .from('health_logs')
            .select('systolic_bp, diastolic_bp, log_date')
            .eq('user_id', id)
            .not('systolic_bp', 'is', null)
            .order('log_date', ascending: false)
            .limit(1)
            .maybeSingle();
        if (log != null) {
          lastBp = '${log['systolic_bp']}/${log['diastolic_bp']}';
          lastBpDate = DateTime.tryParse(log['log_date']?.toString() ?? '');
        }
      } catch (_) {}
      summaries.add(
        DoctorPatientSummary(
          id: id,
          name: p['name']?.toString() ?? 'Pasien',
          phone: p['phone']?.toString(),
          profilePicture: p['profile_picture']?.toString(),
          lastBp: lastBp,
          lastBpDate: lastBpDate,
        ),
      );
    }
    return summaries;
  }

  Future<int> patientCount() async {
    final rows = await _client
        .from('users')
        .select('id')
        .eq('role', 'patient');
    return (rows as List).length;
  }
}
