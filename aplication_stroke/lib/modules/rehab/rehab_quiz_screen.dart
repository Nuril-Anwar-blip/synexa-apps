import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/rehab_models.dart';
import '../../../services/remote/rehab_service.dart';

class RehabQuizScreen extends StatefulWidget {
  final int phaseFrom;
  const RehabQuizScreen({super.key, required this.phaseFrom});

  @override
  State<RehabQuizScreen> createState() => _RehabQuizScreenState();
}

class _RehabQuizScreenState extends State<RehabQuizScreen> {
  final RehabService _rehabService = RehabService();
  final String _userId = Supabase.instance.client.auth.currentUser?.id ?? '';

  List<RehabQuizQuestion> _questions = [];
  bool _isLoading = true;
  int _currentQuestionIndex = 0;
  int _totalScore = 0;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final questions = await _rehabService.getQuizQuestions(widget.phaseFrom);
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading questions: $e');
      setState(() => _isLoading = false);
    }
  }

  void _answerQuestion(int score) {
    setState(() {
      _totalScore += score;
      if (_currentQuestionIndex < _questions.length - 1) {
        _currentQuestionIndex++;
      } else {
        _isFinished = true;
        _submitResult();
      }
    });
  }

  Future<void> _submitResult() async {
    // Skor minimal lulus (asumsi 70% dari skor maksimal)
    // Maks skor per soal = 2 (Bisa Mandiri)
    final maxScore = _questions.length * 2;
    final passed = _totalScore >= (maxScore * 0.7);

    try {
      await _rehabService.submitQuizAttempt(
        userId: _userId,
        phaseFrom: widget.phaseFrom,
        score: _totalScore,
        passed: passed,
      );
    } catch (e) {
      debugPrint('Error submit result: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Evaluasi Fase', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _questions.isEmpty
              ? const Center(child: Text('Tidak ada pertanyaan kuis.'))
              : _isFinished
                  ? _buildResultView()
                  : _buildQuizView(),
    );
  }

  Widget _buildQuizView() {
    final question = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.blue.shade50,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
            minHeight: 8,
          ),
          const SizedBox(height: 12),
          Text(
            'Pertanyaan ${_currentQuestionIndex + 1} dari ${_questions.length}',
            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.shade50.withOpacity(0.5),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              question.questionText,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 48),
          Expanded(
            child: ListView.builder(
              itemCount: question.options.length,
              itemBuilder: (context, index) {
                final option = question.options[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildOptionButton(option),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(QuizOption option) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _answerQuestion(option.score),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue.shade100, width: 2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  option.text,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: Colors.blue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultView() {
    final maxScore = _questions.length * 2;
    final passed = _totalScore >= (maxScore * 0.7);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: passed ? Colors.green.shade50 : Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                passed ? Icons.emoji_events_rounded : Icons.info_outline_rounded,
                size: 64,
                color: passed ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              passed ? 'Luar Biasa!' : 'Terus Semangat!',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              passed
                  ? 'Anda berhasil menyelesaikan fase ini dan siap untuk tantangan baru.'
                  : 'Anda perlu sedikit lebih konsisten lagi agar bisa lanjut ke fase berikutnya.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text('Skor Evaluasi', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(
                    '$_totalScore / $maxScore',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Kembali ke Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
