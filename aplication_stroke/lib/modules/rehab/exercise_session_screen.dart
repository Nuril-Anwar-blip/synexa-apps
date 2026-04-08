import '../../../models/rehab_models.dart';
// import '../../../services/remote/rehab_service.dart';

// class ExerciseSessionScreen extends StatefulWidget {
//   final RehabExercise exercise;
//   const ExerciseSessionScreen({super.key, required this.exercise});

//   @override
//   State<ExerciseSessionScreen> createState() => _ExerciseSessionScreenState();
// }

// class _ExerciseSessionScreenState extends State<ExerciseSessionScreen> {
//   final RehabService _rehabService = RehabService();
//   final String _userId = Supabase.instance.client.auth.currentUser?.id ?? '';

//   late int _timeLeft;
//   Timer? _timer;
//   bool _isRunning = false;
//   bool _isFinished = false;

//   @override
//   void initState() {
//     super.initState();
//     _timeLeft = widget.exercise.durationSeconds;
//   }

//   void _toggleTimer() {
//     if (_isRunning) {
//       _stopTimer();
//     } else {
//       _startTimer();
//     }
//   }

//   void _startTimer() {
//     setState(() => _isRunning = true);
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (_timeLeft > 0) {
//         setState(() => _timeLeft--);
//       } else {
//         _finishSession();
//       }
//     });
//   }

//   void _stopTimer() {
//     _timer?.cancel();
//     setState(() => _isRunning = false);
//   }

//   Future<void> _finishSession() async {
//     _stopTimer();
//     setState(() => _isFinished = true);

//     try {
//       await _rehabService.logExerciseCompletion(
//         userId: _userId,
//         exerciseId: widget.exercise.id,
//         durationActualSeconds: widget.exercise.durationSeconds - _timeLeft,
//       );
//     } catch (e) {
//       debugPrint('Error logging completion: $e');
//     }
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.exercise.name),
//         leading: IconButton(
//           icon: const Icon(Icons.close),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(24),
//               child: Column(
//                 children: [
//                   _buildMediaPlaceholder(),
//                   const SizedBox(height: 32),
//                   _buildTimerDisplay(),
//                   const SizedBox(height: 32),
//                   _buildInstructions(),
//                 ],
//               ),
//             ),
//           ),
//           _buildBottomAction(),
//         ],
//       ),
//     );
//   }

//   Widget _buildMediaPlaceholder() {
//     return Container(
//       width: double.infinity,
//       height: 200,
//       decoration: BoxDecoration(
//         color: Colors.grey.shade200,
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: const Icon(Icons.play_circle_fill, size: 64, color: Colors.blue),
//     );
//   }

//   Widget _buildTimerDisplay() {
//     final minutes = (_timeLeft / 60).floor();
//     final seconds = _timeLeft % 60;

