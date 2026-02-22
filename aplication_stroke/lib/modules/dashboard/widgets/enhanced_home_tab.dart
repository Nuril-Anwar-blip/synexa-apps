import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import Providers
import '../../../providers/language_provider.dart';

// Import Screens & Models
import '../../medication_reminder/medication_reminder_screen.dart';
import '../../medication_reminder/models/medication_reminder.dart';
import '../../consultation/patient_chat_dashboard_screen.dart';
import '../../education/stroke_education_screen.dart';
import '../../rehab/rehab_dashboard_screen.dart';
import '../../health/health_monitoring_screen.dart';
import '../../emergency_location/emergency_location_screen.dart';
import '../../exercise/exercise_screen.dart';

// Import Modular Components & Models
import '../models/dashboard_stats.dart';
import 'greeting_heart_rate_card.dart';
import 'quick_action_card.dart';
import 'feature_card.dart';
import 'stroke_education_card.dart';

/// Halaman EnhancedHomeTab
/// 
/// Merupakan tab Beranda utama yang menampilkan ringkasan data kesehatan,
/// pengingat obat, dan akses cepat ke fitur-fitur aplikasi lainnya.
class EnhancedHomeTab extends StatefulWidget {
  const EnhancedHomeTab({super.key});

  @override
  State<EnhancedHomeTab> createState() => _EnhancedHomeTabState();
}

