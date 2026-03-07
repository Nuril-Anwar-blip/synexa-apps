/// ====================================================================
/// File: enhanced_home_tab.dart
/// --------------------------------------------------------------------
/// Tab Home yang Ditingkatkan (Enhanced Home Dashboard)
/// 
/// Dokumen ini berisi layar dashboard utama aplikasi yang menampilkan:
/// 
/// 1. Hero Header:
///    - Ucapan salam berdasarkan waktu (Pagi/Siang/Malam)
///    - Nama pengguna
///    - Tombol quick settings
/// 
/// 2. Quick Stats:
///    - Detak jantung terakhir (dari sensor realtime)
///    - Progress exercise harian
/// 
/// 3. Search Bar:
///    - Pencarian global untuk fitur/artikel
/// 
/// 4. Quick Actions:
///    - Akses cepat ke fitur utama (Medicines, Rehab, dll)
/// 
/// 5. Medication Reminders:
///    - Daftar obat yang perlu diminum
/// 
/// 6. Feature Grid:
///    - Grid ikon untuk semua fitur aplikasi
/// 
/// 7. Healthcare Providers:
///    - Daftar apoteker/dokter yang tersedia
/// 
/// 8. Emergency Section:
///    - Tombol panggilan darurat
/// 
/// Fitur Realtime:
/// - Mendengarkan data sensor (heart rate) dari Supabase Realtime
/// - Update otomatis saat ada data baru
/// 
/// Author: Tim Developer Synexa
/// ====================================================================

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
import '../../../models/emergency_contact_model.dart';
import '../../../widgets/quick_settings_sheet.dart';
import '../models/dashboard_stats.dart';

/// EnhancedHomeTab — Modern & Interactive Home Dashboard
class EnhancedHomeTab extends StatefulWidget {
  const EnhancedHomeTab({super.key});

  @override
  State<EnhancedHomeTab> createState() => _EnhancedHomeTabState();
}

