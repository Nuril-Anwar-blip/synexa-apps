import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../medication_reminder/medication_reminder_screen.dart';
import '../../medication_reminder/models/medication_reminder.dart';
import '../../consultation/patient_chat_dashboard_screen.dart';
import '../../exercise/exercise_screen.dart';
import '../../education/stroke_education_screen.dart';
// New imports for Rehab & Health
import '../../rehab/rehab_dashboard_screen.dart';
import '../../health/health_monitoring_screen.dart';

class EnhancedHomeTab extends StatefulWidget {
  const EnhancedHomeTab({super.key});

  @override
  State<EnhancedHomeTab> createState() => _EnhancedHomeTabState();
}

class _EnhancedHomeTabState extends State<EnhancedHomeTab> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();

  late final StreamController<_DashboardStats> _statsController;
  late final Stream<_DashboardStats> _statsStream;
  late final Stream<List<MedicationReminder>> _remindersStream;

  RealtimeChannel? _sensorChannel;
  String? _userId;

  String _userName = 'Integrated Stroke';
  String? _photoUrl;
  _DashboardStats _currentStats = _DashboardStats.empty();
  List<MedicationReminder> _reminders = [];

  Map<String, bool> _exerciseCompletionStatus = {};

  @override
  void initState() {
    super.initState();
    _statsController = StreamController<_DashboardStats>.broadcast();
    _statsStream = _statsController.stream;
    _init();
  }

  Future<void> _init() async {
    _userId = _supabase.auth.currentUser?.id;
    if (_userId == null) return;

    await _loadUserProfile();
    await _fetchLatestHeartRate();
    _listenRealtime();
    _loadReminders();
    _loadHealthcareProviders();
    _loadExerciseCompletionStatus();
  }

  void _listenRealtime() {
    if (_userId == null) return;

    _sensorChannel = _supabase.channel('realtime_sensor_data_$_userId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'sensor_data',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: _userId!,
        ),
        callback: (payload) async {
          final row = payload.newRecord;
          if (row['heart_rate'] != null) {
            _updateStats(heartRate: '${row['heart_rate']} bpm');
          }
        },
      )
      ..subscribe();
  }

  Future<void> _loadUserProfile() async {
    if (_userId == null) return;

    try {
      final data = await _supabase
          .from('users')
          .select('full_name, photo_url')
          .eq('id', _userId!)
          .maybeSingle();

      if (!mounted || data == null) return;

      setState(() {
        final name = data['full_name']?.toString() ?? '';
        _userName = name.isNotEmpty ? name : 'Integrated Stroke';
        _photoUrl = data['photo_url']?.toString();
      });
    } catch (_) {}
  }

  Future<void> _fetchLatestHeartRate() async {
    if (_userId == null) return;

    try {
      final response = await _supabase
          .from('sensor_data')
          .select('heart_rate')
          .eq('user_id', _userId!)
          .order('timestamp', ascending: false)
          .limit(1)
          .maybeSingle();

      final hr = response?['heart_rate'];
      if (hr != null) _updateStats(heartRate: '$hr bpm');
    } catch (_) {}
  }

  Future<void> _loadReminders() async {
    if (_userId == null) return;

    try {
      _remindersStream = _supabase
          .from('medication_reminders')
          .stream(primaryKey: ['id'])
          .eq('user_id', _userId!)
          .order('time', ascending: true)
          .map(
            (rows) =>
                rows.map((row) => MedicationReminder.fromMap(row)).toList(),
          );

      _remindersStream.listen((reminders) {
        if (mounted) {
          setState(() => _reminders = reminders);
        }
      });
    } catch (_) {}
  }

  Future<void> _loadExerciseCompletionStatus() async {
    if (_userId == null) return;
    try {
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final todayKey = _getDayKey(DateFormat('EEEE', 'id_ID').format(today));

      final response = await _supabase
          .from('exercise_progress')
          .select('day, completed')
          .eq('user_id', _userId!)
          .eq('date', dateStr)
          .eq('day', todayKey)
          .maybeSingle();

      if (mounted && response != null) {
        setState(() {
          _exerciseCompletionStatus[todayKey] = response['completed'] ?? false;
        });
      }
    } catch (e) {
      if (mounted) {
        print('Error loading exercise status: $e');
      }
    }
  }

  String _getDayKey(String day) {
    final dayMap = {
      'Senin': 'monday',
      'Selasa': 'tuesday',
      'Rabu': 'wednesday',
      'Kamis': 'thursday',
      'Jumat': 'friday',
      'Sabtu': 'saturday',
      'Minggu': 'sunday',
    };
    return dayMap[day] ?? day.toLowerCase();
  }

  void _updateStats({String? heartRate}) {
    _currentStats = _DashboardStats(
      heartRate: heartRate ?? _currentStats.heartRate,
    );
    _statsController.add(_currentStats);
  }

  Future<void> _toggleMedication(MedicationReminder reminder) async {
    try {
      await _supabase
          .from('medication_reminders')
          .update({'taken': !reminder.taken})
          .eq('id', reminder.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memperbarui: $e')));
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _sensorChannel?.unsubscribe();
    if (_sensorChannel != null) _supabase.removeChannel(_sensorChannel!);
    _statsController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Padding untuk floating navbar (70 height + 16 margin + safe area)
    final bottom = MediaQuery.of(context).padding.bottom + 86;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 14, 16, bottom),
      children: [
        // Greeting dengan Heart Rate
        StreamBuilder<_DashboardStats>(
          stream: _statsStream,
          builder: (context, snapshot) {
            final stats = snapshot.data ?? _DashboardStats.empty();
            final bpm = _parseHeartRate(stats.heartRate);

            return _GreetingWithHeartRate(
              name: _userName,
              photoUrl: _photoUrl,
              heartRate: stats.heartRate,
              status: _heartRateStatus(bpm),
              isDark: isDark,
            );
          },
        ),
        const SizedBox(height: 16),

        // Search Bar
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Cari dokter, obat, atau kebutuhan...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 16),

        // Medication Checklist
        if (_reminders.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pengingat Obat',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._reminders.map(
                    (reminder) => CheckboxListTile(
                      title: Text(reminder.name),
                      value: reminder.taken,
                      onChanged: (value) => _toggleMedication(reminder),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Weekly Exercise (Hanya hari ini)
        Card(
          child: ListTile(
            title: const Text('Latihan Mingguan'),
            subtitle: const Text('Latihan untuk hari ini'),
            trailing: const Icon(Icons.fitness_center),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExerciseScreen()),
              );
            },
          ),
        ),

        // Healthcare Providers
        _buildHealthcareProvidersSection(),

        const SizedBox(height: 16),

        // Stroke Education
        _buildStrokeEducationCard(),

        const SizedBox(height: 16),

        // Quick Actions
        _buildQuickActions(),

        const SizedBox(height: 16),

        // Main Features
        _buildMainFeatures(),
      ],
    );
  }

  List<Map<String, dynamic>> _healthcareProviders = [];

  Future<void> _loadHealthcareProviders() async {
    try {
      final roles = [
        'apoteker',
        'Apoteker',
        'pharmacist',
        'Pharmacist',
        'dokter',
        'Dokter',
        'doctor',
        'Doctor',
      ];
      final response = await _supabase
          .from('users')
          .select('id, full_name, photo_url, role, phone_number')
          .filter('role', 'in', roles)
          .limit(5);

      if (mounted) {
        setState(() {
          _healthcareProviders = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      if (mounted) {
        print('Error loading healthcare providers: $e');
      }
    }
  }

  Widget _buildHealthcareProvidersSection() {
    if (_healthcareProviders.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Apoteker & Dokter Terdekat',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PatientChatDashboardScreen(),
                  ),
                );
              },
              child: const Text('Lihat Semua'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._healthcareProviders.map((provider) {
          return Card(
            child: ListTile(
              title: Text(
                provider['full_name']?.toString() ?? 'Tidak ada nama',
              ),
              subtitle: Text(
                _getSpecialtyFromRole(provider['role']?.toString() ?? ''),
              ),
              leading: const Icon(Icons.person),
              onTap: () {
                // Navigate to provider detail
              },
            ),
          );
        }),
      ],
    );
  }

  String _getSpecialtyFromRole(String role) {
    final roleLower = role.toLowerCase();
    if (roleLower.contains('apoteker') || roleLower.contains('pharmacist')) {
      return 'Apoteker Klinis';
    } else if (roleLower.contains('dokter') || roleLower.contains('doctor')) {
      return 'Dokter Spesialis';
    }
    return role;
  }

  Widget _buildStrokeEducationCard() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StrokeEducationScreen()),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade400, Colors.red.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.health_and_safety_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edukasi Stroke',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pelajari tentang stroke, pencegahan, dan penanganan',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Akses Cepat',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.chat_bubble_rounded,
                label: 'Chat Apoteker',
                color: Colors.teal,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PatientChatDashboardScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.medication_liquid_rounded,
                label: 'Pengingat Obat',
                color: Colors.indigo,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MedicationReminderScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fitur Utama',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            _FeatureCard(
              icon: Icons.fitness_center_rounded,
              label: 'Rehabilitasi',
              desc: 'Program harian Anda',
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RehabDashboardScreen()),
                );
              },
            ),
            _FeatureCard(
              icon: Icons.monitor_heart_rounded,
              label: 'Monitoring',
              desc: 'Tensi & Gula Darah',
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HealthMonitoringScreen()),
                );
              },
            ),
            _FeatureCard(
              icon: Icons.groups_rounded,
              label: 'Komunitas',
              desc: 'Diskusi & dukungan',
              color: Colors.deepOrange,
              onTap: () {
                // Navigate to community
              },
            ),
          ],
        ),
      ],
    );
  }

  int? _parseHeartRate(String hrText) {
    final m = RegExp(r'(\d+)').firstMatch(hrText);
    if (m == null) return null;
    return int.tryParse(m.group(1) ?? '');
  }

  String _heartRateStatus(int? bpm) {
    if (bpm == null) return 'Belum ada data';
    if (bpm < 60) return 'Rendah';
    if (bpm <= 100) return 'Normal';
    return 'Tinggi';
  }
}

class _DashboardStats {
  final String heartRate;
  const _DashboardStats({required this.heartRate});
  factory _DashboardStats.empty() => const _DashboardStats(heartRate: '—');
}

class _GreetingWithHeartRate extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final String heartRate;
  final String status;
  final bool isDark;

  const _GreetingWithHeartRate({
    required this.name,
    required this.photoUrl,
    required this.heartRate,
    required this.status,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withOpacity(0.9),
            Colors.teal.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withOpacity(0.9),
            backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                ? NetworkImage(photoUrl!)
                : null,
            child: (photoUrl == null || photoUrl!.isEmpty)
                ? Icon(Icons.person, color: theme.primaryColor, size: 28)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, $name',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Apa yang Anda rasakan hari ini?',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.monitor_heart,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      heartRate,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String desc;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.label,
    required this.desc,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.9), color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

