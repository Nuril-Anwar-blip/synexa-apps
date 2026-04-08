// import 'package:flutter/material.dart';

// import 'package:supabase_flutter/supabase_flutter.dart';

// /// Model untuk Rencana Latihan.
// /// Digunakan untuk mendefinisikan detail setiap jenis latihan pemulihan.
// class ExercisePlan {
//   ExercisePlan({
//     required this.id, // Menambahkan ID unik untuk sinkronisasi database
//     required this.title,
//     required this.focus,
//     required this.durationMinutes,
//     required this.level,
//     required this.description,
//     required this.steps,
//     required this.equipment,
//     this.isCompleted = false,
//   });

//   final String id;
//   final String title;
//   final String focus;
//   final int durationMinutes;
//   final String level;
//   final String description;
//   final List<String> steps;
//   final String equipment;
//   bool isCompleted;
// }

// /// Layar Latihan Pemulihan.
// /// Menampilkan daftar latihan harian dan melacak progres pengguna menggunakan Supabase.
// class ExerciseScreen extends StatefulWidget {
//   const ExerciseScreen({super.key});

//   @override
//   State<ExerciseScreen> createState() => _ExerciseScreenState();
// }

// class _ExerciseScreenState extends State<ExerciseScreen> {
//   final _supabase = Supabase.instance.client;
//   bool _isInitLoading = true;
//   String? _userId;

//   final List<ExercisePlan> _plans = [];

//   @override
//   void initState() {
//     super.initState();
//     _userId = _supabase.auth.currentUser?.id;
//     _initData();
//   }

//   Future<void> _initData() async {
//     if (_userId == null) return;
//     await _loadPhaseAndExercises();
//   }

//   /// Memuat fase pengguna dan daftar latihan dari database.
//   Future<void> _loadPhaseAndExercises() async {
//     try {
//       // 1. Dapatkan fase saat ini
//       final progress = await _supabase
//           .from('rehab_user_progress')
//           .select('current_phase_id')
//           .eq('user_id', _userId!)
//           .maybeSingle();

//       final phaseId = progress?['current_phase_id'] ?? 1;

//       // 2. Dapatkan latihan untuk fase tersebut
//       final exercises = await _supabase
//           .from('rehab_exercises')
//           .select()
//           .eq('phase_id', phaseId)
//           .order('name');

//       if (mounted) {
//         setState(() {
//           _plans.clear();
//           for (var item in (exercises as List)) {
//             final durationSeconds = item['duration_seconds'] as int? ?? 600;
//             final rawInstructions = item['instructions'];
//             final List<String> steps = rawInstructions is List
//                 ? rawInstructions.map((e) => e.toString()).toList()
//                 : [item['duration_text']?.toString() ?? 'Lakukan sesuai petunjuk.'];
//             _plans.add(ExercisePlan(
//               id: item['id'].toString(),
//               title: item['name'] ?? '',
//               focus: 'Fase $phaseId',
//               durationMinutes: (durationSeconds / 60).round(),
//               level: 'Sesuai Fase',
//               description: item['duration_text'] ?? 'Ikuti instruksi latihan.',
//               steps: steps,
//               equipment: 'Tanpa alat',
//               isCompleted: false, // Tracking table missing in schema
//             ));
//           }
//           _isInitLoading = false;
//         });
//       }
//     } catch (e) {
//       debugPrint('Error loading exercises: $e');
//       if (mounted) setState(() => _isInitLoading = false);
//     }
//   }

//   /// Mencatat progres ke rehab_user_progress.
//   Future<void> _updateSupabaseProgress(ExercisePlan plan) async {
//     if (_userId == null) return;
//     try {
//       await _supabase.from('rehab_exercise_logs').insert({
//         'user_id': _userId,
//         'exercise_id': plan.id,
//         'duration_actual_seconds': plan.durationMinutes * 60,
//         'is_aborted': false,
//       });
//     } catch (e) {
//       debugPrint('Error updating progress: $e');
//     }
//   }

//   final List<String> _levels = const ['Semua', 'Ringan', 'Sedang', 'Intens'];
//   String _selectedLevel = 'Semua';

//   List<ExercisePlan> get _visiblePlans {
//     if (_selectedLevel == 'Semua') return _plans;
//     return _plans.where((plan) => plan.level == _selectedLevel).toList();
//   }

