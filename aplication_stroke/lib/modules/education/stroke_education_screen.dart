import 'package:flutter/material.dart';
import '../../models/education_model.dart';
import '../../services/remote/education_service.dart';

class StrokeEducationScreen extends StatefulWidget {
  const StrokeEducationScreen({super.key});

  @override
  State<StrokeEducationScreen> createState() => _StrokeEducationScreenState();
}

class _StrokeEducationScreenState extends State<StrokeEducationScreen> {
  final EducationService _educationService = EducationService();
  List<EducationContent> _dbContent = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEducation();
  }

  Future<void> _loadEducation() async {
    try {
      final data = await _educationService.getAllEducation();
      if (mounted) {
        setState(() {
          _dbContent = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading education: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edukasi Stroke'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Konten dari Database (Baru)
                if (_dbContent.isNotEmpty) ...[
                  const _SectionHeader('Modul Edukasi Terbaru'),
                  const SizedBox(height: 12),
                  ..._dbContent.map((content) => Column(
                        children: [
                          _SectionCard(
                            title: content.title,
                            icon: Icons.article_rounded,
                            color: Colors.blue,
                            isDark: isDark,
                            children: [
                              if (content.imageUrl != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      content.imageUrl!,
                                      width: double.infinity,
                                      height: 180,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        height: 180,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.image_not_supported),
                                      ),
                                    ),
                                  ),
                                ),
                              _InfoText(content.content),
                              if (content.category != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Chip(
                                      label: Text(
                                        content.category!,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      )),
                  const Divider(height: 32),
                ],

                // 2. Konten Bawaan (Dokumentasi Statis)
                const _SectionHeader('Panduan Dasar Stroke'),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Apa itu Stroke?',
                  icon: Icons.health_and_safety_rounded,
                  color: Colors.red,
                  isDark: isDark,
                  children: [
                    const _InfoText(
                      'Stroke adalah kondisi medis serius yang terjadi ketika aliran darah ke otak terganggu atau terputus.',
                    ),
                    const SizedBox(height: 12),
                    const _Subtitle('Jenis-jenis Stroke:'),
                    const _BulletPoint('Stroke Iskemik: Penyumbatan pembuluh darah'),
                    const _BulletPoint('Stroke Hemoragik: Pecahnya pembuluh darah'),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Tanda dan Gejala (FAST)',
                  icon: Icons.warning_rounded,
                  color: Colors.orange,
                  isDark: isDark,
                  children: [
                    const _FastItem('F', 'Face', 'Wajah mencong/tidak simetris'),
                    const _FastItem('A', 'Arm', 'Lengan melemah/mati rasa'),
                    const _FastItem('S', 'Speech', 'Bicara pelo/cadal'),
                    const _FastItem('T', 'Time', 'Segera panggil bantuan medis'),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Faktor Risiko & Pencegahan',
                  icon: Icons.shield_rounded,
                  color: Colors.green,
                  isDark: isDark,
                  children: [
                    const _BulletPoint('Kontrol Hipertensi & Diabetes'),
                    const _BulletPoint('Pola Makan Sehat & Rendah Garam'),
                    const _BulletPoint('Aktivitas Fisik Teratur'),
                    const _BulletPoint('Hindari Rokok & Alkohol'),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool isDark;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _InfoText extends StatelessWidget {
  final String text;
  const _InfoText(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        height: 1.6,
        color: isDark ? Colors.grey[300] : Colors.grey[700],
      ),
    );
  }
}

class _Subtitle extends StatelessWidget {
  final String text;
  const _Subtitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;
  const _BulletPoint(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FastItem extends StatelessWidget {
  final String letter;
  final String title;
  final String description;

  const _FastItem(this.letter, this.title, this.description);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(8)),
            child: Center(
              child: Text(letter, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
