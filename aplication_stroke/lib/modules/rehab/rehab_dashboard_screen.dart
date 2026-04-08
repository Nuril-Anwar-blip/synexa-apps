// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../../../models/rehab_models.dart';
// import '../../../services/remote/rehab_service.dart';
// import 'exercise_session_screen.dart';

// class RehabDashboardScreen extends StatefulWidget {
//   const RehabDashboardScreen({super.key});

//   @override
//   State<RehabDashboardScreen> createState() => _RehabDashboardScreenState();
// }

// class _RehabDashboardScreenState extends State<RehabDashboardScreen> {
//   final RehabService _rehabService = RehabService();
//   final String _userId = Supabase.instance.client.auth.currentUser?.id ?? '';

//   bool _isLoading = true;
//   List<RehabExercise> _exercises = [];
//   RehabPhase? _currentPhase;
//   RehabProgress? _progress;

//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//   }

//   Future<void> _loadData() async {
//     setState(() => _isLoading = true);
//     try {
//       if (_userId.isEmpty) {
//         _progress = null;
//         _exercises = [];
//       } else {
//         _progress = await _rehabService.getUserProgress(_userId);
//         if (_progress != null) {
//           _currentPhase =
//               await _rehabService.getPhaseDetail(_progress!.currentPhaseId);
//           _exercises =
//               await _rehabService.getExercises(_progress!.currentPhaseId);
//         } else {
//           _currentPhase = null;
//           _exercises = [];
//         }
//       }
//     } catch (e) {
//       debugPrint('Error loading rehab data: $e');
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Program Rehabilitasi'),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _progress == null
//               ? _buildEmptyState()
//               : _buildDashboard(),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Icon(Icons.fitness_center, size: 64, color: Colors.grey),
//           const SizedBox(height: 16),
//           const Text('Belum ada program aktif.'),
//           const SizedBox(height: 8),
//           ElevatedButton(
//             onPressed: _startInitialProgram,
//             child: const Text('Mulai Program'),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _startInitialProgram() async {
//     if (_userId.isEmpty) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Silakan login terlebih dahulu.')),
//       );
//       return;
//     }
//     try {
//       await Supabase.instance.client.from('rehab_user_progress').upsert(
//         {
//           'user_id': _userId,
//           'current_phase_id': 1,
//           'phase_started_at': DateTime.now().toIso8601String(),
//           'streak_count': 0,
//         },
//         onConflict: 'user_id',
//       );
//       await _loadData();
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Program fase 1 dimulai.')),
//       );
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Gagal memulai program: $e')),
//       );
//     }
//   }

//   Widget _buildDashboard() {
//     return ListView(
//       padding: const EdgeInsets.all(16),
//       children: [
//         _buildProgressCard(),
//         const SizedBox(height: 24),
//         _buildExerciseSection('Latihan Hari Ini', _exercises, Icons.fitness_center, Colors.blue),
//       ],
//     );
//   }

//   Widget _buildProgressCard() {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Container(
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(16),
//           gradient: LinearGradient(
//             colors: [Colors.blue.shade700, Colors.blue.shade400],
//           ),
//         ),
//         child: Column(
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Fase Saat Ini',
//                       style: TextStyle(color: Colors.white70, fontSize: 14),
//                     ),
//                     Text(
//                       _currentPhase?.name ?? '...',
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//                 // Streak count removed as not in schema
//               ],
//             ),
//             const SizedBox(height: 20),
//             LinearProgressIndicator(
//               value: 0.1, // Fixed dummy for now
//               backgroundColor: Colors.white24,
//               valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
//               minHeight: 8,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildExerciseSection(String title, List<RehabExercise> exercises, IconData icon, Color color) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Icon(icon, color: color),
//             const SizedBox(width: 8),
//             Text(
//               title,
//               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//           ],
//         ),
//         const SizedBox(height: 12),
//         if (exercises.isEmpty)
//           const Padding(
//             padding: EdgeInsets.only(left: 32, bottom: 16),
//             child: Text('Tidak ada latihan.', style: TextStyle(color: Colors.grey)),
//           )
//         else
//           ...exercises.map((e) => _buildExerciseCard(e)).toList(),
//         const SizedBox(height: 16),
//       ],
//     );
//   }