//   int get _completedMinutes => _plans
//       .where((plan) => plan.isCompleted)
//       .fold(0, (total, plan) => total + plan.durationMinutes);

//   /// Mengganti status penyelesaian latihan dan menyimpannya ke database.
//   void _toggleCompletion(ExercisePlan plan) {
//     setState(() {
//       plan.isCompleted = !plan.isCompleted;
//     });
//     _updateSupabaseProgress(plan);
//   }

//   void _showSteps(ExercisePlan plan) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
//       ),
//       builder: (_) {
//         return FractionallySizedBox(
//           heightFactor: 0.85,
//           child: SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Center(
//                     child: Container(
//                       width: 36,
//                       height: 4,
//                       decoration: BoxDecoration(
//                         color: Colors.grey[400],
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 14),
//                   Text(
//                     'Langkah ${plan.title}',
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Durasi ±${plan.durationMinutes} menit • ${plan.level}',
//                     style: TextStyle(color: Colors.grey[600]),
//                   ),
//                   const SizedBox(height: 16),
//                   Expanded(
//                     child: ListView.separated(
//                       itemCount: plan.steps.length,
//                       separatorBuilder: (_, __) => const Divider(height: 20),
//                       itemBuilder: (_, index) => ListTile(
//                         leading: CircleAvatar(
//                           backgroundColor: Colors.blue.shade50,
//                           foregroundColor: Colors.blue.shade700,
//                           child: Text('${index + 1}'),
//                         ),
//                         title: Text(plan.steps[index]),
//                       ),
//                     ),
//                   ),
//                   SafeArea(
//                     top: false,
//                     child: SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: () => Navigator.pop(context),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.blue.shade600,
//                         ),
//                         child: const Text('Mengerti, siap latihan'),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildTipsCard() {
//     final tips = [
//       'Awali latihan dengan peregangan 2 menit untuk memanaskan otot.',
//       'Berhenti sejenak jika terasa pusing atau nyeri tajam.',
//       'Catat latihan yang selesai agar tenaga medis dapat memantau progres.',
//     ];

//     return Card(
//       margin: const EdgeInsets.only(top: 16),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       elevation: 0,
//       color: Colors.orange.shade50,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.lightbulb, color: Colors.orange.shade700),
//                 const SizedBox(width: 8),
//                 const Text(
//                   'Tips Fisioterapis',
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             for (final tip in tips)
//               Padding(
//                 padding: const EdgeInsets.only(bottom: 8),
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text('• ', style: TextStyle(fontSize: 16)),
//                     Expanded(
//                       child: Text(
//                         tip,
//                         style: const TextStyle(color: Colors.black87),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Tampilkan indikator loading saat memuat data pertama kali
//     if (_isInitLoading) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     final totalMinutes = _plans.fold<int>(
//       0,
//       (total, plan) => total + plan.durationMinutes,
//     );
//     final completedCount = _plans.where((plan) => plan.isCompleted).length;

//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(title: const Text('Latihan Pemulihan')),
//       body: ListView(
//         padding: EdgeInsets.fromLTRB(
//           16,
//           16,
//           16,
//           MediaQuery.of(context).padding.bottom + 100,
//         ),
//         children: [
//           _ExerciseSummaryCard(
//             completed: completedCount,
//             total: _plans.length,
//             totalMinutes: totalMinutes,
//             completedMinutes: _completedMinutes,
//           ),
//           const SizedBox(height: 16),
//           const Text(
//             'Pilih Tingkat Latihan',
//             style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
//           ),
//           const SizedBox(height: 8),
//           Wrap(
//             spacing: 8,
//             children: _levels
//                 .map(
//                   (level) => ChoiceChip(
//                     label: Text(level),
//                     selected: _selectedLevel == level,
//                     onSelected: (_) => setState(() => _selectedLevel = level),
//                     selectedColor: Colors.blue.shade100,
//                     labelStyle: TextStyle(
//                       color: _selectedLevel == level
//                           ? Colors.blue.shade900
//                           : Colors.black87,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 )
//                 .toList(),
//           ),
//           _buildTipsCard(),
//           const SizedBox(height: 24),
//           const Text(
//             'Rencana Latihan Hari Ini',
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
//           ),
//           const SizedBox(height: 12),
//           if (_visiblePlans.isEmpty)
//             Container(
//               padding: const EdgeInsets.all(24),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(16),
//                 border: Border.all(color: Colors.blueGrey.withOpacity(0.1)),
//               ),
//               child: Column(
//                 children: const [
//                   Icon(Icons.inbox_outlined, size: 36, color: Colors.grey),
//                   SizedBox(height: 12),
//                   Text(
//                     'Belum ada latihan untuk filter ini.',
//                     style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
//                   ),
//                   SizedBox(height: 6),
//                   Text(
//                     'Coba pilih tingkat latihan lain atau konsultasikan dengan fisioterapis Anda.',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(color: Colors.black54),
//                   ),
//                 ],
//               ),
//             )
//           else
//             ..._visiblePlans.map(
//               (plan) => _ExerciseCard(
//                 plan: plan,
//                 onToggle: () => _toggleCompletion(plan),
//                 onShowSteps: () => _showSteps(plan),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

