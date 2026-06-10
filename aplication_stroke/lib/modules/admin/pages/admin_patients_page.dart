import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/admin_service.dart';
import '../utils/admin_formatters.dart';

class AdminPatientsPage extends StatefulWidget {
  const AdminPatientsPage({super.key});

  @override
  State<AdminPatientsPage> createState() => _AdminPatientsPageState();
}

class _AdminPatientsPageState extends State<AdminPatientsPage> {
  final _admin = AdminService();
  final _search = TextEditingController();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(_filter);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await _admin.listPatients();
      if (!mounted) return;
      setState(() {
        _patients = rows;
        _filtered = rows;
      });
      _filter();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _patients = [];
        _filtered = [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filter() {
    final q = _search.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _patients
          : _patients.where((p) {
              final name = p['name']?.toString().toLowerCase() ?? '';
              final email = p['email']?.toString().toLowerCase() ?? '';
              return name.contains(q) || email.contains(q);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pasien',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '${_patients.length} pasien terdaftar',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Muat ulang',
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 280,
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau email...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
            child: _ErrorBanner(message: _error!, onRetry: _load),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? const SizedBox.shrink()
              : _filtered.isEmpty
              ? Center(
                  child: Text(
                    'Belum ada data pasien',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DataTable(
                      headingRowColor:
                          WidgetStateProperty.all(Colors.grey.shade50),
                      columns: const [
                        DataColumn(label: Text('Nama')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Telepon')),
                        DataColumn(label: Text('Terdaftar')),
                      ],
                      rows: _filtered.map((p) {
                        final name = p['name']?.toString() ?? '-';
                        final created = DateTime.tryParse(
                          p['created_at']?.toString() ?? '',
                        );
                        return DataRow(
                          cells: [
                            DataCell(
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: const Color(0xFF0A7AC1)
                                        .withValues(alpha: 0.12),
                                    child: Text(
                                      AdminFormatters.initial(name),
                                      style: const TextStyle(
                                        color: Color(0xFF0A7AC1),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(name),
                                ],
                              ),
                            ),
                            DataCell(Text(p['email']?.toString() ?? '-')),
                            DataCell(Text(p['phone']?.toString() ?? '-')),
                            DataCell(
                              Text(AdminFormatters.date(created)),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF991B1B)),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}
