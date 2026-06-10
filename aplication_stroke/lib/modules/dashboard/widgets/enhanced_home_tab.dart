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
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import Providers
import '../../../providers/language_provider.dart';
import '../../../providers/theme_provider.dart';

// Import Screens
import '../../medication_reminder/medication_reminder_screen.dart';
import '../../../models/home_dashboard_models.dart';
import '../../../services/remote/home_dashboard_service.dart';
import '../../../services/remote/staff_presence_service.dart';
import '../../../utils/user_profile_helper.dart';
import '../../../utils/app_route_transitions.dart';
import '../../consultation/patient_chat_dashboard_screen.dart';
import '../../education/stroke_education_screen.dart';
import '../../rehab/rehab_dashboard_screen.dart';
import '../../health/health_monitoring_screen.dart';
import '../../emergency_location/emergency_location_screen.dart';
import '../../emergency_call/emergency_call_screen.dart';
import '../../exercise/exercise_screen.dart';
import '../../community/community_screen.dart';
import '../../notifications/notifications_screen.dart';
import '../../../services/remote/notification_inbox_service.dart';

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
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final _dashboard = HomeDashboardService.instance;

  RealtimeChannel? _sensorChannel;
  RealtimeChannel? _medLogChannel;
  RealtimeChannel? _rehabLogChannel;
  String? _patientId;
  String? _pairedPharmacistId;
  Timer? _staffRefreshTimer;

  String _userName = 'Integrated Stroke';
  String? _photoUrl;
  DashboardStats _currentStats = DashboardStats.empty();
  List<TodayMedicationDose> _todayMeds = [];
  List<TodayExercise> _todayExercises = [];
  List<StaffMemberStatus> _staffMembers = [];
  List<EmergencyContactModel> _emergencyContacts = [];
  bool _dashboardLoading = true;
  int _unreadNotifications = 0;

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
    _loadUnreadNotifications();
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      final count = await NotificationInboxService.instance.unreadCount();
      if (mounted) setState(() => _unreadNotifications = count);
    } catch (_) {}
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      AppRouteTransitions.fadeSlide(const NotificationsScreen()),
    );
    await _loadUnreadNotifications();
  }

  Future<void> _init() async {
    _patientId = await UserProfileHelper.patientProfileId();
    if (_patientId == null) {
      if (mounted) setState(() => _dashboardLoading = false);
      return;
    }

    await _loadUserProfile();
    await _fetchLatestHeartRate();
    await _refreshDashboard();
    _listenRealtime();
    _staffRefreshTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _loadStaffStatus(),
    );
  }

  Future<void> _refreshDashboard() async {
    if (_patientId == null) return;
    setState(() => _dashboardLoading = true);
    await Future.wait([
      _loadTodayMedications(),
      _loadTodayExercises(),
      _loadStaffStatus(),
    ]);
    if (mounted) setState(() => _dashboardLoading = false);
  }

  void _listenRealtime() {
    if (_patientId == null) return;

    _sensorChannel = _supabase.channel('realtime_sensor_data_$_patientId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'sensor_data',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: _patientId!,
        ),
        callback: (payload) async {
          final row = payload.newRecord;
          if (row['sensor_type'] == 'heart_rate') {
            final raw = row['value_raw'];
            if (raw is Map && raw['bpm'] != null) {
              _updateStats(heartRate: '${raw['bpm']} bpm');
            } else if (row['value_numeric'] != null) {
              _updateStats(heartRate: '${row['value_numeric']} bpm');
            }
          }
        },
      )
      ..subscribe();

    _medLogChannel = _dashboard.subscribeMedicationLogs(
      _patientId!,
      _loadTodayMedications,
    );
    _rehabLogChannel = _dashboard.subscribeExerciseLogs(
      _patientId!,
      _loadTodayExercises,
    );
    StaffPresenceService.instance.subscribePresence(_loadStaffStatus);
  }

  Future<void> _loadUserProfile() async {
    if (_patientId == null) return;
    try {
      final data = await _supabase
          .from('users')
          .select(
            'name, profile_picture, paired_pharmacist_id, emergency_contact_name, emergency_contact_phone',
          )
          .eq('id', _patientId!)
          .maybeSingle();

      if (!mounted || data == null) return;
      setState(() {
        final name = data['name']?.toString() ?? '';
        _userName = name.isNotEmpty ? name : 'Integrated Stroke';
        _photoUrl = data['profile_picture']?.toString();
        _pairedPharmacistId = data['paired_pharmacist_id']?.toString();
        final ecName = data['emergency_contact_name']?.toString();
        final ecPhone = data['emergency_contact_phone']?.toString();
        if (ecName != null && ecName.isNotEmpty) {
          _emergencyContacts = [
            EmergencyContactModel(
              name: ecName,
              phoneNumber: ecPhone ?? '',
              relationship: '',
            ),
          ];
        }
      });
    } catch (_) {}
  }

  Future<void> _fetchLatestHeartRate() async {
    if (_patientId == null) return;
    try {
      final response = await _supabase
          .from('sensor_data')
          .select('value_raw, value_numeric')
          .eq('user_id', _patientId!)
          .eq('sensor_type', 'heart_rate')
          .order('recorded_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final raw = response?['value_raw'];
      if (raw is Map && raw['bpm'] != null) {
        _updateStats(heartRate: '${raw['bpm']} bpm');
      } else if (response?['value_numeric'] != null) {
        _updateStats(heartRate: '${response!['value_numeric']} bpm');
      }
    } catch (_) {}
  }

  Future<void> _loadTodayMedications() async {
    if (_patientId == null) return;
    try {
      final meds = await _dashboard.loadTodayMedications(_patientId!);
      if (mounted) setState(() => _todayMeds = meds);
    } catch (_) {}
  }

  Future<void> _loadTodayExercises() async {
    if (_patientId == null) return;
    try {
      final exercises = await _dashboard.loadTodayExercises(_patientId!);
      if (mounted) setState(() => _todayExercises = exercises);
    } catch (_) {}
  }

  Future<void> _loadStaffStatus() async {
    try {
      final staff = await _dashboard.loadStaffStatus(
        pairedPharmacistId: _pairedPharmacistId,
      );
      if (mounted) setState(() => _staffMembers = staff);
    } catch (_) {}
  }

  void _updateStats({String? heartRate}) {
    _currentStats = DashboardStats(
      heartRate: heartRate ?? _currentStats.heartRate,
    );
    _statsController.add(_currentStats);
  }

  Future<void> _toggleMedication(TodayMedicationDose dose) async {
    if (_patientId == null) return;
    final newTaken = !dose.taken;
    final newStock = dose.quantityRemaining != null
        ? (newTaken
              ? (dose.quantityRemaining! - dose.doseAmount).clamp(0, 9999)
              : dose.quantityRemaining! + dose.doseAmount)
        : null;

    setState(() {
      _todayMeds = _todayMeds.map((d) {
        if (d.reminderId == dose.reminderId &&
            d.scheduledAt == dose.scheduledAt) {
          return d.copyWith(taken: newTaken, quantityRemaining: newStock);
        }
        return d;
      }).toList();
    });

    try {
      await _dashboard.toggleMedicationDose(dose, _patientId!, newTaken);
    } catch (e) {
      await _loadTodayMedications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui: $e')),
        );
      }
    }
  }

  Future<void> _toggleExercise(TodayExercise exercise) async {
    if (_patientId == null) return;
    final newCompleted = !exercise.completed;

    setState(() {
      _todayExercises = _todayExercises.map((e) {
        if (e.id == exercise.id) {
          return e.copyWith(completed: newCompleted);
        }
        return e;
      }).toList();
    });

    try {
      await _dashboard.toggleExercise(
        exercise,
        _patientId!,
        newCompleted,
      );
    } catch (e) {
      await _loadTodayExercises();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui latihan: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _staffRefreshTimer?.cancel();
    _sensorChannel?.unsubscribe();
    if (_sensorChannel != null) _supabase.removeChannel(_sensorChannel!);
    _medLogChannel?.unsubscribe();
    if (_medLogChannel != null) _supabase.removeChannel(_medLogChannel!);
    _rehabLogChannel?.unsubscribe();
    if (_rehabLogChannel != null) _supabase.removeChannel(_rehabLogChannel!);
    StaffPresenceService.instance.disposeChannel();
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

            // ── Obat Hari Ini ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildMedicationSection(lang, isDark),
              ),
            ),

            // ── Latihan Hari Ini ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildTodayExerciseSection(lang, isDark),
              ),
            ),

            // ── Feature Grid ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildFeatureGrid(lang, isDark),
              ),
            ),

            // ── Tenaga Medis Jaga / Online ──
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
                  GestureDetector(
                    onTap: _openNotifications,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        if (_unreadNotifications > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                _unreadNotifications > 9
                                    ? '9+'
                                    : '$_unreadNotifications',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
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
    final exercisesDone = _todayExercises.where((e) => e.completed).length;
    final medicsTaken = _todayMeds.where((r) => r.taken).length;

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
              value: _todayExercises.isEmpty
                  ? '0'
                  : '$exercisesDone/${_todayExercises.length}',
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
              value: _todayMeds.isEmpty
                  ? '0'
                  : '$medicsTaken/${_todayMeds.length}',
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
          MaterialPageRoute(builder: (_) => const MedicationReminderScreenV2()),
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
          MaterialPageRoute(builder: (_) => const ExerciseScreenV2()),
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
          MaterialPageRoute(builder: (_) => const HealthMonitoringScreenV2()),
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
    final visibleMeds = _todayMeds.take(5).toList();
    final doneCount = _todayMeds.where((r) => r.taken).length;
    final progress =
        _todayMeds.isEmpty ? 0.0 : doneCount / _todayMeds.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SectionHeader(
              title: lang.translate({
                'id': 'Obat Hari Ini',
                'en': "Today's Medicine",
                'ms': 'Ubat Hari Ini',
              }),
              isDark: isDark,
            ),
            TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                AppRouteTransitions.fadeSlide(
                  const MedicationReminderScreenV2(),
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
          child: _dashboardLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _todayMeds.isEmpty
              ? Text(
                  lang.translate({
                    'id': 'Belum ada jadwal obat hari ini.',
                    'en': 'No medicine scheduled for today.',
                    'ms': 'Tiada jadual ubat hari ini.',
                  }),
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black45,
                    fontSize: 13,
                  ),
                )
              : Column(
                  children: [
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
                          '$doneCount/${_todayMeds.length}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...visibleMeds.map(
                      (dose) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                          onTap: () => _toggleMedication(dose),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: dose.taken
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : (isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.grey.shade50),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: dose.taken
                                    ? Colors.green.withValues(alpha: 0.4)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: dose.taken
                                        ? Colors.green.withValues(alpha: 0.15)
                                        : Colors.indigo.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    dose.taken
                                        ? Icons.check_circle_rounded
                                        : Icons.medication_rounded,
                                    size: 18,
                                    color: dose.taken
                                        ? Colors.green
                                        : Colors.indigo,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dose.medicationName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          decoration: dose.taken
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        '${dose.time.format(context)} · ${dose.dosage} · ${_periodLabel(dose.period, lang)}${dose.quantityRemaining != null ? ' · Stok: ${dose.quantityRemaining}' : ''}',
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
                                if (!dose.taken)
                                  Icon(
                                    Icons.touch_app_outlined,
                                    size: 16,
                                    color: Colors.indigo.withValues(alpha: 0.5),
                                  ),
                                if (dose.taken)
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
                  ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildTodayExerciseSection(LanguageProvider lang, bool isDark) {
    final visible = _todayExercises.take(5).toList();
    final doneCount = _todayExercises.where((e) => e.completed).length;
    final progress = _todayExercises.isEmpty
        ? 0.0
        : doneCount / _todayExercises.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SectionHeader(
              title: lang.translate({
                'id': 'Latihan Hari Ini',
                'en': "Today's Exercise",
                'ms': 'Latihan Hari Ini',
              }),
              isDark: isDark,
            ),
            TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                AppRouteTransitions.fadeSlide(const RehabDashboardScreen()),
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
          child: _dashboardLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _todayExercises.isEmpty
              ? Text(
                  lang.translate({
                    'id':
                        'Belum ada program latihan. Mulai dari menu Rehabilitasi.',
                    'en': 'No exercise program yet. Start from Rehab menu.',
                    'ms':
                        'Tiada program latihan. Mulakan dari menu Pemulihan.',
                  }),
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black45,
                    fontSize: 13,
                  ),
                )
              : Column(
                  children: [
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
                                progress == 1 ? Colors.green : Colors.teal,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '$doneCount/${_todayExercises.length}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...visible.map(
                      (exercise) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _toggleExercise(exercise),
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: exercise.completed
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : (isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.grey.shade50),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: exercise.completed
                                      ? Colors.green.withValues(alpha: 0.4)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    exercise.completed
                                        ? Icons.check_circle_rounded
                                        : Icons.fitness_center_rounded,
                                    size: 20,
                                    color: exercise.completed
                                        ? Colors.green
                                        : Colors.teal,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          exercise.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            decoration: exercise.completed
                                                ? TextDecoration.lineThrough
                                                : null,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          '${_periodLabel(exercise.sessionPeriod, lang)} · ${exercise.durationText}',
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
                                  if (!exercise.completed)
                                    Icon(
                                      Icons.touch_app_outlined,
                                      size: 16,
                                      color: Colors.teal.withValues(alpha: 0.5),
                                    ),
                                  if (exercise.completed)
                                    Text(
                                      lang.translate({
                                        'id': 'Selesai',
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
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  String _periodLabel(String period, LanguageProvider lang) {
    switch (period) {
      case 'pagi':
        return lang.translate({'id': 'Pagi', 'en': 'Morning', 'ms': 'Pagi'});
      case 'siang':
        return lang.translate({'id': 'Siang', 'en': 'Afternoon', 'ms': 'Petang'});
      case 'sore':
        return lang.translate({'id': 'Sore', 'en': 'Evening', 'ms': 'Petang'});
      case 'malam':
        return lang.translate({'id': 'Malam', 'en': 'Night', 'ms': 'Malam'});
      default:
        return period;
    }
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
          MaterialPageRoute(builder: (_) => const ExerciseScreenV2()),
        ),
        completed: _todayExercises.isNotEmpty &&
            _todayExercises.every((e) => e.completed),
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
          MaterialPageRoute(builder: (_) => const HealthMonitoringScreenV2()),
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
    final onDuty = _staffMembers.where((s) => s.isAvailable).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SectionHeader(
              title: lang.translate({
                'id': 'Jaga & Online Sekarang',
                'en': 'On Duty & Online',
                'ms': 'Bertugas & Dalam Talian',
              }),
              isDark: isDark,
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                AppRouteTransitions.fadeSlide(
                  const PatientChatDashboardScreen(),
                ),
              ),
              child: Text(
                lang.translate({'id': 'Chat', 'en': 'Chat', 'ms': 'Sembang'}),
              ),
            ),
          ],
        ),
        if (onDuty.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              lang.translate({
                'id': '${onDuty.length} tenaga medis tersedia saat ini',
                'en': '${onDuty.length} staff available now',
                'ms': '${onDuty.length} kakitangan tersedia sekarang',
              }),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.greenAccent : Colors.teal.shade700,
              ),
            ),
          ),
        const SizedBox(height: 4),
        if (_dashboardLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (_staffMembers.isEmpty)
          Text(
            lang.translate({
              'id': 'Belum ada data tenaga medis.',
              'en': 'No medical staff data yet.',
              'ms': 'Tiada data kakitangan perubatan.',
            }),
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black45,
              fontSize: 13,
            ),
          )
        else
          ..._staffMembers.take(6).map((staff) {
            final isPharmacist = staff.isPharmacist;
            final statusLabel = _staffStatusLabel(staff, lang);
            final statusColor = staff.isAvailable
                ? Colors.green
                : (isDark ? Colors.white38 : Colors.black38);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: staff.isAvailable
                    ? Border.all(color: Colors.green.withValues(alpha: 0.35))
                    : null,
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
                  Stack(
                    clipBehavior: Clip.none,
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
                          backgroundImage: staff.photoUrl != null
                              ? NetworkImage(staff.photoUrl!)
                              : null,
                          backgroundColor: Colors.white,
                          child: staff.photoUrl == null
                              ? Icon(
                                  isPharmacist
                                      ? Icons.local_pharmacy
                                      : Icons.medical_services,
                                  color:
                                      isPharmacist ? Colors.teal : Colors.blue,
                                  size: 22,
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        right: -1,
                        bottom: -1,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: staff.isOnline ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          staff.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          staff.subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              staff.isOnDuty
                                  ? Icons.schedule_rounded
                                  : Icons.circle,
                              size: 10,
                              color: statusColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isPharmacist)
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        AppRouteTransitions.fadeSlide(
                          const PatientChatDashboardScreen(),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.teal.shade400,
                              Colors.teal.shade700,
                            ],
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

  String _staffStatusLabel(StaffMemberStatus staff, LanguageProvider lang) {
    if (staff.isOnline && staff.isOnDuty) {
      return lang.translate({
        'id': 'Jaga · Online',
        'en': 'On duty · Online',
        'ms': 'Bertugas · Dalam talian',
      });
    }
    if (staff.isOnDuty) {
      return lang.translate({
        'id': 'Sedang jaga',
        'en': 'On duty',
        'ms': 'Sedang bertugas',
      });
    }
    if (staff.isOnline) {
      return lang.translate({
        'id': 'Online',
        'en': 'Online',
        'ms': 'Dalam talian',
      });
    }
    return lang.translate({
      'id': 'Offline',
      'en': 'Offline',
      'ms': 'Luar talian',
    });
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
                    onPressed: () async {
                      Navigator.pop(context);
                      final phone = contact.phoneNumber.replaceAll(' ', '');
                      if (phone.isNotEmpty) {
                        await launchUrl(Uri.parse('tel:$phone'));
                      }
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
