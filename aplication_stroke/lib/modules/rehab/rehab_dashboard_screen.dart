import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/rehab_models.dart';
import '../../../services/remote/rehab_service.dart';
import '../../../widgets/pop_up_loading.dart';
import 'exercise_session_screen.dart';
import 'rehab_quiz_screen.dart';

class RehabDashboardScreen extends StatefulWidget {
  const RehabDashboardScreen({super.key});

  @override
  State<RehabDashboardScreen> createState() => _RehabDashboardScreenState();
}

class _RehabDashboardScreenState extends State<RehabDashboardScreen> {
  final RehabService _rehabService = RehabService();
  final String _userId = Supabase.instance.client.auth.currentUser?.id ?? '';

  bool _isLoading = true;
  List<RehabExercise> _exercises = [];
  RehabPhase? _currentPhase;
  RehabProgress? _progress;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      if (_userId.isEmpty) {
        // Load sample exercises for demo purposes
        _loadSampleExercises();
      } else {
        _progress = await _rehabService.getUserProgress(_userId);
        if (_progress != null) {
          _currentPhase = await _rehabService.getPhaseDetail(
            _progress!.currentPhaseId,
          );
          _exercises = await _rehabService.getExercises(
            _progress!.currentPhaseId,
          );
        } else {
          _currentPhase = null;
          _exercises = [];
          _loadSampleExercises();
        }
      }
    } catch (e) {
      debugPrint('Error loading rehab data: $e');
      _loadSampleExercises();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loadSampleExercises() {
    _currentPhase = RehabPhase(id: 1, name: 'Fase 1: Pemulihan Awal');
    _progress = RehabProgress(
      userId: _userId.isEmpty ? 'demo' : _userId,
      currentPhaseId: 1,
      phaseStartedAt: DateTime.now(),
      streakCount: 3,
    );
    _exercises = [
      RehabExercise(
        id: '1',
        phaseId: 1,
        name: 'Latihan Pergelangan Tangan',
        instructions: [
          'Rentangkan tangan',
          'Putar pergelangan searah jarum jam',
          'Putar berlawanan arah jarum jam',
        ],
        durationText: '5 menit',
        durationSeconds: 300,
        timeCategory: 'pagi',
      ),
      RehabExercise(
        id: '2',
        phaseId: 1,
        name: 'Latihan Jari-Jari',
        instructions: ['Rentangkan jari', 'Kepalkan tangan', 'Ulangi 10 kali'],
        durationText: '5 menit',
        durationSeconds: 300,
        timeCategory: 'pagi',
      ),
      RehabExercise(
        id: '3',
        phaseId: 1,
        name: 'Latihan Lengan Atas',
        instructions: [
          'Angkat lengan ke atas',
          'Tahan 5 detik',
          'Turunkan perlahan',
        ],
        durationText: '10 menit',
        durationSeconds: 600,
        timeCategory: 'siang',
      ),
      RehabExercise(
        id: '4',
        phaseId: 1,
        name: 'Latihan Kaki',
        instructions: [
          'Duduk dengan kaki terangkat',
          'Luruskan kaki',
          'Tahan 5 detik',
        ],
        durationText: '10 menit',
        durationSeconds: 600,
        timeCategory: 'sore',
      ),
      RehabExercise(
        id: '5',
        phaseId: 1,
        name: 'Latihan Keseimbangan',
        instructions: [
          'Berdiri dengan kedua kaki',
          'Pindahkan berat badan',
          'Pertahankan keseimbangan',
        ],
        durationText: '8 menit',
        durationSeconds: 480,
        timeCategory: 'sore',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildDashboard(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0A7AC1).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fitness_center,
                size: 80,
                color: Color(0xFF0A7AC1),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Mulai Perjalanan\nPemulihan Anda',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Program rehabilitasi khusus untuk\nmembantu Anda pulih di rumah',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _startInitialProgram,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A7AC1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Mulai Sekarang',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startInitialProgram() async {
    if (_userId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu.')),
      );
      return;
    }
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PopUpLoading(),
      );
      await Supabase.instance.client.from('rehab_user_progress').upsert({
        'user_id': _userId,
        'current_phase_id': 1,
        'phase_started_at': DateTime.now().toIso8601String(),
        'streak_count': 0,
      }, onConflict: 'user_id');
      await _loadData();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Program fase 1 dimulai. Semangat!')),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memulai program: $e')));
    }
  }

  Widget _buildDashboard() {
    final exercisesByTime = _getExercisesByTimeOfDay();

    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverToBoxAdapter(
          child: Column(
            children: [
              _buildProgressHeader(),
              _buildStatsRow(),
              _buildDailyGoalCard(),
              _buildExerciseSchedule(exercisesByTime),
              _buildQuizSection(),
              _buildAchievements(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  Map<String, List<RehabExercise>> _getExercisesByTimeOfDay() {
    return {
      'pagi': _exercises.where((e) => e.timeCategory == 'pagi').toList(),
      'siang': _exercises.where((e) => e.timeCategory == 'siang').toList(),
      'sore': _exercises.where((e) => e.timeCategory == 'sore').toList(),
    };
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF0A7AC1),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Rehab Stroke',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A7AC1), Color(0xFF059669)],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.emoji_events, color: Colors.amber),
          onPressed: () => _showAchievements(),
        ),
        IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
      ],
    );
  }

  Widget _buildProgressHeader() {
    final phaseName = _currentPhase?.name ?? 'Fase 1';
    final daysActive = _progress?.streakCount ?? 0;
    final progressPercent = ((_progress?.currentPhaseId ?? 1) / 4 * 100).clamp(
      0,
      100,
    );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A7AC1), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A7AC1).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    phaseName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$daysActive hari berturut-turut',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${progressPercent.toInt()}%',
                    style: const TextStyle(
                      color: Color(0xFF0A7AC1),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progressPercent / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Progress fase ${_progress?.currentPhaseId ?? 1} dari 4',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final totalExercises = _exercises.length;
    final completedToday = (_progress?.streakCount ?? 0) % 7;
    final caloriesBurned = totalExercises * 25;
    final minutesDone = totalExercises * 5;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildStatCard(
            icon: Icons.local_fire_department,
            iconColor: Colors.orange,
            value: '$caloriesBurned',
            label: 'Kalori',
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            icon: Icons.timer,
            iconColor: const Color(0xFF0A7AC1),
            value: '$minutesDone',
            label: 'Menit',
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            icon: Icons.check_circle,
            iconColor: const Color(0xFF059669),
            value: '$completedToday/$totalExercises',
            label: 'Selesai',
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyGoalCard() {
    final exercisesByTime = _getExercisesByTimeOfDay();
    final allExercises = [
      ...exercisesByTime['pagi']!,
      ...exercisesByTime['siang']!,
      ...exercisesByTime['sore']!,
    ];
    final completedCount = 0;
    final totalCount = allExercises.length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              const Text(
                'Target Harian',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$completedCount / $totalCount',
                  style: const TextStyle(
                    color: Color(0xFF059669),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: totalCount > 0 ? completedCount / totalCount : 0,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF059669),
              ),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selesaikan semua latihan untuk mencapai target!',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseSchedule(
    Map<String, List<RehabExercise>> exercisesByTime,
  ) {
    final timeSlots = [
      {
        'key': 'pagi',
        'label': 'Pagi',
        'icon': Icons.wb_sunny,
        'time': '06.00 - 10.00',
      },
      {
        'key': 'siang',
        'label': 'Siang',
        'icon': Icons.wb_cloudy,
        'time': '12.00 - 15.00',
      },
      {
        'key': 'sore',
        'label': 'Sore',
        'icon': Icons.nights_stay,
        'time': '17.00 - 20.00',
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Jadwal Latihan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 16),
          ...timeSlots.map((slot) {
            final exercises = exercisesByTime[slot['key']] ?? [];
            return _buildTimeSlotCard(
              label: slot['label'] as String,
              icon: slot['icon'] as IconData,
              time: slot['time'] as String,
              exercises: exercises,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimeSlotCard({
    required String label,
    required IconData icon,
    required String time,
    required List<RehabExercise> exercises,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0A7AC1).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A7AC1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
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
                    color: exercises.isEmpty
                        ? Colors.grey.shade200
                        : const Color(0xFF059669).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${exercises.length} Latihan',
                    style: TextStyle(
                      color: exercises.isEmpty
                          ? Colors.grey
                          : const Color(0xFF059669),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (exercises.isNotEmpty)
            ...exercises.map((exercise) => _buildExerciseItem(exercise))
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Tidak ada latihan untuk periode ini',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExerciseItem(RehabExercise exercise) {
    return InkWell(
      onTap: () => _startExercise(exercise),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: exercise.mediaUrl != null && exercise.mediaUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        exercise.mediaUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.fitness_center,
                          color: Color(0xFF0A7AC1),
                        ),
                      ),
                    )
                  : const Icon(Icons.fitness_center, color: Color(0xFF0A7AC1)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  Text(
                    exercise.durationText,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0A7AC1).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Color(0xFF0A7AC1),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startExercise(RehabExercise exercise) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseSessionScreen(exercise: exercise),
      ),
    ).then((_) => _loadData());
  }

  Widget _buildQuizSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.amber.shade400, Colors.orange.shade600],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kuis Pemahaman',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Uji pemahaman Anda tentang rehabilitasi stroke',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => _startQuiz(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Mulai Kuis',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.quiz, color: Colors.white, size: 40),
          ),
        ],
      ),
    );
  }

  void _startQuiz() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            RehabQuizScreen(phaseFrom: _progress?.currentPhaseId ?? 1),
      ),
    );
  }

  Widget _buildAchievements() {
    final achievements = [
      {
        'icon': Icons.local_fire_department,
        'label': '7 Hari Beruntun',
        'unlocked': (_progress?.streakCount ?? 0) >= 7,
      },
      {
        'icon': Icons.star,
        'label': 'Fase 1 Selesai',
        'unlocked': (_progress?.currentPhaseId ?? 0) >= 2,
      },
      {
        'icon': Icons.emoji_events,
        'label': '10 Latihan',
        'unlocked': (_progress?.streakCount ?? 0) >= 10,
      },
      {'icon': Icons.shield, 'label': 'Quiz Lulus', 'unlocked': false},
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pencapaian',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final achievement = achievements[index];
                final isUnlocked = achievement['unlocked'] as bool;
                return Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: isUnlocked
                              ? Colors.amber.shade100
                              : Colors.grey.shade200,
                          shape: BoxShape.circle,
                          border: isUnlocked
                              ? Border.all(color: Colors.amber, width: 2)
                              : null,
                        ),
                        child: Icon(
                          achievement['icon'] as IconData,
                          color: isUnlocked
                              ? Colors.amber.shade700
                              : Colors.grey,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        achievement['label'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: isUnlocked
                              ? const Color(0xFF1A1A2E)
                              : Colors.grey,
                          fontWeight: isUnlocked
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAchievements() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Pencapaian',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildAchievementItem(
              icon: Icons.local_fire_department,
              label: '7 Hari Beruntun',
              description: 'Latihan 7 hari berturut-turut',
              isUnlocked: (_progress?.streakCount ?? 0) >= 7,
            ),
            _buildAchievementItem(
              icon: Icons.star,
              label: 'Fase 1 Selesai',
              description: 'Selesaikan fase 1 rehabilitasi',
              isUnlocked: (_progress?.currentPhaseId ?? 0) >= 2,
            ),
            _buildAchievementItem(
              icon: Icons.fitness_center,
              label: '10 Latihan',
              description: 'Selesaikan 10 sesi latihan',
              isUnlocked: (_progress?.streakCount ?? 0) >= 10,
            ),
            _buildAchievementItem(
              icon: Icons.quiz,
              label: 'Quiz Lulus',
              description: 'Lulus kuis pemahaman',
              isUnlocked: false,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementItem({
    required IconData icon,
    required String label,
    required String description,
    required bool isUnlocked,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.amber.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: isUnlocked ? Border.all(color: Colors.amber) : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUnlocked ? Colors.amber : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isUnlocked ? Colors.white : Colors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isUnlocked ? const Color(0xFF1A1A2E) : Colors.grey,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (isUnlocked)
            const Icon(Icons.check_circle, color: Colors.amber)
          else
            Icon(Icons.lock, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}