class _EnhancedHomeTabState extends State<EnhancedHomeTab> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();

  late final StreamController<DashboardStats> _statsController;
  late final Stream<DashboardStats> _statsStream;
  late Stream<List<MedicationReminder>> _remindersStream;

  RealtimeChannel? _sensorChannel;
  String? _userId;

  String _userName = 'Integrated Stroke';
  String? _photoUrl;
  DashboardStats _currentStats = DashboardStats.empty();
  List<MedicationReminder> _reminders = [];

  final Map<String, bool> _exerciseCompletionStatus = {};

  @override
  void initState() {
    super.initState();
    _statsController = StreamController<DashboardStats>.broadcast();
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

  /// Mendengarkan perubahan data sensor secara realtime dari Supabase
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

  /// Mengambil profil pengguna (nama & foto)
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

  /// Mengambil data detak jantung terakhir dari database
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

  /// Mendengarkan stream pengingat obat
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

  /// Mengambil status penyelesaian latihan harian
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
        debugPrint('Error loading exercise status: $e');
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
    _currentStats = DashboardStats(
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
    
    // Pasangkan padding dengan tinggi navbar melayang (60px) + margin (20px)
    final bottomPadding = MediaQuery.of(context).padding.bottom + 80;

    return Consumer<LanguageProvider>(
      builder: (context, lang, _) {
        return ListView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
          children: [
            // Komponen Greeting & Heart Rate Realtime
            StreamBuilder<DashboardStats>(
              stream: _statsStream,
              builder: (context, snapshot) {
                final stats = snapshot.data ?? DashboardStats.empty();
                final bpm = _parseHeartRate(stats.heartRate);

                return GreetingWithHeartRate(
                  name: _userName,
                  photoUrl: _photoUrl,
                  heartRate: stats.heartRate,
                  status: _heartRateStatus(bpm, lang),
                  isDark: isDark,
                );
              },
            ),
            const SizedBox(height: 16),

            // Search Bar (Pencarian Fitur/Layanan)
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: lang.translate({
                  'id': 'Cari dokter, obat, atau kebutuhan...',
                  'en': 'Search for doctors, medicine, or needs...',
                  'ms': 'Cari doktor, ubat, atau keperluan...',
                }),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Section: Pengingat Obat (Checklist harian)
            if (_reminders.isNotEmpty) ...[
              _SectionHeader(title: lang.translate({
                'id': 'Pengingat Obat',
                'en': 'Medication Reminder',
                'ms': 'Peringatan Ubat',
              })),
              const SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: _reminders.map((reminder) => ListTile(
                    leading: Checkbox(
                      value: reminder.taken,
                      onChanged: (_) => _toggleMedication(reminder),
                    ),
                    title: Text(reminder.name, style: TextStyle(
                      decoration: reminder.taken ? TextDecoration.lineThrough : null,
                    )),
                    subtitle: Text(reminder.time.format(context)),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Komponen Edukasi Stroke
            _SectionHeader(title: lang.translate({
              'id': 'Edukasi Kesehatan',
              'en': 'Health Education',
              'ms': 'Pendidikan Kesihatan',
            })),
            const SizedBox(height: 8),
            StrokeEducationCard(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StrokeEducationScreen()),
              ),
            ),
            const SizedBox(height: 16),

            // Section: Tenaga Medis (Apoteker & Dokter)
            _buildHealthcareSection(lang),
            const SizedBox(height: 16),

            // Section: Akses Cepat
            _SectionHeader(title: lang.translate({
              'id': 'Layanan Utama',
              'en': 'Main Services',
              'ms': 'Perkhidmatan Utama',
            })),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: QuickActionCard(
                    icon: Icons.chat_bubble_rounded,
                    label: lang.translate({
                      'id': 'Chat Apoteker',
                      'en': 'Pharmacist Chat',
                      'ms': 'Sembang Ahli Farmasi',
                    }),
                    color: Colors.teal,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PatientChatDashboardScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: QuickActionCard(
                    icon: Icons.medication_liquid_rounded,
                    label: lang.translate({
                      'id': 'Pengingat Obat',
                      'en': 'Medicine Reminder',
                      'ms': 'Peringatan Ubat',
                    }),
                    color: Colors.indigo,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MedicationReminderScreen()),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Section: RS Terdekat (Emergency)
            _SectionHeader(title: lang.translate({
              'id': 'Bantuan Darurat',
              'en': 'Emergency Help',
              'ms': 'Bantuan Kecemasan',
            })),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmergencyLocationScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade400, Colors.red.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.translate({
                              'id': 'Lokasi RS Terdekat',
                              'en': 'Nearest Hospital',
                              'ms': 'Hospital Terdekat',
                            }),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lang.translate({
                              'id': 'Cari bantuan dalam radius 20km',
                              'en': 'Find help within 20km radius',
                              'ms': 'Cari bantuan dalam radius 20km',
                            }),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Section: Fitur Rehabilitasi & Latihan
            _SectionHeader(title: lang.translate({
              'id': 'Fitur Utama',
              'en': 'Main Features',
              'ms': 'Ciri Utama',
            })),
            const SizedBox(height: 12),
            GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                FeatureCard(
                  icon: Icons.fitness_center_rounded,
                  label: lang.translate({
                    'id': 'Latihan',
                    'en': 'Exercise',
                    'ms': 'Latihan',
                  }),
                  desc: lang.translate({
                    'id': 'Program fisik harian',
                    'en': 'Daily physical program',
                    'ms': 'Program fizikal harian',
                  }),
                  color: Colors.green,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ExerciseScreen()),
                  ),
                ),
                FeatureCard(
                  icon: Icons.health_and_safety_rounded,
                  label: lang.translate({
                    'id': 'Rehabilitasi',
                    'en': 'Rehabilitation',
                    'ms': 'Rehabilitasi',
                  }),
                  desc: lang.translate({
                    'id': 'Program kognitif',
                    'en': 'Cognitive program',
                    'ms': 'Program kognitif',
                  }),
                  color: Colors.purple,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RehabDashboardScreen()),
                  ),
                ),
                FeatureCard(
                  icon: Icons.monitor_heart_rounded,
                  label: lang.translate({
                    'id': 'Monitoring',
                    'en': 'Monitoring',
                    'ms': 'Pemantauan',
                  }),
                  desc: lang.translate({
                    'id': 'Tensi & Gula Darah',
                    'en': 'Pressure & Blood Sugar',
                    'ms': 'Tekanan & Gula Darah',
                  }),
                  color: Colors.blue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HealthMonitoringScreen()),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> _healthcareProviders = [];

  Future<void> _loadHealthcareProviders() async {
    try {
      final roles = ['apoteker', 'Apoteker', 'pharmacist', 'Pharmacist', 'dokter', 'Dokter', 'doctor', 'Doctor'];
      final response = await _supabase
          .from('users')
          .select('id, full_name, photo_url, role, phone_number')
          .filter('role', 'in', roles)
          .limit(3);

      if (mounted) {
        setState(() => _healthcareProviders = List<Map<String, dynamic>>.from(response));
      }
    } catch (e) {
      debugPrint('Error loading healthcare providers: $e');
    }
  }

  Widget _buildHealthcareSection(LanguageProvider lang) {
    if (_healthcareProviders.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SectionHeader(title: lang.translate({
              'id': 'Apoteker & Dokter',
              'en': 'Pharmacist & Doctor',
              'ms': 'Ahli Farmasi & Doktor',
            })),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PatientChatDashboardScreen()),
              ),
              child: Text(lang.translate({
                'id': 'Lihat Semua',
                'en': 'See All',
                'ms': 'Lihat Semua',
              })),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._healthcareProviders.map((provider) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(Icons.person, color: Colors.blue),
                ),
                title: Text(provider['full_name']?.toString() ?? 'Tenaga Medis', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(_getSpecialtyFromRole(provider['role']?.toString() ?? '', lang)),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () {},
              ),
            )),
      ],
    );
  }

  String _getSpecialtyFromRole(String role, LanguageProvider lang) {
    final lower = role.toLowerCase();
    if (lower.contains('apoteker') || lower.contains('pharmacist')) {
      return lang.translate({
        'id': 'Apoteker Klinis',
        'en': 'Clinical Pharmacist',
        'ms': 'Ahli Farmasi Klinikal',
      });
    }
    if (lower.contains('dokter') || lower.contains('doctor')) {
      return lang.translate({
        'id': 'Dokter Spesialis',
        'en': 'Specialist Doctor',
        'ms': 'Doktor Pakar',
      });
    }
    return role;
  }

  int? _parseHeartRate(String hrText) {
    final m = RegExp(r'(\d+)').firstMatch(hrText);
    return m != null ? int.tryParse(m.group(1) ?? '') : null;
  }

  String _heartRateStatus(int? bpm, LanguageProvider lang) {
    if (bpm == null) return lang.translate({'id': 'Belum ada data', 'en': 'No data', 'ms': 'Tiada data'});
    if (bpm < 60) return lang.translate({'id': 'Rendah', 'en': 'Low', 'ms': 'Rendah'});
    if (bpm <= 100) return lang.translate({'id': 'Normal', 'en': 'Normal', 'ms': 'Normal'});
    return lang.translate({'id': 'Tinggi', 'en': 'High', 'ms': 'Tinggi'});
  }
}

/// Widget internal untuk judul section agar konsisten
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}