// class _ExerciseSummaryCard extends StatelessWidget {
//   const _ExerciseSummaryCard({
//     required this.completed,
//     required this.total,
//     required this.totalMinutes,
//     required this.completedMinutes,
//   });

//   final int completed;
//   final int total;
//   final int totalMinutes;
//   final int completedMinutes;

//   @override
//   Widget build(BuildContext context) {
//     final progress = total == 0 ? 0.0 : completed / total;

//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(20),
//         gradient: LinearGradient(
//           colors: [Colors.blue.shade600, Colors.blue.shade300],
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.blue.shade200.withOpacity(0.5),
//             blurRadius: 18,
//             offset: const Offset(0, 8),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Progres Mingguan',
//             style: TextStyle(
//               color: Colors.white70,
//               fontSize: 14,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           const SizedBox(height: 6),
//           Text(
//             '$completed dari $total latihan',
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 22,
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//           const SizedBox(height: 10),
//           ClipRRect(
//             borderRadius: BorderRadius.circular(8),
//             child: LinearProgressIndicator(
//               value: progress.clamp(0.0, 1.0),
//               minHeight: 8,
//               backgroundColor: Colors.white24,
//               valueColor: const AlwaysStoppedAnimation(Colors.white),
//             ),
//           ),
//           const SizedBox(height: 14),
//           Row(
//             children: [
//               Expanded(
//                 child: _SummaryItem(
//                   label: 'Target Waktu',
//                   value: '$totalMinutes menit',
//                 ),
//               ),
//               Container(
//                 width: 1,
//                 height: 36,
//                 color: Colors.white.withOpacity(0.4),
//               ),
//               Expanded(
//                 child: _SummaryItem(
//                   label: 'Sudah Dikerjakan',
//                   value: '$completedMinutes menit',
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _SummaryItem extends StatelessWidget {
//   const _SummaryItem({required this.label, required this.value});

//   final String label;
//   final String value;

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(color: Colors.white70, fontSize: 13),
//         ),
//         const SizedBox(height: 6),
//         Text(
//           value,
//           style: const TextStyle(
//             color: Colors.white,
//             fontSize: 16,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _ExerciseCard extends StatelessWidget {
//   const _ExerciseCard({
//     required this.plan,
//     required this.onToggle,
//     required this.onShowSteps,
//   });

//   final ExercisePlan plan;
//   final VoidCallback onToggle;
//   final VoidCallback onShowSteps;

//   @override
//   Widget build(BuildContext context) {
//     final accentColor = plan.isCompleted
//         ? Colors.green.shade600
//         : Colors.blue.shade600;

//     return Card(
//       margin: const EdgeInsets.only(bottom: 16),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
//       elevation: 1.5,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 CircleAvatar(
//                   radius: 26,
//                   backgroundColor: accentColor.withOpacity(0.12),
//                   child: Icon(
//                     plan.isCompleted
//                         ? Icons.check_circle
//                         : Icons.self_improvement_outlined,
//                     color: accentColor,
//                     size: 30,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         plan.title,
//                         style: const TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w700,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         plan.focus,
//                         style: TextStyle(color: Colors.grey.shade600),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 12,
//                     vertical: 6,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.grey.shade100,
//                     borderRadius: BorderRadius.circular(24),
//                   ),
//                   child: Text(
//                     plan.level,
//                     style: const TextStyle(
//                       fontWeight: FontWeight.w600,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Text(
//               plan.description,
//               style: const TextStyle(color: Colors.black87, height: 1.3),
//             ),
//             const SizedBox(height: 12),
//             Wrap(
//               spacing: 8,
//               runSpacing: 8,
//               children: [
//                 _InfoChip(
//                   icon: Icons.timer,
//                   label: '${plan.durationMinutes} mnt',
//                 ),
//                 _InfoChip(
//                   icon: Icons.chair_alt_outlined,
//                   label: plan.equipment,
//                 ),
//               ],
//             ),
//             const SizedBox(height: 14),
//             Row(
//               children: [
//                 Expanded(
//                   child: OutlinedButton.icon(
//                     icon: const Icon(Icons.menu_book_outlined),
//                     label: const Text('Langkah Latihan'),
//                     onPressed: onShowSteps,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     icon: Icon(
//                       plan.isCompleted
//                           ? Icons.refresh_rounded
//                           : Icons.check_circle_rounded,
//                     ),
//                     label: Text(plan.isCompleted ? 'Ulangi' : 'Tandai Selesai'),
//                     onPressed: onToggle,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: accentColor,
//                       foregroundColor: Colors.white,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _InfoChip extends StatelessWidget {
//   const _InfoChip({required this.icon, required this.label});

//   final IconData icon;
//   final String label;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade100,
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 16, color: Colors.grey.shade800),
//           const SizedBox(width: 6),
//           Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
//         ],
//       ),
//     );
//   }
// }

