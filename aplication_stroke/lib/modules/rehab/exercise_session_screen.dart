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

class _ExerciseSessionScreenState extends State<ExerciseSessionScreen> {
  final RehabService _rehabService = RehabService();
  final String _userId = Supabase.instance.client.auth.currentUser?.id ?? '';

  late int _timeLeft;
  Timer? _timer;
  bool _isRunning = false;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.exercise.durationSeconds;
  }

  void _toggleTimer() {
    if (_isRunning) {
      _stopTimer();
    } else {
      _startTimer();
    }
  }

  void _startTimer() {
    setState(() => _isRunning = true);
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
    setState(() => _isRunning = false);
  }

  Future<void> _finishSession() async {
    _stopTimer();
    setState(() => _isFinished = true);

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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise.name),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildMediaPlaceholder(),
                  const SizedBox(height: 32),
                  _buildTimerDisplay(),
                  const SizedBox(height: 32),
                  _buildInstructions(),
                ],
              ),
            ),
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildMediaPlaceholder() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Icons.play_circle_fill, size: 64, color: Colors.blue),
    );
  }

  Widget _buildTimerDisplay() {
    final minutes = (_timeLeft / 60).floor();
    final seconds = _timeLeft % 60;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 180,
              height: 180,
              child: CircularProgressIndicator(
                value: _timeLeft / widget.exercise.durationSeconds,
                strokeWidth: 10,
                backgroundColor: Colors.blue.shade50,
              ),
            ),
            Text(
              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _isRunning ? 'Sedang Berlangsung' : 'Siap Mulai?',
          style: TextStyle(
            color: Colors.blue.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Instruksi Latihan:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...widget.exercise.instructions
            .map(
              (step) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 20,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(step)),
                  ],
                ),
              ),
            )
            .toList(),
      ],
    );
  }

  Widget _buildBottomAction() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isFinished
                ? () => Navigator.pop(context)
                : _toggleTimer,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isFinished
                  ? Colors.green
                  : (_isRunning ? Colors.red : Colors.blue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              _isFinished
                  ? 'Selesai'
                  : (_isRunning ? 'Berhenti Sejenak' : 'Mulai Sekarang'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
