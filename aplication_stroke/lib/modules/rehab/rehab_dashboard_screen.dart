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
  RehabProgress? _progress;
  RehabPhase? _currentPhase;
  List<RehabExercise> _morningExercises = [];
  List<RehabExercise> _afternoonExercises = [];
  List<RehabExercise> _eveningExercises = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _progress = await _rehabService.getUserProgress(_userId);
      if (_progress != null) {
        _currentPhase = await _rehabService.getPhaseDetail(_progress!.currentPhaseId);
        _morningExercises = await _rehabService.getExercises(_progress!.currentPhaseId, 'pagi');
        _afternoonExercises = await _rehabService.getExercises(_progress!.currentPhaseId, 'siang');
        _eveningExercises = await _rehabService.getExercises(_progress!.currentPhaseId, 'sore');
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
            onPressed: () {
              // Logic to start initial phase
            },
            child: const Text('Mulai Program'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildProgressCard(),
        const SizedBox(height: 24),
        _buildExerciseSection('Pagi', _morningExercises, Icons.wb_sunny_outlined, Colors.orange),
        _buildExerciseSection('Siang', _afternoonExercises, Icons.wb_cloudy_outlined, Colors.yellow.shade700),
        _buildExerciseSection('Sore', _eveningExercises, Icons.nights_stay_outlined, Colors.indigo),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.fireplace, color: Colors.orange, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${_progress?.streakCount ?? 0} Hari',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: 0.3, // Dummy progress
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 12),
            const Text(
              'Anda sedang di minggu ke-2 fase ini',
              style: TextStyle(color: Colors.white70, fontSize: 12),
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
