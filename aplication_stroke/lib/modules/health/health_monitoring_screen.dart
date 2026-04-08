// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../../../models/health_log_model.dart';
// import '../../../services/remote/health_service.dart';

// class HealthMonitoringScreen extends StatefulWidget {
//   const HealthMonitoringScreen({super.key});

//   @override
//   State<HealthMonitoringScreen> createState() => _HealthMonitoringScreenState();
// }

// class _HealthMonitoringScreenState extends State<HealthMonitoringScreen> {
//   final HealthService _healthService = HealthService();
//   final String _userId = Supabase.instance.client.auth.currentUser?.id ?? '';

//   bool _isLoading = true;
//   List<HealthLog> _bpLogs = [];
//   List<HealthLog> _bsLogs = [];
//   List<HealthLog> _weightLogs = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadAllLogs();
//   }

//   Future<void> _loadAllLogs() async {
//     setState(() => _isLoading = true);
//     try {
//       _bpLogs = await _healthService.getHealthLogs(_userId, 'blood_pressure');
//       _bsLogs = await _healthService.getHealthLogs(_userId, 'blood_sugar');
//       _weightLogs = await _healthService.getHealthLogs(_userId, 'weight');
//     } catch (e) {
//       debugPrint('Error loading health logs: $e');
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   void _showAddLogSheet(String type) {
//     final systolicController = TextEditingController();
//     final diastolicController = TextEditingController();
//     final valueController = TextEditingController();
//     final noteController = TextEditingController();

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
//       builder: (_) => Container(
//         padding: EdgeInsets.only(
//           top: 24,
//           left: 24,
//           right: 24,
//           bottom: MediaQuery.of(context).viewInsets.bottom + 24,
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Tambah Data ${type == 'blood_pressure' ? 'Tensi' : (type == 'blood_sugar' ? 'Gula Darah' : 'Berat Badan')}',
//               style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 16),
//             if (type == 'blood_pressure') ...[
//               Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: systolicController,
//                       decoration: const InputDecoration(labelText: 'Sistolik (mmHg)', border: OutlineInputBorder()),
//                       keyboardType: TextInputType.number,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: TextField(
//                       controller: diastolicController,
//                       decoration: const InputDecoration(labelText: 'Diastolik (mmHg)', border: OutlineInputBorder()),
//                       keyboardType: TextInputType.number,
//                     ),
//                   ),
//                 ],
//               ),
//             ] else ...[
//               TextField(
//                 controller: valueController,
//                 decoration: InputDecoration(
//                   labelText: type == 'blood_sugar' ? 'Kadar (mg/dL)' : 'Berat (kg)',
//                   border: const OutlineInputBorder(),
//                 ),
//                 keyboardType: TextInputType.number,
//               ),
//             ],
//             const SizedBox(height: 12),
//             TextField(
//               controller: noteController,
//               decoration: const InputDecoration(labelText: 'Catatan (Opsional)', border: OutlineInputBorder()),
//             ),
//             const SizedBox(height: 20),
//             SizedBox(
//               width: double.infinity,
//               height: 50,
//               child: ElevatedButton(
//                 onPressed: () async {
//                   final log = HealthLog(
//                     userId: _userId,
//                     logType: type,
//                     valueSystolic: int.tryParse(systolicController.text),
//                     valueDiastolic: int.tryParse(diastolicController.text),
//                     valueNumeric: double.tryParse(valueController.text),
//                     note: noteController.text,
//                     recordedAt: DateTime.now(),
//                   );
//                   await _healthService.saveHealthLog(log);
//                   Navigator.pop(context);
//                   _loadAllLogs();
//                 },
//                 child: const Text('Simpan Data'),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Monitoring Kesehatan')),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : RefreshIndicator(
//               onRefresh: _loadAllLogs,
//               child: ListView(
//                 padding: const EdgeInsets.all(16),
//                 children: [
//                   _buildHealthCard('Tekanan Darah', _bpLogs.isNotEmpty ? '${_bpLogs.first.valueSystolic}/${_bpLogs.first.valueDiastolic}' : '—', 'mmHg', Colors.red, () => _showAddLogSheet('blood_pressure')),
//                   const SizedBox(height: 16),
//                   _buildHealthCard('Gula Darah', _bsLogs.isNotEmpty ? '${_bsLogs.first.valueNumeric}' : '—', 'mg/dL', Colors.orange, () => _showAddLogSheet('blood_sugar')),
//                   const SizedBox(height: 16),
//                   _buildHealthCard('Berat Badan', _weightLogs.isNotEmpty ? '${_weightLogs.first.valueNumeric}' : '—', 'kg', Colors.blue, () => _showAddLogSheet('weight')),
//                   const SizedBox(height: 32),
//                   const Text('Grafik Progres (Segera Hadir)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//                   const SizedBox(height: 16),
//                   _buildChartPlaceholder(),
//                 ],
//               ),
//             ),
//     );
//   }

//   Widget _buildHealthCard(String title, String value, String unit, Color color, VoidCallback onTap) {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(16),
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
//                   const SizedBox(height: 8),
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.baseline,
//                     textBaseline: TextBaseline.alphabetic,
//                     children: [
//                       Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
//                       const SizedBox(width: 4),
//                       Text(unit, style: const TextStyle(color: Colors.grey)),
//                     ],
//                   ),
//                 ],
//               ),
//               CircleAvatar(
//                 backgroundColor: color.withOpacity(0.1),
//                 child: Icon(Icons.add, color: color),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildChartPlaceholder() {
//     return Container(
//       height: 200,
//       decoration: BoxDecoration(
//         color: Colors.grey.shade100,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.grey.shade300),
//       ),
//       child: const Center(child: Text('Data tidak cukup untuk menampilkan grafik.', style: TextStyle(color: Colors.grey))),
//     );
//   }
// }

// ====================================================================
// File: health_monitoring_screen_v2.dart
// Health Monitoring — Full theme/lang/font support + chart preview
// Letakkan di: lib/modules/health/health_monitoring_screen.dart
// ====================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';

// ── Uncomment saat integrasi dengan app nyata ──────────────────────────────
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../../providers/theme_provider.dart';
// import '../../providers/language_provider.dart';
// import '../../../models/health_log_model.dart';
// import '../../../services/remote/health_service.dart';

// ── Mock model ─────────────────────────────────────────────────────────────
class HealthLogV2 {
  final String logType;
  final int? systolic;
  final int? diastolic;
  final double? numeric;
  final String? note;
  final DateTime recordedAt;

  HealthLogV2({
    required this.logType,
    this.systolic,
    this.diastolic,
    this.numeric,
    this.note,
    required this.recordedAt,
  });
}

final _mockBPLogs = <HealthLogV2>[];
final _mockBSLogs = <HealthLogV2>[];
final _mockWeightLogs = <HealthLogV2>[];

// ── Main Screen ────────────────────────────────────────────────────────────
class HealthMonitoringScreenV2 extends StatefulWidget {
  const HealthMonitoringScreenV2({super.key});

  @override
  State<HealthMonitoringScreenV2> createState() =>
      _HealthMonitoringScreenV2State();
}

class _HealthMonitoringScreenV2State extends State<HealthMonitoringScreenV2>
    with SingleTickerProviderStateMixin {
  List<HealthLogV2> _bpLogs = [];
  List<HealthLogV2> _bsLogs = [];
  List<HealthLogV2> _weightLogs = [];
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  
  double get _fs {
    try {
      return Provider.of<ThemeProvider>(context).fontSize;
    } catch (_) {
      return 1.0;
    }
  }

  String _t(Map<String, String> m) {
    try {
      return Provider.of<LanguageProvider>(context).translate(m);
    } catch (_) {
      return m['id'] ?? '';
    }
  }

  Color _statusColor(String type, dynamic val) {
    if (type == 'blood_pressure') {
      final s = val as int;
      if (s < 90 || s > 140) return Colors.red;
      if (s > 120) return Colors.orange;
      return Colors.green;
    }
    if (type == 'blood_sugar') {
      final v = (val as double);
      if (v < 70 || v > 140) return Colors.red;
      if (v > 100) return Colors.orange;
      return Colors.green;
    }
    return Colors.blue;
  }

  String _statusLabel(String type, dynamic val) {
    final color = _statusColor(type, val);
    if (color == Colors.green) return 'Normal';
    if (color == Colors.orange) return 'Perhatian';
    return 'Tinggi';
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }

  void _showAddSheet(String type) {
    final c1 = TextEditingController();
    final c2 = TextEditingController();
    final noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => Container(
          decoration: BoxDecoration(
            color: _isDark ? const Color(0xFF0F1B2E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _t({
                  'id':
                      'Tambah Data ${type == 'blood_pressure'
                          ? 'Tekanan Darah'
                          : type == 'blood_sugar'
                          ? 'Gula Darah'
                          : 'Berat Badan'}',
                  'en':
                      'Add ${type == 'blood_pressure'
                          ? 'Blood Pressure'
                          : type == 'blood_sugar'
                          ? 'Blood Sugar'
                          : 'Weight'} Data',
                }),
                style: TextStyle(
                  fontSize: 18 * _fs,
                  fontWeight: FontWeight.w800,
                  color: _isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              if (type == 'blood_pressure') ...[
                Row(
                  children: [
                    Expanded(
                      child: _inputField(
                        c1,
                        'Sistolik (mmHg)',
                        TextInputType.number,
                        _isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _inputField(
                        c2,
                        'Diastolik (mmHg)',
                        TextInputType.number,
                        _isDark,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                _inputField(
                  c1,
                  type == 'blood_sugar'
                      ? 'Kadar Gula (mg/dL)'
                      : 'Berat Badan (kg)',
                  const TextInputType.numberWithOptions(decimal: true),
                  _isDark,
                ),
              ],
              const SizedBox(height: 12),
              _inputField(
                noteCtrl,
                'Catatan (opsional)',
                TextInputType.text,
                _isDark,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    if (type == 'blood_pressure') {
                      final s = int.tryParse(c1.text) ?? 0;
                      final d = int.tryParse(c2.text) ?? 0;
                      if (s > 0 && d > 0) {
                        setState(
                          () => _bpLogs.insert(
                            0,
                            HealthLogV2(
                              logType: type,
                              systolic: s,
                              diastolic: d,
                              note: noteCtrl.text,
                              recordedAt: DateTime.now(),
                            ),
                          ),
                        );
                      }
                    } else {
                      final v = double.tryParse(c1.text) ?? 0;
                      if (v > 0) {
                        setState(() {
                          if (type == 'blood_sugar') {
                            _bsLogs.insert(
                              0,
                              HealthLogV2(
                                logType: type,
                                numeric: v,
                                note: noteCtrl.text,
                                recordedAt: DateTime.now(),
                              ),
                            );
                          } else {
                            _weightLogs.insert(
                              0,
                              HealthLogV2(
                                logType: type,
                                numeric: v,
                                note: noteCtrl.text,
                                recordedAt: DateTime.now(),
                              ),
                            );
                          }
                        });
                      }
                    }
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('✅ Data berhasil disimpan'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  },
                  icon: const Icon(Icons.save_rounded),
                  label: Text(_t({'id': 'Simpan Data', 'en': 'Save Data'})),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(
    TextEditingController ctrl,
    String label,
    TextInputType type,
    bool isDark,
  ) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
        filled: true,
        fillColor: isDark ? Colors.white10 : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.teal, width: 2),
        ),
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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => Navigator.pop(context),
              color: _isDark ? Colors.white : Colors.black87,
            ),
            title: Text(
              _t({'id': 'Monitoring Kesehatan', 'en': 'Health Monitoring'}),
              style: TextStyle(
                fontSize: 18 * _fs,
                fontWeight: FontWeight.w800,
                color: _isDark ? Colors.white : Colors.black87,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(background: _buildHeroHeader()),
            bottom: TabBar(
              controller: _tabCtrl,
              labelColor: Colors.teal,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.teal,
              indicatorWeight: 3,
              labelStyle: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12 * _fs,
              ),
              tabs: [
                Tab(
                  icon: const Icon(Icons.favorite_rounded, size: 16),
                  text: _t({'id': 'Tensi', 'en': 'Blood Pressure'}),
                ),
                Tab(
                  icon: const Icon(Icons.water_drop_rounded, size: 16),
                  text: _t({'id': 'Gula Darah', 'en': 'Blood Sugar'}),
                ),
                Tab(
                  icon: const Icon(Icons.monitor_weight_rounded, size: 16),
                  text: _t({'id': 'Berat', 'en': 'Weight'}),
                ),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [_buildBPTab(), _buildBSTab(), _buildWeightTab()],
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    final latestBP = _bpLogs.isNotEmpty ? _bpLogs.first : null;
    final latestBS = _bsLogs.isNotEmpty ? _bsLogs.first : null;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDark
              ? [const Color(0xFF004D40), const Color(0xFF060B1A)]
              : [Colors.teal.shade600, Colors.teal.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 60),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t({'id': 'Hasil Terbaru', 'en': "Latest Status"}),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                        fontSize: 14 * _fs,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (latestBP != null)
                      Text(
                        'Tensi: ${latestBP.systolic}/${latestBP.diastolic} mmHg',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22 * _fs,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    const SizedBox(height: 4),
                    if (latestBS != null)
                      Text(
                        'Gula Darah: ${latestBS.numeric} mg/dL',
                        style: TextStyle(
                          color: Colors.teal.shade50,
                          fontWeight: FontWeight.w600,
                          fontSize: 16 * _fs,
                        ),
                      ),
                  ],
                ),
              ),
              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Normal',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
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

  // ── Blood Pressure Tab ──────────────────────────────────────────────────
  Widget _buildBPTab() {
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // Summary card
          _SummaryCard(
            title: _t({'id': 'Tekanan Darah', 'en': 'Blood Pressure'}),
            value: _bpLogs.isNotEmpty
                ? '${_bpLogs.first.systolic}/${_bpLogs.first.diastolic}'
                : '—',
            unit: 'mmHg',
            icon: Icons.favorite_rounded,
            color: Colors.red,
            status: _bpLogs.isNotEmpty
                ? _statusLabel('blood_pressure', _bpLogs.first.systolic)
                : '-',
            statusColor: _bpLogs.isNotEmpty
                ? _statusColor('blood_pressure', _bpLogs.first.systolic)
                : Colors.grey,
            isDark: _isDark,
            fs: _fs,
            onAdd: () => _showAddSheet('blood_pressure'),
          ),
          const SizedBox(height: 16),

          // Mini chart
          _MiniBarChart(
            logs: _bpLogs.take(7).toList(),
            logType: 'blood_pressure',
            isDark: _isDark,
            fs: _fs,
          ),
          const SizedBox(height: 16),

          // Normal range info
          _RangeInfoCard(
            title: _t({'id': 'Rentang Normal', 'en': 'Normal Range'}),
            ranges: [
              ('Normal', '< 120/80 mmHg', Colors.green),
              ('Perhatian', '120-139/80-89 mmHg', Colors.orange),
              ('Tinggi', '≥ 140/90 mmHg', Colors.red),
            ],
            isDark: _isDark,
            fs: _fs,
          ),
          const SizedBox(height: 16),

          // History
          _HistorySection(
            title: _t({'id': 'Riwayat', 'en': 'History'}),
            logs: _bpLogs,
            logType: 'blood_pressure',
            isDark: _isDark,
            fs: _fs,
            formatTime: _formatTime,
            statusColor: _statusColor,
            statusLabel: _statusLabel,
          ),
        ],
      ),
    );
  }

  // ── Blood Sugar Tab ─────────────────────────────────────────────────────
  Widget _buildBSTab() {
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _SummaryCard(
            title: _t({'id': 'Gula Darah', 'en': 'Blood Sugar'}),
            value: _bsLogs.isNotEmpty ? '${_bsLogs.first.numeric}' : '—',
            unit: 'mg/dL',
            icon: Icons.water_drop_rounded,
            color: Colors.orange,
            status: _bsLogs.isNotEmpty
                ? _statusLabel('blood_sugar', _bsLogs.first.numeric)
                : '-',
            statusColor: _bsLogs.isNotEmpty
                ? _statusColor('blood_sugar', _bsLogs.first.numeric)
                : Colors.grey,
            isDark: _isDark,
            fs: _fs,
            onAdd: () => _showAddSheet('blood_sugar'),
          ),
          const SizedBox(height: 16),
          _MiniBarChart(
            logs: _bsLogs.take(7).toList(),
            logType: 'blood_sugar',
            isDark: _isDark,
            fs: _fs,
          ),
          const SizedBox(height: 16),
          _RangeInfoCard(
            title: _t({'id': 'Rentang Normal', 'en': 'Normal Range'}),
            ranges: [
              ('Rendah', '< 70 mg/dL', Colors.blue),
              ('Normal', '70-100 mg/dL', Colors.green),
              ('Tinggi', '> 140 mg/dL', Colors.red),
            ],
            isDark: _isDark,
            fs: _fs,
          ),
          const SizedBox(height: 16),
          _HistorySection(
            title: _t({'id': 'Riwayat', 'en': 'History'}),
            logs: _bsLogs,
            logType: 'blood_sugar',
            isDark: _isDark,
            fs: _fs,
            formatTime: _formatTime,
            statusColor: _statusColor,
            statusLabel: _statusLabel,
          ),
        ],
      ),
    );
  }

  // ── Weight Tab ──────────────────────────────────────────────────────────
  Widget _buildWeightTab() {
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _SummaryCard(
            title: _t({'id': 'Berat Badan', 'en': 'Body Weight'}),
            value: _weightLogs.isNotEmpty
                ? '${_weightLogs.first.numeric}'
                : '—',
            unit: 'kg',
            icon: Icons.monitor_weight_rounded,
            color: Colors.blue,
            status: 'Normal',
            statusColor: Colors.green,
            isDark: _isDark,
            fs: _fs,
            onAdd: () => _showAddSheet('weight'),
          ),
          const SizedBox(height: 16),
          _MiniBarChart(
            logs: _weightLogs.take(7).toList(),
            logType: 'weight',
            isDark: _isDark,
            fs: _fs,
          ),
          const SizedBox(height: 16),

          // BMI card
          if (_weightLogs.isNotEmpty)
            _BMICard(
              weight: _weightLogs.first.numeric ?? 0,
              isDark: _isDark,
              fs: _fs,
            ),
          const SizedBox(height: 16),

          _HistorySection(
            title: _t({'id': 'Riwayat', 'en': 'History'}),
            logs: _weightLogs,
            logType: 'weight',
            isDark: _isDark,
            fs: _fs,
            formatTime: _formatTime,
            statusColor: (t, v) => Colors.blue,
            statusLabel: (t, v) => 'Normal',
          ),
        ],
      ),
    );
  }
}