//     return Column(
//       children: [
//         Stack(
//           alignment: Alignment.center,
//           children: [
//             SizedBox(
//               width: 180,
//               height: 180,
//               child: CircularProgressIndicator(
//                 value: _timeLeft / widget.exercise.durationSeconds,
//                 strokeWidth: 10,
//                 backgroundColor: Colors.blue.shade50,
//               ),
//             ),
//             Text(
//               '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
//               style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
//             ),
//           ],
//         ),
//         const SizedBox(height: 16),
//         Text(
//           _isRunning ? 'Sedang Berlangsung' : 'Siap Mulai?',
//           style: TextStyle(
//             color: Colors.blue.shade700,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildInstructions() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Instruksi Latihan:',
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 12),
//         ...widget.exercise.instructions
//             .map(
//               (step) => Padding(
//                 padding: const EdgeInsets.only(bottom: 8),
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Icon(
//                       Icons.check_circle,
//                       size: 20,
//                       color: Colors.green,
//                     ),
//                     const SizedBox(width: 8),
//                     Expanded(child: Text(step)),
//                   ],
//                 ),
//               ),
//             )
//             .toList(),
//       ],
//     );
//   }

//   Widget _buildBottomAction() {
//     return SafeArea(
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: SizedBox(
//           width: double.infinity,
//           height: 56,
//           child: ElevatedButton(
//             onPressed: _isFinished
//                 ? () => Navigator.pop(context)
//                 : _toggleTimer,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: _isFinished
//                   ? Colors.green
//                   : (_isRunning ? Colors.red : Colors.blue),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//             ),
//             child: Text(
//               _isFinished
//                   ? 'Selesai'
//                   : (_isRunning ? 'Berhenti Sejenak' : 'Mulai Sekarang'),
//               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// ====================================================================
// File: exercise_session_screen_v2.dart
// Exercise Session — Full theme/lang/font support + improved timer
// Letakkan di: lib/modules/rehab/exercise_session_screen.dart
// ====================================================================

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// Uncomment saat integrasi:
import '../../../models/rehab_models.dart';
import '../../../services/remote/rehab_service.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';

// ── Mock model ─────────────────────────────────────────────────────────────
class MockExercise {
  final String id;
  final String name;
  final List<String> instructions;
  final int durationSeconds;
  final String durationText;
  final String? mediaUrl;

  const MockExercise({
    required this.id,
    required this.name,
    required this.instructions,
    required this.durationSeconds,
    required this.durationText,
    this.mediaUrl,
  });
}

// ── Main Screen ────────────────────────────────────────────────────────────
class ExerciseSessionScreen extends StatefulWidget {
  final MockExercise exercise;
  const ExerciseSessionScreen({super.key, required this.exercise});

  @override
  State<ExerciseSessionScreen> createState() => _ExerciseSessionScreenV2State();
}

class _ExerciseSessionScreenV2State extends State<ExerciseSessionScreen>
    with TickerProviderStateMixin {
  late int _timeLeft;
  late int _totalSeconds;
  bool _isRunning = false;
  bool _isFinished = false;
  bool _isPaused = false;
  int _completedReps = 0;

  Timer? _timer;
  late AnimationController _circleCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _completeCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _completeAnim;

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.exercise.durationSeconds;
    _totalSeconds = widget.exercise.durationSeconds;

    _circleCtrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: _totalSeconds),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _completeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _pulseAnim = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _completeAnim = CurvedAnimation(
      parent: _completeCtrl,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _circleCtrl.dispose();
    _pulseCtrl.dispose();
    _completeCtrl.dispose();
    super.dispose();
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  double get _fs => 1.0;
  String _t(Map<String, String> m) => m['id'] ?? '';

  double get _progress =>
      _totalSeconds == 0 ? 0 : (_totalSeconds - _timeLeft) / _totalSeconds;

  String get _timeStr {
    final m = _timeLeft ~/ 60;
    final s = _timeLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _toggle() {
    HapticFeedback.mediumImpact();
    if (_isRunning) {
      _pause();
    } else {
      _start();
    }
  }

  void _start() {
    setState(() {
      _isRunning = true;
      _isPaused = false;
    });
    _circleCtrl.forward();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        t.cancel();
        _finish();
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    _circleCtrl.stop();
    setState(() {
      _isRunning = false;
      _isPaused = true;
    });
  }

  void _reset() {
    _timer?.cancel();
    _circleCtrl.reset();
    setState(() {
      _timeLeft = _totalSeconds;
      _isRunning = false;
      _isPaused = false;
      _isFinished = false;
    });
  }

  void _finish() {
    HapticFeedback.heavyImpact();
    _pulseCtrl.stop();
    setState(() {
      _isRunning = false;
      _isFinished = true;
      _timeLeft = 0;
    });
    _completeCtrl.forward();

    // Di app nyata: log ke Supabase
    // await rehabService.logExerciseCompletion(...)
  }

  void _abort() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(_t({'id': 'Batalkan Sesi?', 'en': 'Abort Session?'})),
        content: Text(
          _t({
            'id': 'Progress sesi ini tidak akan disimpan',
            'en': 'Session progress will not be saved',
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_t({'id': 'Lanjutkan', 'en': 'Continue'})),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context); // dialog
              Navigator.pop(context); // screen
            },
            child: Text(_t({'id': 'Batalkan', 'en': 'Abort'})),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = _isDark ? const Color(0xFF060B1A) : const Color(0xFFF0F4FF);

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isFinished ? _buildCompleteView() : _buildSessionView(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: _isRunning ? _pause : () => Navigator.pop(context),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.exercise.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18 * _fs,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      widget.exercise.durationText,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isRunning)
                GestureDetector(
                  onTap: _abort,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.withOpacity(0.5)),
                    ),
                    child: Text(
                      _t({'id': 'Hentikan', 'en': 'Stop'}),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Video/image placeholder
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: _isDark ? const Color(0xFF0F1B2E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade400, Colors.teal.shade700],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.4),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Circular timer
          _buildCircularTimer(),
          const SizedBox(height: 32),

          // Instructions
          _buildInstructions(),
          const SizedBox(height: 24),

          // Action buttons
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildCircularTimer() {
    final color = _isRunning
        ? Colors.teal
        : _isPaused
        ? Colors.orange
        : Colors.grey;

    return ScaleTransition(
      scale: _isRunning ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
      child: SizedBox(
        width: 200,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background circle
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.05),
                border: Border.all(color: color.withOpacity(0.15), width: 2),
              ),
            ),
            // Progress arc
            CustomPaint(
              size: const Size(200, 200),
              painter: _ArcPainter(progress: _progress, color: color),
            ),
            // Time display
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _timeStr,
                  style: TextStyle(
                    fontSize: 42 * _fs,
                    fontWeight: FontWeight.w900,
                    color: _isDark ? Colors.white : Colors.black87,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  _isRunning
                      ? _t({'id': 'Sedang Berlangsung', 'en': 'In Progress'})
                      : _isPaused
                      ? _t({'id': 'Dijeda', 'en': 'Paused'})
                      : _t({'id': 'Siap Mulai?', 'en': 'Ready to Start?'}),
                  style: TextStyle(
                    fontSize: 12 * _fs,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF0F1B2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.format_list_bulleted_rounded,
                  color: Colors.teal,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _t({'id': 'Instruksi Latihan', 'en': 'Exercise Instructions'}),
                style: TextStyle(
                  fontSize: 15 * _fs,
                  fontWeight: FontWeight.w800,
                  color: _isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...widget.exercise.instructions.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${e.key + 1}',
                        style: const TextStyle(
                          color: Colors.teal,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      e.value,
                      style: TextStyle(
                        fontSize: 14 * _fs,
                        color: _isDark ? Colors.white70 : Colors.black54,
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
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        if (_isPaused || !_isRunning) ...[
          GestureDetector(
            onTap: _reset,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _isDark ? Colors.white10 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.replay_rounded,
                color: _isDark ? Colors.white54 : Colors.grey.shade600,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: GestureDetector(
            onTap: _toggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isRunning
                      ? [Colors.orange.shade400, Colors.orange.shade700]
                      : [Colors.teal.shade400, Colors.teal.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: (_isRunning ? Colors.orange : Colors.teal)
                        .withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isRunning
                        ? _t({'id': 'Jeda', 'en': 'Pause'})
                        : _isPaused
                        ? _t({'id': 'Lanjutkan', 'en': 'Resume'})
                        : _t({'id': 'Mulai Sekarang', 'en': 'Start Now'}),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16 * _fs,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompleteView() {
    return Center(
      child: ScaleTransition(
        scale: _completeAnim,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.teal.shade500],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 60,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                _t({'id': 'Luar Biasa! 🎉', 'en': 'Excellent! 🎉'}),
                style: TextStyle(
                  fontSize: 28 * _fs,
                  fontWeight: FontWeight.w900,
                  color: _isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.exercise.name,
                style: TextStyle(
                  fontSize: 18 * _fs,
                  fontWeight: FontWeight.w700,
                  color: Colors.teal,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _t({
                  'id': 'Sesi latihan berhasil diselesaikan!',
                  'en': 'Exercise session completed!',
                }),
                style: TextStyle(
                  fontSize: 14 * _fs,
                  color: _isDark ? Colors.white54 : Colors.black45,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CompleteStat(
                    icon: Icons.timer_rounded,
                    value: widget.exercise.durationText,
                    label: _t({'id': 'Durasi', 'en': 'Duration'}),
                    color: Colors.blue,
                    isDark: _isDark,
                    fs: _fs,
                  ),
                  const SizedBox(width: 20),
                  _CompleteStat(
                    icon: Icons.local_fire_department_rounded,
                    value:
                        '~${(widget.exercise.durationSeconds / 60 * 3).round()} kal',
                    label: _t({'id': 'Kalori', 'en': 'Calories'}),
                    color: Colors.orange,
                    isDark: _isDark,
                    fs: _fs,
                  ),
                  const SizedBox(width: 20),
                  _CompleteStat(
                    icon: Icons.star_rounded,
                    value: '+10 XP',
                    label: _t({'id': 'Poin', 'en': 'Points'}),
                    color: Colors.amber,
                    isDark: _isDark,
                    fs: _fs,
                  ),
                ],
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check_circle_rounded, size: 22),
                  label: Text(
                    _t({'id': 'Selesai', 'en': 'Done'}),
                    style: TextStyle(
                      fontSize: 16 * _fs,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompleteStat extends StatelessWidget {
  const _CompleteStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
    required this.fs,
  });
  final IconData icon;
  final String value, label;
  final Color color;
  final bool isDark;
  final double fs;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 14 * fs,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10 * fs,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      ],
    );
  }
}

// ── Arc Painter ────────────────────────────────────────────────────────────
class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _ArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final paint = Paint()
      ..color = color.withOpacity(0.15)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, paint);

    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress || old.color != color;
}