// ====================================================================
// File: exercise_screen_v2.dart
// Exercise Screen — Full theme/lang support + 7-day tracking
// ====================================================================
import 'dart:async';
import 'dart:convert' as dart_convert;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import 'package:shared_preferences/shared_preferences.dart'
    as shared_preferences;

import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import 'package:provider/provider.dart';

// Uncomment when integrated with real app:
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../../providers/theme_provider.dart';
// import '../../providers/language_provider.dart';

// ── Mock providers for standalone preview ──────────────────────────────────
// Remove these when integrating with real app
class _MockThemeProvider {
  bool isDarkMode = false;
  double fontSize = 1.0;
  String fontFamily = 'Poppins';
}

// ── Exercise data model ────────────────────────────────────────────────────
class ExerciseItem {
  final String id;
  final String name;
  final String phase;
  final int durationMinutes;
  final String level;
  final String desc;
  final List<String> steps;
  final String equipment;
  bool isCompleted;

  ExerciseItem({
    required this.id,
    required this.name,
    required this.phase,
    required this.durationMinutes,
    required this.level,
    required this.desc,
    required this.steps,
    required this.equipment,
    this.isCompleted = false,
  });
}

// ── Sample data ────────────────────────────────────────────────────────────
final _sampleExercises = [
  ExerciseItem(
    id: '1',
    name: 'Putar Pergelangan Kaki',
    phase: 'Fase 1',
    durationMinutes: 3,
    level: 'Ringan',
    desc: 'Latihan ringan untuk meningkatkan fleksibilitas sendi',
    steps: [
      'Duduk tegak di kursi',
      'Angkat kaki perlahan',
      'Putar pergelangan kaki searah jarum jam 8 kali',
      'Putar berlawanan jarum jam 8 kali',
      'Ulangi untuk kaki lainnya',
    ],
    equipment: 'Tanpa alat',
  ),
  ExerciseItem(
    id: '2',
    name: 'Meraih Benda di Depan',
    phase: 'Fase 1',
    durationMinutes: 5,
    level: 'Ringan',
    desc: 'Melatih koordinasi tangan dan jangkauan lengan',
    steps: [
      'Duduk tegak',
      'Letakkan benda di depan jangkauan',
      'Raih benda perlahan dengan tangan kanan',
      'Kembalikan ke posisi awal',
      'Ulangi dengan tangan kiri',
    ],
    equipment: 'Benda ringan',
  ),
  ExerciseItem(
    id: '3',
    name: 'Latihan Napas Dalam',
    phase: 'Fase 1',
    durationMinutes: 5,
    level: 'Ringan',
    desc: 'Meningkatkan kapasitas paru dan relaksasi',
    steps: [
      'Duduk atau berbaring nyaman',
      'Tarik napas perlahan lewat hidung 4 detik',
      'Tahan 2 detik',
      'Buang napas perlahan lewat mulut 6 detik',
      'Ulangi 10 kali',
    ],
    equipment: 'Tanpa alat',
  ),
  ExerciseItem(
    id: '4',
    name: 'Genggam dan Lepas',
    phase: 'Fase 1',
    durationMinutes: 4,
    level: 'Sedang',
    desc: 'Melatih kekuatan otot tangan',
    steps: [
      'Pegang bola karet kecil',
      'Genggam kuat selama 3 detik',
      'Lepaskan perlahan',
      'Istirahat 2 detik',
      'Ulangi 15 kali per tangan',
    ],
    equipment: 'Bola karet',
  ),
];

