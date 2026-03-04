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
        _progress = null;
        _exercises = [];
      } else {
        _progress = await _rehabService.getUserProgress(_userId);
        if (_progress != null) {
          _currentPhase =
              await _rehabService.getPhaseDetail(_progress!.currentPhaseId);
          _exercises =
              await _rehabService.getExercises(_progress!.currentPhaseId);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Program Rehabilitasi'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _progress == null
              ? _buildEmptyState()
              : _buildDashboard(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.fitness_center, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Belum ada program aktif.'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _startInitialProgram,
            child: const Text('Mulai Program'),
          ),
        ],
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
      await Supabase.instance.client.from('rehab_user_progress').upsert(
        {
          'user_id': _userId,
          'current_phase_id': 1,
          'phase_started_at': DateTime.now().toIso8601String(),
          'streak_count': 0,
        },
        onConflict: 'user_id',
      );
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Program fase 1 dimulai.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memulai program: $e')),
      );
    }
  }

  Widget _buildDashboard() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildProgressCard(),
        const SizedBox(height: 24),
        _buildExerciseSection('Latihan Hari Ini', _exercises, Icons.fitness_center, Colors.blue),
      ],
    );
  }

  Widget _buildProgressCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.blue.shade400],
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fase Saat Ini',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      _currentPhase?.name ?? '...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Streak count removed as not in schema
              ],
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: 0.1, // Fixed dummy for now
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseSection(String title, List<RehabExercise> exercises, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (exercises.isEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 32, bottom: 16),
            child: Text('Tidak ada latihan.', style: TextStyle(color: Colors.grey)),
          )
        else
          ...exercises.map((e) => _buildExerciseCard(e)).toList(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildExerciseCard(RehabExercise exercise) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.play_arrow, color: Colors.blue),
        ),
        title: Text(exercise.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(exercise.durationText),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ExerciseSessionScreen(exercise: exercise),
            ),
          );
        },
      ),
    );
  }
}
