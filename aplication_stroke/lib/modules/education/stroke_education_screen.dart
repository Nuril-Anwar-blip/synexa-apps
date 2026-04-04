// import 'package:flutter/material.dart';
// import '../../models/education_model.dart';
// import '../../services/remote/education_service.dart';

// class StrokeEducationScreen extends StatefulWidget {
//   const StrokeEducationScreen({super.key});

//   @override
//   State<StrokeEducationScreen> createState() => _StrokeEducationScreenState();
// }

// class _StrokeEducationScreenState extends State<StrokeEducationScreen> {
//   final EducationService _educationService = EducationService();
//   List<EducationContent> _dbContent = [];
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadEducation();
//   }

//   Future<void> _loadEducation() async {
//     try {
//       final data = await _educationService.getAllEducation();
//       if (mounted) {
//         setState(() {
//           _dbContent = data;
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       debugPrint('Error loading education: $e');
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final isDark = theme.brightness == Brightness.dark;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Edukasi Stroke'),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : ListView(
//               padding: const EdgeInsets.all(16),
//               children: [
//                 // 1. Konten dari Database (Baru)
//                 if (_dbContent.isNotEmpty) ...[
//                   const _SectionHeader('Modul Edukasi Terbaru'),
//                   const SizedBox(height: 12),
//                   ..._dbContent.map((content) => Column(
//                         children: [
//                           _SectionCard(
//                             title: content.title,
//                             icon: Icons.article_rounded,
//                             color: Colors.blue,
//                             isDark: isDark,
//                             children: [
//                               if (content.imageUrl != null)
//                                 Padding(
//                                   padding: const EdgeInsets.only(bottom: 12),
//                                   child: ClipRRect(
//                                     borderRadius: BorderRadius.circular(12),
//                                     child: Image.network(
//                                       content.imageUrl!,
//                                       width: double.infinity,
//                                       height: 180,
//                                       fit: BoxFit.cover,
//                                       errorBuilder: (_, __, ___) => Container(
//                                         height: 180,
//                                         color: Colors.grey[300],
//                                         child: const Icon(Icons.image_not_supported),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               _InfoText(content.content),
//                               if (content.category != null)
//                                 Padding(
//                                   padding: const EdgeInsets.only(top: 8),
//                                   child: Align(
//                                     alignment: Alignment.centerRight,
//                                     child: Chip(
//                                       label: Text(
//                                         content.category!,
//                                         style: const TextStyle(fontSize: 10),
//                                       ),
//                                       padding: EdgeInsets.zero,
//                                     ),
//                                   ),
//                                 ),
//                             ],
//                           ),
//                           const SizedBox(height: 16),
//                         ],
//                       )),
//                   const Divider(height: 32),
//                 ],

//                 // 2. Konten Bawaan (Dokumentasi Statis)
//                 const _SectionHeader('Panduan Dasar Stroke'),
//                 const SizedBox(height: 12),
//                 _SectionCard(
//                   title: 'Apa itu Stroke?',
//                   icon: Icons.health_and_safety_rounded,
//                   color: Colors.red,
//                   isDark: isDark,
//                   children: [
//                     const _InfoText(
//                       'Stroke adalah kondisi medis serius yang terjadi ketika aliran darah ke otak terganggu atau terputus.',
//                     ),
//                     const SizedBox(height: 12),
//                     const _Subtitle('Jenis-jenis Stroke:'),
//                     const _BulletPoint('Stroke Iskemik: Penyumbatan pembuluh darah'),
//                     const _BulletPoint('Stroke Hemoragik: Pecahnya pembuluh darah'),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//                 _SectionCard(
//                   title: 'Tanda dan Gejala (FAST)',
//                   icon: Icons.warning_rounded,
//                   color: Colors.orange,
//                   isDark: isDark,
//                   children: [
//                     const _FastItem('F', 'Face', 'Wajah mencong/tidak simetris'),
//                     const _FastItem('A', 'Arm', 'Lengan melemah/mati rasa'),
//                     const _FastItem('S', 'Speech', 'Bicara pelo/cadal'),
//                     const _FastItem('T', 'Time', 'Segera panggil bantuan medis'),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//                 _SectionCard(
//                   title: 'Faktor Risiko & Pencegahan',
//                   icon: Icons.shield_rounded,
//                   color: Colors.green,
//                   isDark: isDark,
//                   children: [
//                     const _BulletPoint('Kontrol Hipertensi & Diabetes'),
//                     const _BulletPoint('Pola Makan Sehat & Rendah Garam'),
//                     const _BulletPoint('Aktivitas Fisik Teratur'),
//                     const _BulletPoint('Hindari Rokok & Alkohol'),
//                   ],
//                 ),
//                 SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
//               ],
//             ),
//     );
//   }
// }

