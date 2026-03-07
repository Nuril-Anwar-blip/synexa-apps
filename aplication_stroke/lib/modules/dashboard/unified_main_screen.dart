import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// Import Providers
import '../../../providers/language_provider.dart';

// Import Custom Widgets
import '../../../widgets/base_screen.dart';
import '../../../widgets/app_bar_with_actions.dart';
import '../../../widgets/global_search_bar.dart';
import '../../../widgets/medication_checklist_card.dart';
import '../../../widgets/weekly_exercise_card.dart';
import '../../../widgets/healthcare_provider_card.dart';
import '../../../widgets/navbar.dart';

// Import Models & Sub-Screens
import '../medication_reminder/models/medication_reminder.dart';
import '../consultation/patient_chat_dashboard_screen.dart';
import '../medication_reminder/medication_reminder_screen.dart';
import '../exercise/exercise_screen.dart';
import '../community/community_screen.dart';
import '../profile/profile_screen.dart';
import 'widgets/greeting_heart_rate_card.dart';
import 'models/dashboard_stats.dart';

class UnifiedMainScreen extends StatefulWidget {
  const UnifiedMainScreen({super.key});

  @override
  State<UnifiedMainScreen> createState() => _UnifiedMainScreenState();
}

class _UnifiedMainScreenState extends State<UnifiedMainScreen> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();

  int _currentIndex = 0;
  String? _userId;
  String _userName = 'Integrated Stroke';
  String? _photoUrl;

  // Streams for real-time data
  late final StreamController<DashboardStats> _statsController;
  late final Stream<DashboardStats> _statsStream;
  late Stream<List<MedicationReminder>> _remindersStream;
  DashboardStats _currentStats = DashboardStats.empty();
  RealtimeChannel? _sensorChannel;

  List<MedicationReminder> _reminders = [];
  List<Map<String, dynamic>> _healthcareProviders = [];

  // Home Tab Content Scroll Controller
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _statsController = StreamController<DashboardStats>.broadcast();
    _statsStream = _statsController.stream;
    _initData();
  }

  Future<void> _initData() async {
    _userId = _supabase.auth.currentUser?.id;
    if (_userId == null) return;

    await _loadUserProfile();
    await _fetchLatestHeartRate();
    _listenRealtime();
    _loadReminders();
    _loadHealthcareProviders();
  }

  Future<void> _loadUserProfile() async {
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
    try {
      final response = await _supabase
          .from('sensor_data')
          .select('value')
          .eq('user_id', _userId!)
          .eq('type', 'heart_rate')
          .order('timestamp', ascending: false)
          .limit(1)
          .maybeSingle();

      final value = response?['value'] as Map<String, dynamic>?;
      final hr = value?['heart_rate'];
      if (hr != null) _updateStats(heartRate: '$hr bpm');
    } catch (_) {}
  }

  void _listenRealtime() {
    _sensorChannel = _supabase.channel('realtime_sensor_data_unified_$_userId')
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
          if (row['type'] == 'heart_rate' && row['value'] != null) {
            final value = row['value'] as Map<String, dynamic>;
            if (value['heart_rate'] != null) {
              _updateStats(heartRate: '${value['heart_rate']} bpm');
            }
          }
        },
      )
      ..subscribe();
  }

  Future<void> _loadReminders() async {
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
        if (mounted) setState(() => _reminders = reminders);
      });
    } catch (_) {}
  }

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
          .limit(3);

      if (mounted) {
        setState(
          () =>
              _healthcareProviders = List<Map<String, dynamic>>.from(response),
        );
      }
    } catch (e) {
      debugPrint('Error loading healthcare providers: $e');
    }
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

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _sensorChannel?.unsubscribe();
    if (_sensorChannel != null) _supabase.removeChannel(_sensorChannel!);
    _statsController.close();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: _currentIndex == 0
          ? const AppBarWithActions(
              title: 'Beranda Terpadu',
              showLanguageToggle: true,
            )
          : null,
      body: _buildCurrentTab(),
      bottomNavigationBar: CustomNavbar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        photoUrl: _photoUrl,
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return const CommunityScreen();
      case 2:
        return const PatientChatDashboardScreen();
      case 3:
        return const ProfileScreen();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return Consumer<LanguageProvider>(
      builder: (context, lang, _) {
        final bottomPad = MediaQuery.of(context).padding.bottom + 90;
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        // Dummy data for WeeklyExerciseCard demo
        final dummyExercises = {
          'monday': ExerciseDay(
            name: 'Latihan Peregangan',
            description: 'Peregangan sendi dasar',
            duration: 15,
            exercises: ['Tangan', 'Kaki'],
          ),
          'tuesday': ExerciseDay(
            name: 'Latihan Kognitif',
            description: 'Ingatan jangka pendek',
            duration: 10,
            exercises: ['Mengingat Benda'],
          ),
          'wednesday': ExerciseDay(
            name: 'Peregangan Punggung',
            description: 'Melenturkan punggung depan',
            duration: 20,
            exercises: ['Punggung'],
          ),
          'thursday': ExerciseDay(
            name: 'Latihan Peregangan',
            description: 'Peregangan sendi dasar',
            duration: 15,
            exercises: ['Tangan', 'Kaki'],
          ),
          'friday': ExerciseDay(
            name: 'Latihan Kognitif',
            description: 'Ingatan jangka pendek',
            duration: 10,
            exercises: ['Mengingat Benda'],
          ),
          'saturday': ExerciseDay(
            name: 'Istirahat Aktif',
            description: 'Jalan santai ringan',
            duration: 30,
            exercises: ['Jalan'],
          ),
          'sunday': ExerciseDay(
            name: 'Istirahat Total',
            description: 'Pemulihan tubuh',
            duration: 0,
            exercises: [],
          ),
        };

        return BaseScreen(
          useSafeArea: false,
          horizontalPadding: 0,
          body: ListView(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad),
            children: [
              // 1. Greeting & Hero / Sensor Data
              StreamBuilder<DashboardStats>(
                stream: _statsStream,
                builder: (context, snapshot) {
                  final stats = snapshot.data ?? DashboardStats.empty();
                  final bpmStr = stats.heartRate?.replaceAll(
                    RegExp(r'[^0-9]'),
                    '',
                  );
                  final bpm = int.tryParse(bpmStr ?? '');

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

              // 2. Global Search
              GlobalSearchBar(controller: _searchController),
              const SizedBox(height: 16),

              // 3. Medication Checklist
              if (_reminders.isNotEmpty) ...[
                Text(
                  lang.translate({
                    'id': 'Obat Anda',
                    'en': 'Your Medications',
                    'ms': 'Ubat Anda',
                  }),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                MedicationChecklistCard(
                  reminders: _reminders,
                  onToggle: _toggleMedication,
                ),
                const SizedBox(height: 16),
              ],

              // 4. Weekly Exercise Tracker
              Text(
                lang.translate({
                  'id': 'Program Pemulihan',
                  'en': 'Recovery Program',
                  'ms': 'Program Pemulihan',
                }),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              WeeklyExerciseCard(
                exercises: dummyExercises,
                onTap: (dayKey, exercise) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ExerciseScreen()),
                  );
                },
                onToggleComplete: (day, completed) {
                  // Handle save status
                },
              ),
              const SizedBox(height: 16),

              // 5. Healthcare Providers
              if (_healthcareProviders.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      lang.translate({
                        'id': 'Tenaga Medis',
                        'en': 'Medical Staff',
                        'ms': 'Kakitangan Perubatan',
                      }),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                      child: Text(
                        lang.translate({
                          'id': 'Lihat Semua',
                          'en': 'See All',
                          'ms': 'Lihat Semua',
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._healthcareProviders.map((provider) {
                  String specialty = provider['role']?.toString() ?? '';
                  if (specialty.toLowerCase() == 'apoteker')
                    specialty = 'Apoteker Klinis';
                  if (specialty.toLowerCase() == 'dokter')
                    specialty = 'Dokter Spesialis';

                  return HealthcareProviderCard(
                    name: provider['full_name']?.toString() ?? 'Tenaga Medis',
                    specialty: specialty,
                    photoUrl: provider['photo_url']?.toString(),
                    rating: 4.8,
                    reviewCount: 12,
                    availability: 'Tersedia: 08:00 - 16:00',
                    onMessage: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PatientChatDashboardScreen(),
                        ),
                      );
                    },
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  String _heartRateStatus(int? bpm, LanguageProvider lang) {
    if (bpm == null)
      return lang.translate({
        'id': 'Belum ada data',
        'en': 'No data',
        'ms': 'Tiada data',
      });
    if (bpm < 60)
      return lang.translate({'id': 'Rendah', 'en': 'Low', 'ms': 'Rendah'});
    if (bpm <= 100)
      return lang.translate({'id': 'Normal', 'en': 'Normal', 'ms': 'Normal'});
    return lang.translate({'id': 'Tinggi', 'en': 'High', 'ms': 'Tinggi'});
  }
}
