import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/login_screen.dart';
import '../../services/remote/doctor_service.dart';
import '../../services/remote/staff_presence_service.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  final _supabase = Supabase.instance.client;
  final _doctorService = DoctorService.instance;
  final _searchCtrl = TextEditingController();

  Map<String, dynamic>? _doctor;
  List<DoctorPatientSummary> _patients = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    _load();
    StaffPresenceService.instance.startHeartbeat();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    StaffPresenceService.instance.stopHeartbeat();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final doctor = await _doctorService.currentDoctor();
      final patients = await _doctorService.loadPatients();
      if (!mounted) return;
      setState(() {
        _doctor = doctor;
        _patients = patients;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Gagal memuat data pasien.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<DoctorPatientSummary> get _filtered {
    final q = _searchCtrl.text.toLowerCase().trim();
    if (q.isEmpty) return _patients;
    return _patients
        .where((p) => p.name.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _logout() async {
    await _supabase.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF060B1A) : const Color(0xFFF0F4FF),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF0D2B4E), const Color(0xFF060B1A)]
                    : [Colors.blue.shade700, Colors.indigo.shade500],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Dashboard Dokter',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                _doctor?['name']?.toString() ??
                                    'Selamat datang, Dokter',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              if (_doctor?['specialization'] != null)
                                Text(
                                  _doctor!['specialization'].toString(),
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded,
                              color: Colors.white),
                        ),
                        IconButton(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout_rounded,
                              color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          _StatChip(
                            icon: Icons.people_rounded,
                            label: 'Pasien',
                            value: '${_patients.length}',
                          ),
                          const SizedBox(width: 16),
                          _StatChip(
                            icon: Icons.local_hospital_rounded,
                            label: 'RS',
                            value: _doctor?['hospital_name']?.toString() ??
                                '—',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Cari pasien...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(Icons.search, color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text(_error!))
                : _filtered.isEmpty
                ? const Center(child: Text('Belum ada pasien terdaftar'))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final p = _filtered[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Text(
                                p.name.isNotEmpty
                                    ? p.name[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              p.name,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (p.phone != null && p.phone!.isNotEmpty)
                                  Text(p.phone!),
                                if (p.lastBp != null)
                                  Text(
                                    'TD terakhir: ${p.lastBp} mmHg'
                                    '${p.lastBpDate != null ? ' (${DateFormat('dd MMM', 'id_ID').format(p.lastBpDate!)})' : ''}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.teal.shade700,
                                    ),
                                  ),
                              ],
                            ),
                            isThreeLine: p.lastBp != null,
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