//   Widget _buildExerciseCard(RehabExercise exercise) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: ListTile(
//         leading: Container(
//           width: 48,
//           height: 48,
//           decoration: BoxDecoration(
//             color: Colors.blue.shade50,
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: const Icon(Icons.play_arrow, color: Colors.blue),
//         ),
//         title: Text(exercise.name, style: const TextStyle(fontWeight: FontWeight.bold)),
//         subtitle: Text(exercise.durationText),
//         trailing: const Icon(Icons.chevron_right),
//         onTap: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (_) => ExerciseSessionScreen(exercise: exercise),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// ====================================================================
// File: rehab_dashboard_screen.dart — Redesigned UI, same functions
// ====================================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/rehab_models.dart';
import '../../../services/remote/rehab_service.dart';
import 'exercise_session_screen.dart';

class RehabDashboardScreen extends StatefulWidget {
  const RehabDashboardScreen({super.key});

  @override
  State<RehabDashboardScreen> createState() => _RehabDashboardScreenState();
}

class _RehabDashboardScreenState extends State<RehabDashboardScreen>
    with SingleTickerProviderStateMixin {
  final RehabService _rehabService = RehabService();
  final String _userId = Supabase.instance.client.auth.currentUser?.id ?? '';

  bool _isLoading = true;
  List<RehabExercise> _exercises = [];
  RehabPhase? _currentPhase;
  RehabProgress? _progress;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      if (_userId.isEmpty) {
        _progress = null;
        _exercises = [];
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
        }
      }
    } catch (e) {
      debugPrint('Error loading rehab data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
      await Supabase.instance.client.from('rehab_user_progress').upsert({
        'user_id': _userId,
        'current_phase_id': 1,
        'phase_started_at': DateTime.now().toIso8601String(),
        'streak_count': 0,
      }, onConflict: 'user_id');
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Program fase 1 dimulai.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memulai program: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F1923)
          : const Color(0xFFF4F7FB),
      body: _isLoading
          ? _buildLoading()
          : _progress == null
          ? _buildEmptyState(isDark)
          : _buildDashboard(isDark),
    );
  }

  Widget _buildLoading() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.purple.shade400),
            const SizedBox(height: 16),
            const Text(
              'Memuat program rehabilitasi...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F1923)
          : const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('Program Rehabilitasi'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade400, Colors.blue.shade400],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Mulai Perjalanan\nRehabilitasi Anda',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Program latihan terstruktur yang dirancang oleh tenaga medis untuk membantu pemulihan stroke Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              _featurePill(
                Icons.check_circle_outline,
                'Program fase bertahap',
                Colors.green,
              ),
              const SizedBox(height: 8),
              _featurePill(
                Icons.timer_outlined,
                'Durasi latihan terukur',
                Colors.blue,
              ),
              const SizedBox(height: 8),
              _featurePill(
                Icons.trending_up,
                'Pantau progres harian',
                Colors.orange,
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade500, Colors.blue.shade500],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow_rounded, size: 22),
                    label: const Text(
                      'Mulai Program Rehabilitasi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: _startInitialProgram,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featurePill(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(bool isDark) {
    return NestedScrollView(
      headerSliverBuilder: (_, __) => [
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: isDark ? const Color(0xFF0F1923) : Colors.white,
          elevation: 0,
          title: const Text('Program Rehabilitasi'),
          flexibleSpace: FlexibleSpaceBar(background: _buildHeroHeader(isDark)),
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.purple.shade400,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.purple.shade400,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700),
            tabs: const [
              Tab(
                icon: Icon(Icons.fitness_center_rounded, size: 18),
                text: 'Latihan Hari Ini',
              ),
              Tab(
                icon: Icon(Icons.info_outline, size: 18),
                text: 'Tentang Fase',
              ),
            ],
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [_buildExerciseList(isDark), _buildPhaseInfo(isDark)],
      ),
    );
  }

  Widget _buildHeroHeader(bool isDark) {
    final phaseId = _progress?.currentPhaseId ?? 1;
    final phaseName = _currentPhase?.name ?? 'Fase $phaseId';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2D1B69), const Color(0xFF0F1923)]
              : [Colors.purple.shade600, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 60),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Program Aktif',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      phaseName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_exercises.length} latihan tersedia',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      '${_exercises.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Latihan',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseList(bool isDark) {
    if (_exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sports_gymnastics,
              size: 56,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada latihan untuk fase ini.',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _exercises.length,
        itemBuilder: (_, i) => _exerciseCard(_exercises[i], i, isDark),
      ),
    );
  }

  Widget _exerciseCard(RehabExercise exercise, int index, bool isDark) {
    final colors = [
      Colors.purple,
      Colors.blue,
      Colors.teal,
      Colors.green,
      Colors.orange,
      Colors.pink,
    ];
    final color = colors[index % colors.length];
    final minutes = (exercise.durationSeconds / 60).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2636) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.shade300, color.shade600],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.timer_outlined, size: 14, color: color),
                          const SizedBox(width: 4),
                          Text(
                            '$minutes menit',
                            style: TextStyle(
                              fontSize: 12,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.format_list_bulleted,
                            size: 14,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${exercise.instructions.length} langkah',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
          if (exercise.instructions.isNotEmpty) ...[
            Divider(
              height: 1,
              color: isDark ? Colors.white12 : Colors.grey.shade100,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instruksi:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...exercise.instructions
                      .take(2)
                      .map(
                        (step) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(top: 5, right: 8),
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  step,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  if (exercise.instructions.length > 2)
                    Text(
                      '+${exercise.instructions.length - 2} langkah lagi...',
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
            child: SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.shade400, color.shade700],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text(
                    'Mulai Sesi',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExerciseSessionScreen(
                        exercise: MockExercise(
                          id: exercise.id,
                          name: exercise.name,
                          instructions: exercise.instructions,
                          durationSeconds: exercise.durationSeconds,
                          durationText: exercise.durationText,
                          mediaUrl: exercise.mediaUrl,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseInfo(bool isDark) {
    final phaseId = _progress?.currentPhaseId ?? 1;
    final phaseStarted = _progress?.phaseStartedAt;
    final daysSince = phaseStarted != null
        ? DateTime.now().difference(phaseStarted).inDays
        : 0;

    final phaseDescriptions = {
      1: 'Fase awal berfokus pada pemulihan fungsi dasar, meningkatkan kekuatan otot ringan, dan mobilisasi sendi yang kaku akibat stroke.',
      2: 'Fase menengah meningkatkan koordinasi dan keseimbangan, latihan aktif lebih intensif untuk memperkuat fungsi motorik.',
      3: 'Fase lanjut berfokus pada pemulihan fungsional penuh, aktivitas kehidupan sehari-hari, dan peningkatan kualitas hidup.',
    };

    final phaseGoals = {
      1: [
        'Meningkatkan rentang gerak sendi',
        'Mengurangi kekakuan otot',
        'Melatih koordinasi dasar',
        'Memperkuat napas',
      ],
      2: [
        'Latihan keseimbangan aktif',
        'Koordinasi tangan-kaki',
        'Meningkatkan stamina',
        'Latihan fungsional ringan',
      ],
      3: [
        'Aktivitas kehidupan sehari-hari',
        'Olahraga ringan mandiri',
        'Peningkatan kualitas hidup',
        'Kembali ke rutinitas normal',
      ],
    };

    final desc =
        phaseDescriptions[phaseId] ??
        'Program rehabilitasi terstruktur untuk pemulihan pascastroke.';
    final goals = phaseGoals[phaseId] ?? [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Status card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade500, Colors.blue.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Status Program',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _currentPhase?.name ?? 'Fase $phaseId',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _statChip(
                    Icons.calendar_today_outlined,
                    '$daysSince hari berjalan',
                    Colors.white,
                  ),
                  const SizedBox(width: 10),
                  _statChip(
                    Icons.fitness_center_rounded,
                    '${_exercises.length} latihan',
                    Colors.white,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Description
        _infoSection('Tentang Fase Ini', Icons.info_outline, isDark, [
          Text(
            desc,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black54,
              height: 1.6,
            ),
          ),
        ]),
        const SizedBox(height: 16),

        // Goals
        _infoSection('Target Latihan', Icons.flag_outlined, isDark, [
          ...goals.map(
            (g) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.purple.shade600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      g,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
        const SizedBox(height: 16),

        // Tips
        _infoSection(
          'Tips Latihan Aman',
          Icons.tips_and_updates_outlined,
          isDark,
          [
            _tipRow(
              'Lakukan peregangan 5 menit sebelum latihan',
              Colors.orange,
            ),
            _tipRow(
              'Berhenti jika terasa pusing atau nyeri berlebih',
              Colors.red,
            ),
            _tipRow('Minum air yang cukup selama sesi latihan', Colors.blue),
            _tipRow('Konsultasikan progres dengan fisioterapis', Colors.teal),
          ],
        ),
      ],
    );
  }

  Widget _statChip(IconData icon, String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _infoSection(
    String title,
    IconData icon,
    bool isDark,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2636) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.purple.shade400, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _tipRow(String text, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lightbulb_outline, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 13, height: 1.4)),
        ),
      ],
    ),
  );
}
