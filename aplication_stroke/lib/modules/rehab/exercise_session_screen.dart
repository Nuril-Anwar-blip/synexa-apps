import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/rehab_models.dart';
import '../../../services/remote/rehab_service.dart';

class ExerciseSessionScreen extends StatefulWidget {
  final RehabExercise exercise;
  const ExerciseSessionScreen({super.key, required this.exercise});

  @override
  State<ExerciseSessionScreen> createState() => _ExerciseSessionScreenState();
}

class _ExerciseSessionScreenState extends State<ExerciseSessionScreen>
    with TickerProviderStateMixin {
  final RehabService _rehabService = RehabService();
  final String _userId = Supabase.instance.client.auth.currentUser?.id ?? '';

  late int _timeLeft;
  Timer? _timer;
  bool _isRunning = false;
  bool _isFinished = false;
  bool _isPaused = false;

  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.exercise.durationSeconds;
    _setupAnimations();
  }

  void _setupAnimations() {
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.exercise.durationSeconds),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _progressAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.linear),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _toggleTimer() {
    if (_isRunning) {
      _pauseTimer();
    } else if (_isPaused) {
      _resumeTimer();
    } else {
      _startTimer();
    }
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
      _isPaused = false;
    });
    _progressController.forward();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _finishSession();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _progressController.stop();
    setState(() {
      _isRunning = false;
      _isPaused = true;
    });
  }

  void _resumeTimer() {
    setState(() {
      _isRunning = true;
      _isPaused = false;
    });
    _progressController.forward();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _finishSession();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _progressController.stop();
    setState(() {
      _isRunning = false;
      _isPaused = false;
    });
  }

  Future<void> _finishSession() async {
    _stopTimer();
    setState(() {
      _isFinished = true;
      _timeLeft = 0;
    });

    try {
      await _rehabService.logExerciseCompletion(
        userId: _userId,
        exerciseId: widget.exercise.id,
        durationActualSeconds: widget.exercise.durationSeconds - _timeLeft,
      );
    } catch (e) {
      debugPrint('Error logging completion: $e');
    }
  }

  String get _formattedTime {
    final minutes = _timeLeft ~/ 60;
    final seconds = _timeLeft % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get _progress {
    return _timeLeft / widget.exercise.durationSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isFinished ? _buildCompletedView() : _buildExerciseView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (_isRunning || _isPaused) {
                _showExitDialog();
              } else {
                Navigator.pop(context);
              }
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.close, color: Color(0xFF1A1A2E)),
            ),
          ),
          Expanded(
            child: Text(
              widget.exercise.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildExerciseView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTimerCircle(),
        const SizedBox(height: 40),
        _buildExerciseInfo(),
        const SizedBox(height: 40),
        _buildControls(),
      ],
    );
  }

  Widget _buildTimerCircle() {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 250,
              height: 250,
              child: CircularProgressIndicator(
                value: _progress,
                strokeWidth: 12,
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _progress > 0.3 ? const Color(0xFF0A7AC1) : Colors.orange,
                ),
              ),
            ),
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0A7AC1).withValues(alpha: 0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formattedTime,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const Text(
                      'MENIT',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExerciseInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
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
        children: [
          if (widget.exercise.instructions.isNotEmpty) ...[
            Text(
              widget.exercise.instructions.first,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInfoItem(
                icon: Icons.timer_outlined,
                value: '${widget.exercise.durationSeconds ~/ 60}',
                label: 'Menit',
              ),
              Container(height: 40, width: 1, color: const Color(0xFFE5E7EB)),
              _buildInfoItem(
                icon: Icons.access_time,
                value: widget.exercise.timeCategory,
                label: 'Waktu',
              ),
              Container(height: 40, width: 1, color: const Color(0xFFE5E7EB)),
              _buildInfoItem(
                icon: Icons.fitness_center,
                value: widget.exercise.durationText,
                label: 'Durasi',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF0A7AC1), size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isPaused) ...[
            _buildControlButton(
              icon: Icons.refresh,
              label: 'Ulangi',
              onPressed: _resetSession,
              color: const Color(0xFF6B7280),
            ),
            const SizedBox(width: 24),
          ],
          _buildMainButton(),
        ],
      ),
    );
  }

  Widget _buildMainButton() {
    final String label;
    final IconData icon;
    final Color color;

    if (_isRunning) {
      label = 'Jeda';
      icon = Icons.pause;
      color = Colors.orange;
    } else if (_isPaused) {
      label = 'Lanjutkan';
      icon = Icons.play_arrow;
      color = const Color(0xFF0A7AC1);
    } else {
      label = 'Mulai';
      icon = Icons.play_arrow;
      color = const Color(0xFF059669);
    }

    return SizedBox(
      width: 180,
      height: 56,
      child: ElevatedButton(
        onPressed: _toggleTimer,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _resetSession() {
    setState(() {
      _timeLeft = widget.exercise.durationSeconds;
      _isRunning = false;
      _isPaused = false;
      _isFinished = false;
    });
    _progressController.reset();
  }

  Widget _buildCompletedView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF059669).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            size: 100,
            color: Color(0xFF059669),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Latihan Selesai!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Anda telah menyelesaikan ${widget.exercise.name}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0A7AC1),
                side: const BorderSide(color: Color(0xFF0A7AC1)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
              child: const Text('Kembali'),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _resetSession,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A7AC1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
              child: const Text('Ulangi'),
            ),
          ],
        ),
      ],
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar dari Latihan?'),
        content: const Text('Progress Anda tidak akan disimpan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}