// ── Main Screen ────────────────────────────────────────────────────────────
class ExerciseScreenV2 extends StatefulWidget {
  final bool isPreview;
  const ExerciseScreenV2({super.key, this.isPreview = false});

  @override
  State<ExerciseScreenV2> createState() => _ExerciseScreenV2State();
}

class _ExerciseScreenV2State extends State<ExerciseScreenV2>
    with SingleTickerProviderStateMixin {
  List<ExerciseItem> _exercises = [];
  String _selectedLevel = 'Semua';
  late TabController _tabController;

  // 7-day tracking — weekday index → completed count
  Map<int, int> _weekProgress = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};
  int _streakDays = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _exercises =
        _sampleExercises; // Mutate original memory list, or use shared preferences
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final prefs = await shared_preferences.SharedPreferences.getInstance();
      final savedStreak = prefs.getInt('exercise_streak') ?? 0;
      final savedProgress = prefs.getString('exercise_week_progress') ?? '';

      setState(() {
        _streakDays = savedStreak;
        if (savedProgress.isNotEmpty) {
          final Map<String, dynamic> pt = dart_convert.jsonDecode(
            savedProgress,
          );
          pt.forEach((k, v) {
            _weekProgress[int.parse(k)] = v as int;
          });
        }
      });
    } catch (_) {}
  }

  Future<void> _saveProgress() async {
    try {
      final prefs = await shared_preferences.SharedPreferences.getInstance();
      await prefs.setInt('exercise_streak', _streakDays);
      await prefs.setString(
        'exercise_week_progress',
        dart_convert.jsonEncode(
          _weekProgress.map((k, v) => MapEntry(k.toString(), v)),
        ),
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  double get _fs {
    try {
      return provider.Provider.of<ThemeProvider>(context).fontSize;
    } catch (_) {
      return 1.0;
    }
  }

  LanguageProvider get _lang {
    return provider.Provider.of<LanguageProvider>(context);
  }

  List<ExerciseItem> get _filteredExercises {
    if (_selectedLevel == 'Semua') return _exercises;
    return _exercises.where((e) => e.level == _selectedLevel).toList();
  }

  int get _completedCount => _exercises.where((e) => e.isCompleted).length;
  int get _totalMinutes =>
      _exercises.fold(0, (sum, e) => sum + e.durationMinutes);
  int get _completedMinutes => _exercises
      .where((e) => e.isCompleted)
      .fold(0, (sum, e) => sum + e.durationMinutes);

  void _toggleCompletion(ExerciseItem ex) {
    setState(() {
      ex.isCompleted = !ex.isCompleted;
      // Update week progress for today
      final today = DateTime.now().weekday - 1; // 0=Mon
      _weekProgress[today] = _completedCount;
      if (ex.isCompleted && _completedCount == 1) {
        // Naive streak increment for first completion of the day
        _streakDays += 1;
      } else if (!ex.isCompleted && _completedCount == 0) {
        _streakDays = (_streakDays - 1).clamp(0, 999);
      }
    });
    _saveProgress();
  }

  void _showExerciseDetail(ExerciseItem ex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExerciseDetailSheet(
        exercise: ex,
        isDark: _isDark,
        onStart: () {
          Navigator.pop(context);
          _showTimerDialog(ex);
        },
      ),
    );
  }

  void _showTimerDialog(ExerciseItem ex) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _TimerDialog(
        exercise: ex,
        isDark: _isDark,
        onComplete: () {
          Navigator.pop(context);
          setState(() => ex.isCompleted = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${ex.name} selesai!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = _isDark ? const Color(0xFF060B1A) : const Color(0xFFF0F4FF);

    return Scaffold(
      backgroundColor: bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: _isDark ? const Color(0xFF060B1A) : Colors.white,
            elevation: 0,
            title: Text(
              'Latihan Pemulihan',
              style: TextStyle(
                fontSize: 18 * _fs,
                fontWeight: FontWeight.w800,
                color: _isDark ? Colors.white : Colors.black87,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(background: _buildHeroHeader()),
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.teal,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.teal,
              indicatorWeight: 3,
              labelStyle: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13 * _fs,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.today_rounded, size: 18),
                  text: 'Hari Ini',
                ),
                Tab(
                  icon: Icon(Icons.bar_chart_rounded, size: 18),
                  text: '7 Hari',
                ),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [_buildTodayTab(), _buildWeeklyTab()],
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    final progress = _exercises.isEmpty
        ? 0.0
        : _completedCount / _exercises.length;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDark
              ? [const Color(0xFF003D33), const Color(0xFF060B1A)]
              : [Colors.teal.shade600, Colors.teal.shade300],
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_fire_department_rounded,
                            color: Colors.orangeAccent,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$_streakDays hari streak',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_completedCount dari ${_exercises.length} latihan',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'Target: $_totalMinutes mnt',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const Text(
                          ' · ',
                          style: TextStyle(color: Colors.white30),
                        ),
                        Text(
                          'Selesai: $_completedMinutes mnt',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Progress circle
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 14,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation(
                        progress == 1.0
                            ? Colors.greenAccent
                            : (progress >= 0.5
                                  ? Colors.lightBlueAccent
                                  : Colors.white),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${(progress * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
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

  Widget _buildTodayTab() {
    final card = _isDark ? const Color(0xFF0F1B2E) : Colors.white;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Level filter
        _LevelFilter(
          selected: _selectedLevel,
          isDark: _isDark,
          fs: _fs,
          onChanged: (v) => setState(() => _selectedLevel = v),
        ),
        const SizedBox(height: 12),

        // Tips card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(_isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lightbulb_rounded,
                color: Colors.amber,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tips Fisioterapis',
                      style: TextStyle(
                        fontSize: 13 * _fs,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Awali dengan peregangan 2 menit\n• Berhenti jika pusing atau nyeri tajam\n• Catat latihan yang selesai',
                      style: TextStyle(
                        fontSize: 12 * _fs,
                        color: Colors.amber.shade800,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_filteredExercises.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Tidak ada latihan untuk filter ini',
                style: TextStyle(color: Colors.grey, fontSize: 14 * _fs),
              ),
            ),
          )
        else
          ..._filteredExercises.map(
            (ex) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _ExerciseCard(
                exercise: ex,
                isDark: _isDark,
                fs: _fs,
                onToggle: () => _toggleCompletion(ex),
                onShowDetail: () => _showExerciseDetail(ex),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWeeklyTab() {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final today = DateTime.now().weekday - 1;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      children: [
        // 7-day tracker
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _isDark ? const Color(0xFF0F1B2E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
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
                      color: Colors.teal.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: Colors.teal,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _lang.translate({
                      'id': 'Progress 7 Hari',
                      'en': '7-Day Progress',
                      'ms': 'Kemajuan 7 Hari',
                    }),
                    style: TextStyle(
                      fontSize: 14 * _fs,
                      fontWeight: FontWeight.w800,
                      color: _isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          color: Colors.orange,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$_streakDays Streak',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: List.generate(7, (i) {
                  final done = _weekProgress[i] ?? 0;
                  final isToday = i == today;
                  final hasDone = done > 0;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        children: [
                          Text(
                            _lang.translate({
                              'id': days[i],
                              'en': [
                                'Mon',
                                'Tue',
                                'Wed',
                                'Thu',
                                'Fri',
                                'Sat',
                                'Sun',
                              ][i],
                              'ms': [
                                'ISN',
                                'SEL',
                                'RAB',
                                'KHA',
                                'JUM',
                                'SAB',
                                'AHD',
                              ][i],
                            }),
                            style: TextStyle(
                              fontSize: 10 * _fs,
                              fontWeight: isToday
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: isToday
                                  ? Colors.teal
                                  : (_isDark ? Colors.white54 : Colors.black87),
                            ),
                          ),
                          const SizedBox(height: 6),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 48,
                            decoration: BoxDecoration(
                              color: isToday
                                  ? Colors.teal
                                  : hasDone
                                  ? Colors.teal.withOpacity(0.3)
                                  : (_isDark
                                        ? Colors.white.withOpacity(0.05)
                                        : Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(12),
                              border: isToday
                                  ? Border.all(color: Colors.teal, width: 2)
                                  : null,
                            ),
                            child: Center(
                              child: Icon(
                                hasDone
                                    ? Icons.check_rounded
                                    : isToday
                                    ? Icons.today_rounded
                                    : Icons.circle_outlined,
                                color: isToday
                                    ? Colors.white
                                    : hasDone
                                    ? Colors.teal
                                    : Colors.grey,
                                size: 18,
                              ),
                            ),
                          ),
                          if (done > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '$done',
                                style: TextStyle(
                                  fontSize: 9 * _fs,
                                  color: Colors.teal,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Weekly stats
        Row(
          children: [
            Expanded(
              child: _WeeklyStat(
                icon: Icons.check_circle_rounded,
                color: Colors.green,
                value: '${_weekProgress.values.where((v) => v > 0).length}',
                label: 'Hari Aktif',
                isDark: _isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _WeeklyStat(
                icon: Icons.timer_rounded,
                color: Colors.blue,
                value:
                    '${_weekProgress.values.fold(0, (a, b) => a + b) * 4} mnt',
                label: 'Total Waktu',
                isDark: _isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _WeeklyStat(
                icon: Icons.local_fire_department_rounded,
                color: Colors.orange,
                value: '$_streakDays',
                label: 'Streak',
                isDark: _isDark,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // 7-day auto refresh note
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(_isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.withOpacity(0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Colors.blue,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _lang.translate({
                    'id':
                        'Latihan akan diperbarui otomatis setiap 7 hari berdasarkan progres Anda. Setelah 7 hari selesai, program akan naik ke fase berikutnya.',
                    'en':
                        'Exercises automatically update every 7 days based on progress. After 7 days, the program advances to the next phase.',
                    'ms':
                        'Latihan dikemas kini secara automatik setiap 7 hari berdasarkan kemajuan. Selepas 7 hari, ia maju ke fasa seterusnya.',
                  }),
                  style: TextStyle(
                    fontSize: 12 * _fs,
                    color: _isDark
                        ? Colors.blue.shade300
                        : Colors.blue.shade900,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeeklyStat extends StatelessWidget {
  const _WeeklyStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.isDark,
  });
  final IconData icon;
  final Color color;
  final String value, label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1B2E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Level Filter ───────────────────────────────────────────────────────────
class _LevelFilter extends StatelessWidget {
  const _LevelFilter({
    required this.selected,
    required this.isDark,
    required this.fs,
    required this.onChanged,
  });
  final String selected;
  final bool isDark;
  final double fs;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: ['Semua', 'Ringan', 'Sedang', 'Intens']
            .map(
              (level) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onChanged(level),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected == level
                          ? Colors.teal
                          : (isDark ? Colors.white12 : Colors.white),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected == level
                            ? Colors.teal
                            : (isDark ? Colors.white12 : Colors.grey.shade200),
                      ),
                    ),
                    child: Text(
                      level,
                      style: TextStyle(
                        fontSize: 13 * fs,
                        fontWeight: FontWeight.w700,
                        color: selected == level
                            ? Colors.white
                            : (isDark ? Colors.white54 : Colors.grey.shade600),
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ── Exercise Card ──────────────────────────────────────────────────────────
class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.isDark,
    required this.fs,
    required this.onToggle,
    required this.onShowDetail,
  });
  final ExerciseItem exercise;
  final bool isDark;
  final double fs;
  final VoidCallback onToggle;
  final VoidCallback onShowDetail;

  Color get _levelColor {
    switch (exercise.level) {
      case 'Ringan':
        return Colors.green;
      case 'Sedang':
        return Colors.orange;
      case 'Intens':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = exercise.isCompleted ? Colors.green : Colors.teal;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1B2E) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: exercise.isCompleted
            ? Border.all(color: Colors.green.withOpacity(0.3))
            : null,
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    exercise.isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.self_improvement_rounded,
                    color: accent,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: TextStyle(
                          fontSize: 15 * fs,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                          decoration: exercise.isCompleted
                              ? TextDecoration.none
                              : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        exercise.phase,
                        style: TextStyle(
                          fontSize: 12 * fs,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                // Level badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _levelColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _levelColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    exercise.level,
                    style: TextStyle(
                      fontSize: 11 * fs,
                      fontWeight: FontWeight.w700,
                      color: _levelColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              exercise.desc,
              style: TextStyle(
                fontSize: 13 * fs,
                color: isDark ? Colors.white54 : Colors.black45,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            // Info chips
            Row(
              children: [
                _InfoChip(
                  icon: Icons.timer_outlined,
                  label: '${exercise.durationMinutes} mnt',
                  isDark: isDark,
                  fs: fs,
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.chair_alt_outlined,
                  label: exercise.equipment,
                  isDark: isDark,
                  fs: fs,
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.format_list_numbered_rounded,
                  label: '${exercise.steps.length} langkah',
                  isDark: isDark,
                  fs: fs,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onShowDetail,
                    icon: const Icon(Icons.menu_book_outlined, size: 16),
                    label: Text(
                      'Langkah Latihan',
                      style: TextStyle(fontSize: 12 * fs),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(color: Colors.teal.withOpacity(0.5)),
                      foregroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onToggle,
                    icon: Icon(
                      exercise.isCompleted
                          ? Icons.refresh_rounded
                          : Icons.check_rounded,
                      size: 16,
                    ),
                    label: Text(
                      exercise.isCompleted ? 'Ulangi' : 'Tandai Selesai',
                      style: TextStyle(fontSize: 12 * fs),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      backgroundColor: exercise.isCompleted
                          ? Colors.grey
                          : Colors.teal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.fs,
  });
  final IconData icon;
  final String label;
  final bool isDark;
  final double fs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11 * fs,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Exercise Detail Bottom Sheet ───────────────────────────────────────────
class _ExerciseDetailSheet extends StatelessWidget {
  const _ExerciseDetailSheet({
    required this.exercise,
    required this.isDark,
    required this.onStart,
  });
  final ExerciseItem exercise;
  final bool isDark;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1B2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Video placeholder
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white12 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: Colors.teal,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    exercise.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${exercise.phase} · ${exercise.durationMinutes} menit · ${exercise.level}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Instruksi Latihan:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  ...exercise.steps.asMap().entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${e.key + 1}',
                                style: const TextStyle(
                                  color: Colors.teal,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              e.value,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white70 : Colors.black87,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow_rounded, size: 22),
                label: const Text(
                  'Mulai Sekarang',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Timer Dialog ───────────────────────────────────────────────────────────
class _TimerDialog extends StatefulWidget {
  const _TimerDialog({
    required this.exercise,
    required this.isDark,
    required this.onComplete,
  });
  final ExerciseItem exercise;
  final bool isDark;
  final VoidCallback onComplete;

  @override
  State<_TimerDialog> createState() => _TimerDialogState();
}

class _TimerDialogState extends State<_TimerDialog>
    with SingleTickerProviderStateMixin {
  late int _timeLeft;
  bool _isRunning = false;
  late AnimationController _ctrl;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.exercise.durationMinutes * 60;
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: _timeLeft),
    );
    _progress = Tween<double>(begin: 1, end: 0).animate(_ctrl);
    _ctrl.addListener(() {
      setState(() {
        _timeLeft = ((1 - _ctrl.value) * widget.exercise.durationMinutes * 60)
            .round();
        if (_timeLeft <= 0) {
          _ctrl.stop();
          widget.onComplete();
        }
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      if (_isRunning) {
        _ctrl.stop();
      } else {
        _ctrl.forward();
      }
      _isRunning = !_isRunning;
    });
  }

  String get _timeStr {
    final m = _timeLeft ~/ 60;
    final s = _timeLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF0F1B2E) : Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.exercise.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: widget.isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AnimatedBuilder(
              animation: _progress,
              builder: (_, __) => SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: _progress.value,
                        strokeWidth: 10,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation(Colors.teal),
                      ),
                    ),
                    Text(
                      _timeStr,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: widget.isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _toggle,
                    icon: Icon(
                      _isRunning
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    label: Text(_isRunning ? 'Jeda' : 'Mulai'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
