import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/health_log_model.dart';
import '../../../services/remote/health_service.dart';

class HealthMonitoringScreen extends StatefulWidget {
  const HealthMonitoringScreen({super.key});

  @override
  State<HealthMonitoringScreen> createState() => _HealthMonitoringScreenState();
}

class _HealthMonitoringScreenState extends State<HealthMonitoringScreen> {
  final HealthService _healthService = HealthService();
  final String _userId = Supabase.instance.client.auth.currentUser?.id ?? '';
  
  bool _isLoading = true;
  List<HealthLog> _bpLogs = [];
  List<HealthLog> _bsLogs = [];
  List<HealthLog> _weightLogs = [];

  @override
  void initState() {
    super.initState();
    _loadAllLogs();
  }

  Future<void> _loadAllLogs() async {
    setState(() => _isLoading = true);
    try {
      _bpLogs = await _healthService.getHealthLogs(_userId, 'blood_pressure');
      _bsLogs = await _healthService.getHealthLogs(_userId, 'blood_sugar');
      _weightLogs = await _healthService.getHealthLogs(_userId, 'weight');
    } catch (e) {
      debugPrint('Error loading health logs: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddLogSheet(String type) {
    final systolicController = TextEditingController();
    final diastolicController = TextEditingController();
    final valueController = TextEditingController();
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(
        padding: EdgeInsets.only(
          top: 24,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tambah Data ${type == 'blood_pressure' ? 'Tensi' : (type == 'blood_sugar' ? 'Gula Darah' : 'Berat Badan')}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (type == 'blood_pressure') ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: systolicController,
                      decoration: const InputDecoration(labelText: 'Sistolik (mmHg)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: diastolicController,
                      decoration: const InputDecoration(labelText: 'Diastolik (mmHg)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ] else ...[
              TextField(
                controller: valueController,
                decoration: InputDecoration(
                  labelText: type == 'blood_sugar' ? 'Kadar (mg/dL)' : 'Berat (kg)',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Catatan (Opsional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  final log = HealthLog(
                    userId: _userId,
                    logType: type,
                    valueSystolic: int.tryParse(systolicController.text),
                    valueDiastolic: int.tryParse(diastolicController.text),
                    valueNumeric: double.tryParse(valueController.text),
                    note: noteController.text,
                    recordedAt: DateTime.now(),
                  );
                  await _healthService.saveHealthLog(log);
                  Navigator.pop(context);
                  _loadAllLogs();
                },
                child: const Text('Simpan Data'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Monitoring Kesehatan')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAllLogs,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHealthCard('Tekanan Darah', _bpLogs.isNotEmpty ? '${_bpLogs.first.valueSystolic}/${_bpLogs.first.valueDiastolic}' : '—', 'mmHg', Colors.red, () => _showAddLogSheet('blood_pressure')),
                  const SizedBox(height: 16),
                  _buildHealthCard('Gula Darah', _bsLogs.isNotEmpty ? '${_bsLogs.first.valueNumeric}' : '—', 'mg/dL', Colors.orange, () => _showAddLogSheet('blood_sugar')),
                  const SizedBox(height: 16),
                  _buildHealthCard('Berat Badan', _weightLogs.isNotEmpty ? '${_weightLogs.first.valueNumeric}' : '—', 'kg', Colors.blue, () => _showAddLogSheet('weight')),
                  const SizedBox(height: 32),
                  const Text('Grafik Progres (Segera Hadir)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  _buildChartPlaceholder(),
                ],
              ),
            ),
    );
  }

  Widget _buildHealthCard(String title, String value, String unit, Color color, VoidCallback onTap) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Text(unit, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(Icons.add, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartPlaceholder() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Center(child: Text('Data tidak cukup untuk menampilkan grafik.', style: TextStyle(color: Colors.grey))),
    );
  }
}