class _EnhancedHomeTabState extends State<EnhancedHomeTab>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();

  late final StreamController<DashboardStats> _statsController;
  late final Stream<DashboardStats> _statsStream;
  late Stream<List<MedicationReminder>> _remindersStream;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  RealtimeChannel? _sensorChannel;
  String? _userId;

  String _userName = 'Integrated Stroke';
  String? _photoUrl;
  DashboardStats _currentStats = DashboardStats.empty();
  List<MedicationReminder> _reminders = [];
  List<EmergencyContactModel> _emergencyContacts = [];
  List<Map<String, dynamic>> _healthcareProviders = [];

  final Map<String, bool> _exerciseCompletionStatus = {};

  @override
  void initState() {
    super.initState();
    _statsController = StreamController<DashboardStats>.broadcast();
    _statsStream = _statsController.stream;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
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

  Future<void> _loadUserProfile() async {
    if (_userId == null) return;
    try {
      final data = await _supabase
          .from('users')
          .select('full_name, photo_url, emergency_contact')
          .eq('id', _userId!)
          .maybeSingle();

      if (!mounted || data == null) return;
      setState(() {
        final name = data['full_name']?.toString() ?? '';
        _userName = name.isNotEmpty ? name : 'Integrated Stroke';
        _photoUrl = data['photo_url']?.toString();
        if (data['emergency_contact'] != null &&
            data['emergency_contact'] is List) {
          _emergencyContacts = (data['emergency_contact'] as List)
              .map(
                (e) => EmergencyContactModel.fromMap(e as Map<String, dynamic>),
              )
              .toList();
        }
      });
    } catch (_) {}
  }

  Future<void> _fetchLatestHeartRate() async {
    if (_userId == null) return;
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
        if (mounted) setState(() => _reminders = reminders);
      });
    } catch (_) {}
  }

  Future<void> _loadExerciseCompletionStatus() async {
    if (_userId == null) return;
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).toUtc();
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final todayKey = DateFormat('EEEE', 'id_ID').format(now).toLowerCase();

      final response = await _supabase
          .from('rehab_exercise_logs')
          .select('id')
          .eq('user_id', _userId!)
          .eq('is_aborted', false)
          .gte('completed_at', startOfDay.toIso8601String())
          .lt('completed_at', endOfDay.toIso8601String())
          .maybeSingle();

      if (mounted) {
        setState(() => _exerciseCompletionStatus[todayKey] = response != null);
      }
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
    } catch (_) {}
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
    _pulseController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom + 80;

    return Consumer<LanguageProvider>(
      builder: (context, lang, _) {
        return CustomScrollView(
          slivers: [
            // ── Hero Header ──
            SliverToBoxAdapter(child: _buildHeroHeader(isDark, lang)),

            // ── Quick Stats Row ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: _buildQuickStats(isDark, lang),
              ),
            ),

            // ── Search Bar ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _buildSearchBar(isDark, lang),
              ),
            ),

            // ── Quick Actions Row ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildQuickActions(lang, isDark),
              ),
            ),

            // ── Medication Reminders ──
            if (_reminders.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _buildMedicationSection(lang, isDark),
                ),
              ),

            // ── Feature Grid ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildFeatureGrid(lang, isDark),
              ),
            ),

            // ── Healthcare Providers ──
            if (_healthcareProviders.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _buildHealthcareSection(lang, isDark),
                ),
              ),

            // ── Emergency Buttons ──
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
                child: _buildEmergencySection(lang),
              ),
            ),
          ],
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HERO HEADER
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildHeroHeader(bool isDark, LanguageProvider lang) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? lang.translate({
            'id': 'Selamat Pagi',
            'en': 'Good Morning',
            'ms': 'Selamat Pagi',
          })
        : hour < 17
        ? lang.translate({
            'id': 'Selamat Siang',
            'en': 'Good Afternoon',
            'ms': 'Selamat Petang',
          })
        : lang.translate({
            'id': 'Selamat Malam',
            'en': 'Good Evening',
            'ms': 'Selamat Malam',
          });

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0D47A1), const Color(0xFF006064)]
              : [Colors.teal.shade600, Colors.teal.shade300],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _firstName(_userName),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Quick settings button
                  GestureDetector(
                    onTap: () => QuickSettingsSheet.show(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundImage: _photoUrl != null
                          ? NetworkImage(_photoUrl!)
                          : null,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      child: _photoUrl == null
                          ? const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 24,
                            )
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Heart Rate card inside hero
              StreamBuilder<DashboardStats>(
                stream: _statsStream,
                builder: (context, snapshot) {
                  final stats = snapshot.data ?? DashboardStats.empty();
                  final bpm = _parseHeartRate(stats.heartRate);
                  final hasData = bpm != null;
                  final status = _heartRateStatus(
                    bpm,
                    context.read<LanguageProvider>(),
                  );

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.favorite_rounded,
                              color: hasData
                                  ? Colors.redAccent.shade100
                                  : Colors.white54,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang.translate({
                                  'id': 'Detak Jantung',
                                  'en': 'Heart Rate',
                                  'ms': 'Kadar Jantung',
                                }),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    hasData ? '$bpm' : '--',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 3),
                                    child: Text(
                                      hasData ? 'bpm' : '',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(bpm).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _statusColor(bpm).withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: _statusColor(bpm),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // QUICK STATS
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildQuickStats(bool isDark, LanguageProvider lang) {
    final today = DateTime.now();
    final daysDone = _exerciseCompletionStatus.values.where((v) => v).length;
    final medicsTaken = _reminders.where((r) => r.taken).length;

    return Transform.translate(
      offset: const Offset(0, -16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              icon: Icons.fitness_center_rounded,
              color: Colors.green,
              value: '$daysDone',
              label: lang.translate({
                'id': 'Latihan',
                'en': 'Exercises',
                'ms': 'Latihan',
              }),
              isDark: isDark,
            ),
            _VerticalDivider(isDark: isDark),
            _StatItem(
              icon: Icons.medication_rounded,
              color: Colors.blue,
              value: '$medicsTaken/${_reminders.length}',
              label: lang.translate({
                'id': 'Obat',
                'en': 'Medicine',
                'ms': 'Ubat',
              }),
              isDark: isDark,
            ),
            _VerticalDivider(isDark: isDark),
            _StatItem(
              icon: Icons.calendar_today_rounded,
              color: Colors.orange,
              value: DateFormat('dd MMM').format(today),
              label: lang.translate({
                'id': 'Hari Ini',
                'en': 'Today',
                'ms': 'Hari Ini',
              }),
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SEARCH BAR
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildSearchBar(bool isDark, LanguageProvider lang) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: lang.translate({
            'id': '🔍  Cari fitur, obat, atau layanan...',
            'en': '🔍  Search features, medicine, or services...',
            'ms': '🔍  Cari ciri, ubat, atau perkhidmatan...',
          }),
          hintStyle: TextStyle(
            color: isDark ? Colors.white30 : Colors.black38,
            fontSize: 13.5,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // QUICK ACTIONS
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildQuickActions(LanguageProvider lang, bool isDark) {
    final actions = [
      _ActionData(
        icon: Icons.chat_bubble_rounded,
        label: lang.translate({
          'id': 'Konsultasi',
          'en': 'Consult',
          'ms': 'Konsultasi',
        }),
        gradient: [Colors.teal.shade400, Colors.cyan.shade600],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PatientChatDashboardScreen()),
        ),
      ),
      _ActionData(
        icon: Icons.medication_liquid_rounded,
        label: lang.translate({'id': 'Obat', 'en': 'Medicine', 'ms': 'Ubat'}),
        gradient: [Colors.indigo.shade400, Colors.blue.shade600],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MedicationReminderScreen()),
        ),
      ),
      _ActionData(
        icon: Icons.fitness_center_rounded,
        label: lang.translate({
          'id': 'Latihan',
          'en': 'Exercise',
          'ms': 'Latihan',
        }),
        gradient: [Colors.green.shade400, Colors.teal.shade600],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ExerciseScreen()),
        ),
      ),
      _ActionData(
        icon: Icons.monitor_heart_rounded,
        label: lang.translate({
          'id': 'Monitor',
          'en': 'Monitor',
          'ms': 'Pantau',
        }),
        gradient: [Colors.purple.shade400, Colors.indigo.shade600],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HealthMonitoringScreen()),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: lang.translate({
            'id': 'Akses Cepat',
            'en': 'Quick Access',
            'ms': 'Akses Pantas',
          }),
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        Row(
          children: actions
              .map(
                (a) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: a.onTap,
                      child: Column(
                        children: [
                          AspectRatio(
                            aspectRatio: 1.0,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: a.gradient,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: a.gradient.first.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                a.icon,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            a.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // MEDICATION REMINDERS
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildMedicationSection(LanguageProvider lang, bool isDark) {
    final todayReminders = _reminders.take(3).toList();
    final doneCount = _reminders.where((r) => r.taken).length;
    final progress = _reminders.isEmpty ? 0.0 : doneCount / _reminders.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SectionHeader(
              title: lang.translate({
                'id': 'Pengingat Obat',
                'en': 'Medication',
                'ms': 'Ubat',
              }),
              isDark: isDark,
            ),
            TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MedicationReminderScreen(),
                ),
              ),
              icon: const Icon(Icons.arrow_forward_ios, size: 12),
              label: Text(
                lang.translate({'id': 'Semua', 'en': 'All', 'ms': 'Semua'}),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Progress bar
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: isDark
                            ? Colors.white12
                            : Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(
                          progress == 1 ? Colors.green : Colors.indigo,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$doneCount/${_reminders.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Medication items
              ...todayReminders.map(
                (reminder) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => _toggleMedication(reminder),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: reminder.taken
                            ? Colors.green.withValues(alpha: 0.1)
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.grey.shade50),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: reminder.taken
                              ? Colors.green.withValues(alpha: 0.4)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: reminder.taken
                                  ? Colors.green.withValues(alpha: 0.15)
                                  : Colors.indigo.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              reminder.taken
                                  ? Icons.check_circle_rounded
                                  : Icons.medication_rounded,
                              size: 18,
                              color: reminder.taken
                                  ? Colors.green
                                  : Colors.indigo,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reminder.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    decoration: reminder.taken
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                Text(
                                  reminder.time.format(context),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.black38,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (reminder.taken)
                            Text(
                              lang.translate({
                                'id': 'Sudah',
                                'en': 'Done',
                                'ms': 'Selesai',
                              }),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // FEATURE GRID
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildFeatureGrid(LanguageProvider lang, bool isDark) {
    final features = [
      _FeatureData(
        icon: Icons.fitness_center_rounded,
        label: lang.translate({
          'id': 'Latihan Fisik',
          'en': 'Exercise',
          'ms': 'Latihan Fizikal',
        }),
        desc: lang.translate({
          'id': 'Program harian',
          'en': 'Daily program',
          'ms': 'Program harian',
        }),
        gradient: [Colors.green.shade400, Colors.teal.shade600],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ExerciseScreen()),
        ),
        completed: _exerciseCompletionStatus.values.any((v) => v),
      ),
      _FeatureData(
        icon: Icons.health_and_safety_rounded,
        label: lang.translate({
          'id': 'Rehabilitasi',
          'en': 'Rehab',
          'ms': 'Pemulihan',
        }),
        desc: lang.translate({
          'id': 'Kognitif & motorik',
          'en': 'Cognitive & motor',
          'ms': 'Kognitif & motor',
        }),
        gradient: [Colors.purple.shade400, Colors.indigo.shade600],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RehabDashboardScreen()),
        ),
        completed: false,
      ),
      _FeatureData(
        icon: Icons.monitor_heart_rounded,
        label: lang.translate({
          'id': 'Monitoring',
          'en': 'Monitoring',
          'ms': 'Pemantauan',
        }),
        desc: lang.translate({
          'id': 'Tensi & gula darah',
          'en': 'BP & blood sugar',
          'ms': 'TD & gula darah',
        }),
        gradient: [Colors.blue.shade400, Colors.cyan.shade600],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HealthMonitoringScreen()),
        ),
        completed: false,
      ),
      _FeatureData(
        icon: Icons.book_rounded,
        label: lang.translate({
          'id': 'Edukasi',
          'en': 'Education',
          'ms': 'Pendidikan',
        }),
        desc: lang.translate({
          'id': 'Tentang stroke',
          'en': 'About stroke',
          'ms': 'Tentang strok',
        }),
        gradient: [Colors.orange.shade400, Colors.red.shade400],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StrokeEducationScreen()),
        ),
        completed: false,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: lang.translate({
            'id': 'Fitur Utama',
            'en': 'Main Features',
            'ms': 'Ciri Utama',
          }),
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.15,
          children: features
              .map((f) => _FeatureCard(feature: f, isDark: isDark))
              .toList(),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HEALTHCARE PROVIDERS
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildHealthcareSection(LanguageProvider lang, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SectionHeader(
              title: lang.translate({
                'id': 'Tenaga Medis',
                'en': 'Medical Staff',
                'ms': 'Kakitangan Perubatan',
              }),
              isDark: isDark,
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PatientChatDashboardScreen(),
                ),
              ),
              child: Text(
                lang.translate({'id': 'Chat', 'en': 'Chat', 'ms': 'Sembang'}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._healthcareProviders.map((provider) {
          final name = provider['full_name']?.toString() ?? 'Tenaga Medis';
          final role = provider['role']?.toString() ?? '';
          final photo = provider['photo_url']?.toString();
          final isPharmacist =
              role.toLowerCase().contains('apoteker') ||
              role.toLowerCase().contains('pharmacist');

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isPharmacist
                          ? [Colors.teal.shade300, Colors.teal.shade600]
                          : [Colors.blue.shade300, Colors.blue.shade600],
                    ),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundImage: photo != null ? NetworkImage(photo) : null,
                    backgroundColor: Colors.white,
                    child: photo == null
                        ? Icon(
                            isPharmacist
                                ? Icons.local_pharmacy
                                : Icons.medical_services,
                            color: isPharmacist ? Colors.teal : Colors.blue,
                            size: 22,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        isPharmacist
                            ? lang.translate({
                                'id': 'Apoteker Klinis',
                                'en': 'Clinical Pharmacist',
                                'ms': 'Ahli Farmasi',
                              })
                            : lang.translate({
                                'id': 'Dokter',
                                'en': 'Doctor',
                                'ms': 'Doktor',
                              }),
                        style: TextStyle(
                          fontSize: 12,
                          color: isPharmacist ? Colors.teal : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PatientChatDashboardScreen(),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isPharmacist
                            ? [Colors.teal.shade400, Colors.teal.shade700]
                            : [Colors.blue.shade400, Colors.blue.shade700],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      lang.translate({
                        'id': 'Chat',
                        'en': 'Chat',
                        'ms': 'Sembang',
                      }),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // EMERGENCY SECTION
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildEmergencySection(LanguageProvider lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: lang.translate({
            'id': 'Bantuan Darurat',
            'en': 'Emergency Help',
            'ms': 'Bantuan Kecemasan',
          }),
          isDark: false, // Always visible
        ),
        const SizedBox(height: 10),
        _EmergencyButton(
          icon: Icons.local_hospital_rounded,
          title: lang.translate({
            'id': 'RS Terdekat',
            'en': 'Nearest Hospital',
            'ms': 'Hospital Terdekat',
          }),
          subtitle: lang.translate({
            'id': 'Cari dalam radius 20km',
            'en': 'Find within 20km radius',
            'ms': 'Cari dalam radius 20km',
          }),
          gradient: [Colors.red.shade400, Colors.red.shade700],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EmergencyLocationScreen()),
          ),
        ),
        const SizedBox(height: 8),
        _EmergencyButton(
          icon: Icons.family_restroom_rounded,
          title: lang.translate({
            'id': 'Panggil Keluarga',
            'en': 'Call Family',
            'ms': 'Panggil Keluarga',
          }),
          subtitle: _emergencyContacts.isNotEmpty
              ? _emergencyContacts.first.name
              : lang.translate({
                  'id': 'Belum ada kontak',
                  'en': 'No contact set',
                  'ms': 'Tiada kenalan',
                }),
          gradient: [Colors.orange.shade400, Colors.orange.shade700],
          onTap: () {
            if (_emergencyContacts.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    lang.translate({
                      'id': 'Atur kontak darurat di Profil terlebih dahulu',
                      'en': 'Set emergency contact in Profile first',
                      'ms': 'Tetapkan kenalan kecemasan di Profil dahulu',
                    }),
                  ),
                ),
              );
              return;
            }
            final contact = _emergencyContacts.first;
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(
                  '${lang.translate({'id': 'Panggil', 'en': 'Call', 'ms': 'Panggil'})} ${contact.name}?',
                ),
                content: Text(
                  '${lang.translate({'id': 'Nomor', 'en': 'Number', 'ms': 'Nombor'})}: ${contact.phoneNumber}',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      lang.translate({
                        'id': 'Batal',
                        'en': 'Cancel',
                        'ms': 'Batal',
                      }),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${lang.translate({'id': 'Memanggil', 'en': 'Calling', 'ms': 'Memanggil'})}: ${contact.phoneNumber}',
                          ),
                        ),
                      );
                    },
                    child: Text(
                      lang.translate({
                        'id': 'Panggil',
                        'en': 'Call',
                        'ms': 'Panggil',
                      }),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Helpers ──
  String _firstName(String fullName) {
    final parts = fullName.split(' ');
    return parts.isNotEmpty ? parts.first : fullName;
  }

  int? _parseHeartRate(String hrText) {
    if (hrText.isEmpty || hrText == '--') return null;
    final m = RegExp(r'(\d+)').firstMatch(hrText);
    return m != null ? int.tryParse(m.group(1) ?? '') : null;
  }

  String _heartRateStatus(int? bpm, LanguageProvider lang) {
    if (bpm == null)
      return lang.translate({
        'id': 'Tidak ada data',
        'en': 'No data',
        'ms': 'Tiada data',
      });
    if (bpm < 60)
      return lang.translate({'id': 'Rendah', 'en': 'Low', 'ms': 'Rendah'});
    if (bpm <= 100)
      return lang.translate({'id': 'Normal', 'en': 'Normal', 'ms': 'Normal'});
    return lang.translate({'id': 'Tinggi', 'en': 'High', 'ms': 'Tinggi'});
  }

  Color _statusColor(int? bpm) {
    if (bpm == null) return Colors.white54;
    if (bpm < 60 || bpm > 100) return Colors.redAccent.shade100;
    return Colors.greenAccent.shade200;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : const Color(0xFF1A1C1E),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final bool isDark;

  const _StatItem({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  final bool isDark;
  const _VerticalDivider({required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
    height: 40,
    width: 1,
    color: isDark ? Colors.white12 : Colors.black12,
  );
}

class _ActionData {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;
  const _ActionData({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });
}

class _FeatureData {
  final IconData icon;
  final String label;
  final String desc;
  final List<Color> gradient;
  final VoidCallback onTap;
  final bool completed;
  const _FeatureData({
    required this.icon,
    required this.label,
    required this.desc,
    required this.gradient,
    required this.onTap,
    required this.completed,
  });
}

class _FeatureCard extends StatelessWidget {
  final _FeatureData feature;
  final bool isDark;
  const _FeatureCard({required this.feature, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: feature.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.07),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: feature.gradient),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(feature.icon, color: Colors.white, size: 22),
                ),
                if (feature.completed)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              feature.label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              feature.desc,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _EmergencyButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