// class _SectionHeader extends StatelessWidget {
//   final String title;
//   const _SectionHeader(this.title);

//   @override
//   Widget build(BuildContext context) {
//     return Text(
//       title,
//       style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
//     );
//   }
// }

// class _SectionCard extends StatelessWidget {
//   final String title;
//   final IconData icon;
//   final Color color;
//   final bool isDark;
//   final List<Widget> children;

//   const _SectionCard({
//     required this.title,
//     required this.icon,
//     required this.color,
//     required this.isDark,
//     required this.children,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: isDark ? Colors.grey[800] : Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(icon, color: color, size: 24),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Text(
//                   title,
//                   style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           ...children,
//         ],
//       ),
//     );
//   }
// }

// class _InfoText extends StatelessWidget {
//   final String text;
//   const _InfoText(this.text);

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     return Text(
//       text,
//       style: TextStyle(
//         fontSize: 14,
//         height: 1.6,
//         color: isDark ? Colors.grey[300] : Colors.grey[700],
//       ),
//     );
//   }
// }

// class _Subtitle extends StatelessWidget {
//   final String text;
//   const _Subtitle(this.text);

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Text(
//         text,
//         style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
//       ),
//     );
//   }
// }

// class _BulletPoint extends StatelessWidget {
//   final String text;
//   const _BulletPoint(this.text);

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 4),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text('• '),
//           Expanded(
//             child: Text(
//               text,
//               style: TextStyle(
//                 fontSize: 14,
//                 color: isDark ? Colors.grey[300] : Colors.grey[700],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _FastItem extends StatelessWidget {
//   final String letter;
//   final String title;
//   final String description;

//   const _FastItem(this.letter, this.title, this.description);

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Row(
//         children: [
//           Container(
//             width: 32,
//             height: 32,
//             decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(8)),
//             child: Center(
//               child: Text(letter, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
//                 Text(description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// ====================================================================
// File: stroke_education_screen.dart — Enhanced UI + More Content
// ====================================================================

import 'package:flutter/material.dart';
import '../../models/education_model.dart';
import '../../services/remote/education_service.dart';

class StrokeEducationScreen extends StatefulWidget {
  const StrokeEducationScreen({super.key});

  @override
  State<StrokeEducationScreen> createState() => _StrokeEducationScreenState();
}

class _StrokeEducationScreenState extends State<StrokeEducationScreen>
    with SingleTickerProviderStateMixin {
  final EducationService _educationService = EducationService();
  List<EducationContent> _dbContent = [];
  bool _isLoading = true;
  late TabController _tabController;
  int _expandedIndex = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadEducation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEducation() async {
    try {
      final data = await _educationService.getAllEducation();
      if (mounted)
        setState(() {
          _dbContent = data;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F1923)
          : const Color(0xFFF4F7FB),
      body: _isLoading ? _loading() : _buildBody(isDark),
    );
  }

  Widget _loading() => const Scaffold(
    body: Center(child: CircularProgressIndicator(color: Colors.red)),
  );

  Widget _buildBody(bool isDark) {
    return NestedScrollView(
      headerSliverBuilder: (_, __) => [
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: isDark ? const Color(0xFF0F1923) : Colors.white,
          flexibleSpace: FlexibleSpaceBar(background: _heroHeader()),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.red.shade600,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.red.shade600,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            tabs: const [
              Tab(text: '🧠 Dasar Stroke'),
              Tab(text: '⚠️ Gejala & Tanda'),
              Tab(text: '🛡️ Pencegahan'),
              Tab(text: '🔄 Pemulihan'),
            ],
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          _basicStrokeTab(isDark),
          _symptomsTab(isDark),
          _preventionTab(isDark),
          _recoveryTab(isDark),
        ],
      ),
    );
  }

  Widget _heroHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB71C1C), Color(0xFFE53935), Color(0xFFFF5252)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.health_and_safety_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edukasi Stroke',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Kenali, Cegah, dan Pulih dari Stroke',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _statPill('87%', 'Bisa\nDicegah'),
                  const SizedBox(width: 8),
                  _statPill('4 Jam', 'Golden\nPeriod'),
                  const SizedBox(width: 8),
                  _statPill('Ke-2', 'Penyebab\nKematian'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statPill(String value, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 10,
              height: 1.3,
            ),
          ),
        ],
      ),
    ),
  );

  // ── Tab 1: Dasar Stroke ────────────────────────────────────────────────────
  Widget _basicStrokeTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_dbContent.isNotEmpty) ...[
          _sectionTitle('📚 Modul Terbaru', isDark),
          const SizedBox(height: 8),
          ..._dbContent.map((c) => _dbContentCard(c, isDark)),
          const SizedBox(height: 8),
        ],
        _sectionTitle('🧠 Apa itu Stroke?', isDark),
        const SizedBox(height: 8),
        _infoCard(
          'Definisi Stroke',
          Icons.psychology_outlined,
          Colors.red,
          isDark,
          'Stroke adalah kondisi medis serius yang terjadi ketika suplai darah ke otak terganggu — baik karena penyumbatan (iskemik) maupun pecahnya pembuluh darah (hemoragik). Sel otak mulai mati dalam hitungan menit tanpa suplai darah yang cukup.',
          null,
        ),
        const SizedBox(height: 12),
        _twoColCards(isDark, [
          _MiniCard(
            'Stroke Iskemik',
            '80%',
            'Penyumbatan pembuluh darah oleh bekuan darah atau plak',
            Colors.orange,
            Icons.block_outlined,
          ),
          _MiniCard(
            'Stroke Hemoragik',
            '20%',
            'Pecahnya pembuluh darah di otak — lebih berbahaya',
            Colors.red,
            Icons.water_drop_outlined,
          ),
        ]),
        const SizedBox(height: 12),
        _infoCard(
          'TIA (Mini Stroke)',
          Icons.warning_amber_rounded,
          Colors.amber,
          isDark,
          'Transient Ischemic Attack (TIA) adalah peringatan dini stroke — gejala stroke sementara yang hilang dalam 24 jam. JANGAN ABAIKAN! 10–15% penderita TIA mengalami stroke penuh dalam 3 bulan.',
          [
            'Gejala seperti stroke tapi hilang sendiri',
            'Tanda peringatan sangat serius',
            'Butuh penanganan segera ke dokter',
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Tab 2: Gejala & Tanda ─────────────────────────────────────────────────
  Widget _symptomsTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _fastSection(isDark),
        const SizedBox(height: 16),
        _sectionTitle('Gejala Lainnya yang Harus Diwaspadai', isDark),
        const SizedBox(height: 8),
        _symptomsList(isDark),
        const SizedBox(height: 12),
        _infoCard(
          'Apa yang Harus Dilakukan?',
          Icons.emergency_rounded,
          Colors.red,
          isDark,
          'Jika Anda atau seseorang menunjukkan tanda-tanda stroke, SEGERA hubungi 119 atau bawa ke IGD rumah sakit terdekat. JANGAN menunggu gejala membaik sendiri.',
          [
            'Catat waktu pertama gejala muncul',
            'Hubungi 119 atau antar ke IGD',
            'JANGAN beri makan/minum',
            'JANGAN beri aspirin tanpa resep dokter',
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _fastSection(bool isDark) {
    final items = [
      _FastItem(
        'F',
        'Face (Wajah)',
        'Minta senyum — apakah wajah tampak mencong atau tidak simetris?',
        Colors.red,
      ),
      _FastItem(
        'A',
        'Arm (Lengan)',
        'Angkat kedua tangan — apakah salah satu melemah atau jatuh sendiri?',
        Colors.orange,
      ),
      _FastItem(
        'S',
        'Speech (Bicara)',
        'Minta ulangi kalimat — apakah bicara pelo, lambat, atau tidak nyambung?',
        Colors.blue,
      ),
      _FastItem(
        'T',
        'Time (Waktu)',
        'Jika ada salah satu tanda di atas — SEGERA panggil bantuan medis!',
        Colors.green,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Metode FAST — Kenali Stroke dalam Hitungan Detik',
          isDark,
        ),
        const SizedBox(height: 8),
        ...items.map((f) => _fastCard(f, isDark)),
      ],
    );
  }

  Widget _fastCard(_FastItem item, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2636) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: item.color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: item.color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [item.color.shade300, item.color.shade600],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                item.letter,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
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
                  item.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: item.color.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _symptomsList(bool isDark) {
    final symptoms = [
      (
        'Mati rasa mendadak',
        'Pada wajah, lengan, atau kaki — terutama di satu sisi tubuh',
        Icons.sentiment_very_dissatisfied_rounded,
        Colors.purple,
      ),
      (
        'Kebingungan mendadak',
        'Sulit memahami pembicaraan orang lain secara tiba-tiba',
        Icons.psychology_rounded,
        Colors.blue,
      ),
      (
        'Gangguan penglihatan',
        'Penglihatan kabur atau ganda pada satu/kedua mata',
        Icons.visibility_off_rounded,
        Colors.teal,
      ),
      (
        'Sakit kepala hebat',
        'Sakit kepala terburuk yang pernah dirasakan — tanpa sebab jelas',
        Icons.sick_rounded,
        Colors.orange,
      ),
      (
        'Kehilangan keseimbangan',
        'Tiba-tiba sulit berjalan, pusing, atau kehilangan koordinasi',
        Icons.directions_walk_rounded,
        Colors.red,
      ),
    ];
    return Column(
      children: symptoms
          .map(
            (s) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A2636) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: s.$4.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: s.$4.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(s.$3, color: s.$4, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.$1,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.$2,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  // ── Tab 3: Pencegahan ──────────────────────────────────────────────────────
  Widget _preventionTab(bool isDark) {
    final riskFactors = [
      ('Hipertensi (Tekanan darah tinggi)', '🩺', Colors.red, true),
      ('Diabetes Melitus', '🩸', Colors.orange, true),
      ('Kolesterol tinggi', '🫀', Colors.amber, true),
      ('Merokok', '🚭', Colors.brown, true),
      ('Obesitas / Kegemukan', '⚖️', Colors.purple, true),
      ('Atrial Fibrilasi (aritmia)', '💓', Colors.pink, true),
      ('Riwayat keluarga stroke', '🧬', Colors.blue, false),
      ('Usia > 55 tahun', '👴', Colors.teal, false),
    ];

    final preventions = [
      (
        'Kontrol tekanan darah',
        'Targetkan < 130/80 mmHg. Kurangi garam, kelola stres.',
        Icons.monitor_heart_rounded,
        Colors.red,
      ),
      (
        'Pola makan sehat',
        'Perbanyak sayur, buah, biji-bijian. Kurangi lemak jenuh dan gula.',
        Icons.restaurant_rounded,
        Colors.green,
      ),
      (
        'Olahraga rutin',
        'Minimal 150 menit/minggu aktivitas aerobik seperti jalan cepat, berenang.',
        Icons.directions_run_rounded,
        Colors.blue,
      ),
      (
        'Berhenti merokok',
        'Risiko stroke turun drastis dalam 2–5 tahun setelah berhenti merokok.',
        Icons.smoke_free_rounded,
        Colors.orange,
      ),
      (
        'Batasi alkohol',
        'Konsumsi alkohol berlebihan meningkatkan risiko stroke hemoragik.',
        Icons.no_drinks_rounded,
        Colors.purple,
      ),
      (
        'Kelola stres',
        'Stres kronik meningkatkan tekanan darah. Meditasi, yoga, dan relaksasi membantu.',
        Icons.self_improvement_rounded,
        Colors.teal,
      ),
      (
        'Kontrol gula darah',
        'Diabetes yang tidak terkontrol 2× lipat meningkatkan risiko stroke.',
        Icons.bloodtype_rounded,
        Colors.amber,
      ),
      (
        'Rutin cek kesehatan',
        'Periksa tekanan darah, kolesterol, dan gula darah minimal 1× setahun.',
        Icons.local_hospital_rounded,
        Colors.indigo,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('⚠️ Faktor Risiko Stroke', isDark),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A2636) : Colors.white,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Bisa diubah',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Tidak bisa diubah',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: riskFactors
                    .map(
                      (r) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: r.$3.withOpacity(r.$4 ? 0.1 : 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: r.$3.withOpacity(r.$4 ? 0.3 : 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(r.$2, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              r.$1,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: r.$3.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionTitle('🛡️ Cara Mencegah Stroke', isDark),
        const SizedBox(height: 8),
        ...preventions.asMap().entries.map((e) {
          final i = e.key;
          final p = e.value;
          final expanded = _expandedIndex == i + 100;
          return GestureDetector(
            onTap: () =>
                setState(() => _expandedIndex = expanded ? -1 : i + 100),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A2636) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: expanded ? p.$4.withOpacity(0.4) : Colors.transparent,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
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
                          color: p.$4.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(p.$3, color: p.$4, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          p.$1,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      Icon(
                        expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                  if (expanded) ...[
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(left: 46),
                      child: Text(
                        p.$2,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Colors.black54,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Tab 4: Pemulihan ───────────────────────────────────────────────────────
  Widget _recoveryTab(bool isDark) {
    final phases = [
      (
        'Fase Akut (0–7 hari)',
        'Stabilisasi kondisi medis di ICU/ruang rawat. Pencegahan komplikasi seperti pneumonia dan luka tekan.',
        Colors.red,
        Icons.local_hospital_rounded,
      ),
      (
        'Fase Subakut (7 hari – 3 bulan)',
        'Rehabilitasi intensif: fisioterapi, terapi wicara, terapi okupasi. Periode emas untuk pemulihan fungsi.',
        Colors.orange,
        Icons.healing_rounded,
      ),
      (
        'Fase Kronis (> 3 bulan)',
        'Pemeliharaan fungsi dan adaptasi gaya hidup. Integrasi kembali ke aktivitas sosial dan pekerjaan.',
        Colors.green,
        Icons.trending_up_rounded,
      ),
    ];

    final recoveryTips = [
      (
        'Fisioterapi rutin',
        'Latihan gerak untuk memulihkan kekuatan dan koordinasi tubuh',
        Icons.fitness_center_rounded,
        Colors.blue,
      ),
      (
        'Terapi Wicara',
        'Bagi yang mengalami gangguan bicara dan menelan',
        Icons.record_voice_over_rounded,
        Colors.purple,
      ),
      (
        'Terapi Okupasi',
        'Melatih aktivitas sehari-hari: makan, berpakaian, menulis',
        Icons.handyman_rounded,
        Colors.teal,
      ),
      (
        'Dukungan Psikologis',
        'Depresi pascastroke sangat umum — konseling membantu pemulihan mental',
        Icons.psychology_rounded,
        Colors.pink,
      ),
      (
        'Nutrisi yang Baik',
        'Diet seimbang membantu regenerasi sel otak dan mencegah stroke ulang',
        Icons.restaurant_rounded,
        Colors.green,
      ),
      (
        'Kontrol rutin ke dokter',
        'Pemantauan faktor risiko dan penyesuaian obat secara berkala',
        Icons.medical_services_rounded,
        Colors.red,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('Fase Pemulihan Stroke', isDark),
        const SizedBox(height: 8),
        ...phases.map(
          (p) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A2636) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: p.$3.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: p.$3.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [p.$3.shade300, p.$3.shade600],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(p.$4, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.$1,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: p.$3.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p.$2,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.teal.shade50],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.lightbulb_rounded,
                color: Colors.amber,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Pemulihan stroke bisa berlangsung bertahun-tahun. Konsistensi latihan dan dukungan keluarga adalah kunci utama keberhasilan.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue.shade800,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionTitle('Tips Pemulihan yang Efektif', isDark),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.3,
          children: recoveryTips
              .map(
                (t) => Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A2636) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: t.$4.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: t.$4.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(t.$3, color: t.$4, size: 20),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t.$1,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        t.$2,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        _infoCard(
          'Kapan Hasil Maksimal Tercapai?',
          Icons.timeline_rounded,
          Colors.indigo,
          isDark,
          'Sebagian besar pemulihan terjadi dalam 6 bulan pertama, namun otak terus beradaptasi (neuroplastisitas) hingga bertahun-tahun. Jangan menyerah!',
          [
            '6 bulan pertama: pemulihan paling cepat',
            'Hingga 2 tahun: masih ada potensi pemulihan',
            'Seumur hidup: adaptasi dan kompensasi terus terjadi',
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // ── Helper Widgets ─────────────────────────────────────────────────────────
  Widget _sectionTitle(String title, bool isDark) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: isDark ? Colors.white : Colors.black87,
      ),
    ),
  );

  Widget _infoCard(
    String title,
    IconData icon,
    Color color,
    bool isDark,
    String body,
    List<String>? points,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2636) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
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
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.black54,
              height: 1.6,
            ),
          ),
          if (points != null) ...[
            const SizedBox(height: 10),
            ...points.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
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
                        p,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : Colors.black54,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _twoColCards(bool isDark, List<_MiniCard> cards) {
    return Row(
      children: cards
          .map(
            (c) => Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  left: c == cards.last ? 6 : 0,
                  right: c == cards.first ? 6 : 0,
                ),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A2636) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: c.color.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(c.icon, color: c.color, size: 22),
                    const SizedBox(height: 6),
                    Text(
                      c.value,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: c.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      c.title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      c.desc,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _dbContentCard(EducationContent content, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2636) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (content.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                content.imageUrl!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          if (content.imageUrl != null) const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.article_rounded,
                  color: Colors.blue,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  content.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              if (content.category != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    content.category!,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content.content,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.black54,
              height: 1.5,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Data classes ─────────────────────────────────────────────────────────────
class _FastItem {
  final String letter;
  final String title;
  final String description;
  final MaterialColor color;
  const _FastItem(this.letter, this.title, this.description, this.color);
}

class _MiniCard {
  final String title;
  final String value;
  final String desc;
  final MaterialColor color;
  final IconData icon;
  const _MiniCard(this.title, this.value, this.desc, this.color, this.icon);
}