// ── Summary Card ───────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.status,
    required this.statusColor,
    required this.isDark,
    required this.fs,
    required this.onAdd,
  });
  final String title, value, unit, status;
  final IconData icon;
  final Color color, statusColor;
  final bool isDark;
  final double fs;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1B2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.8), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13 * fs,
                    color: isDark ? Colors.white54 : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 30 * fs,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black87,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        unit,
                        style: TextStyle(
                          fontSize: 12 * fs,
                          color: isDark ? Colors.white38 : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11 * fs,
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.8), color],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mini Bar Chart ─────────────────────────────────────────────────────────
class _MiniBarChart extends StatelessWidget {
  const _MiniBarChart({
    required this.logs,
    required this.logType,
    required this.isDark,
    required this.fs,
  });
  final List<HealthLogV2> logs;
  final String logType;
  final bool isDark;
  final double fs;

  double _getValue(HealthLogV2 log) {
    if (logType == 'blood_pressure') return (log.systolic ?? 0).toDouble();
    return log.numeric ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) return const SizedBox();

    final values = logs.map(_getValue).toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final minVal = values.reduce((a, b) => a < b ? a : b);

    final color = logType == 'blood_pressure'
        ? Colors.red
        : logType == 'blood_sugar'
        ? Colors.orange
        : Colors.blue;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1B2E) : Colors.white,
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.bar_chart_rounded, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                'Tren 7 Hari',
                style: TextStyle(
                  fontSize: 14 * fs,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                'Max: ${maxVal.toStringAsFixed(0)} | Min: ${minVal.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 10 * fs,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(values.length, (i) {
                final pct = maxVal == 0 ? 0.0 : values[i] / maxVal;
                final days = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];
                final dayIdx =
                    (DateTime.now().weekday - 1 - (values.length - 1 - i) + 7) %
                    7;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          values[i].toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: 9 * fs,
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration: Duration(milliseconds: 300 + i * 50),
                          height: 60 * pct.clamp(0.1, 1.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color.withOpacity(0.6), color],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          days[dayIdx],
                          style: TextStyle(
                            fontSize: 9 * fs,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Range Info Card ────────────────────────────────────────────────────────
class _RangeInfoCard extends StatelessWidget {
  const _RangeInfoCard({
    required this.title,
    required this.ranges,
    required this.isDark,
    required this.fs,
  });
  final String title;
  final List<(String, String, Color)> ranges;
  final bool isDark;
  final double fs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1B2E) : Colors.white,
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
              const Icon(
                Icons.info_outline_rounded,
                color: Colors.teal,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13 * fs,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...ranges.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: r.$3,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    r.$1,
                    style: TextStyle(
                      fontSize: 12 * fs,
                      fontWeight: FontWeight.w600,
                      color: r.$3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    r.$2,
                    style: TextStyle(
                      fontSize: 12 * fs,
                      color: isDark ? Colors.white54 : Colors.black87,
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
}

// ── BMI Card ────────────────────────────────────────────────────────────────
class _BMICard extends StatelessWidget {
  const _BMICard({
    required this.weight,
    required this.isDark,
    required this.fs,
  });
  final double weight;
  final bool isDark;
  final double fs;

  @override
  Widget build(BuildContext context) {
    // Asumsi tinggi 165cm untuk preview
    final bmi = weight / (1.65 * 1.65);
    final label = bmi < 18.5
        ? 'Kurus'
        : bmi < 25
        ? 'Normal'
        : bmi < 30
        ? 'Berlebih'
        : 'Obesitas';
    final color = bmi < 18.5
        ? Colors.blue
        : bmi < 25
        ? Colors.green
        : bmi < 30
        ? Colors.orange
        : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1B2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.monitor_weight_rounded, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Indeks Massa Tubuh (BMI)',
                  style: TextStyle(
                    fontSize: 12 * fs,
                    color: isDark ? Colors.white54 : Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      bmi.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 24 * fs,
                        fontWeight: FontWeight.w900,
                        color: color,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 11 * fs,
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Berdasarkan berat ${weight}kg, tinggi 165cm',
                  style: TextStyle(
                    fontSize: 10 * fs,
                    color: isDark ? Colors.white38 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── History Section ────────────────────────────────────────────────────────
class _HistorySection extends StatelessWidget {
  const _HistorySection({
    required this.title,
    required this.logs,
    required this.logType,
    required this.isDark,
    required this.fs,
    required this.formatTime,
    required this.statusColor,
    required this.statusLabel,
  });
  final String title;
  final List<HealthLogV2> logs;
  final String logType;
  final bool isDark;
  final double fs;
  final String Function(DateTime) formatTime;
  final Color Function(String, dynamic) statusColor;
  final String Function(String, dynamic) statusLabel;

  String _display(HealthLogV2 log) {
    if (logType == 'blood_pressure')
      return '${log.systolic}/${log.diastolic} mmHg';
    if (logType == 'blood_sugar') return '${log.numeric} mg/dL';
    return '${log.numeric} kg';
  }

  dynamic _val(HealthLogV2 log) {
    if (logType == 'blood_pressure') return log.systolic;
    return log.numeric;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.teal, Colors.blue],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15 * fs,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
        if (logs.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F1B2E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Belum ada data',
              style: TextStyle(color: Colors.grey, fontSize: 13 * fs),
            ),
          )
        else
          ...logs.map((log) {
            final color = statusColor(logType, _val(log));
            final label = statusLabel(logType, _val(log));
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F1B2E) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: color.withOpacity(0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.circle, color: color, size: 10),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _display(log),
                          style: TextStyle(
                            fontSize: 15 * fs,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          formatTime(log.recordedAt),
                          style: TextStyle(
                            fontSize: 11 * fs,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                        if (log.note != null && log.note!.isNotEmpty)
                          Text(
                            log.note!,
                            style: TextStyle(
                              fontSize: 11 * fs,
                              color: isDark ? Colors.white38 : Colors.black38,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11 * fs,
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
