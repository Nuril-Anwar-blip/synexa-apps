import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/admin_service.dart';
import '../utils/admin_formatters.dart';

class AdminInvitationsPage extends StatefulWidget {
  const AdminInvitationsPage({super.key});

  @override
  State<AdminInvitationsPage> createState() => _AdminInvitationsPageState();
}

class _AdminInvitationsPageState extends State<AdminInvitationsPage>
    with SingleTickerProviderStateMixin {
  final _admin = AdminService();
  late TabController _tab;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _pharm = [];
  List<Map<String, dynamic>> _docs = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pharm = await _admin.listPharmacistInvitations();
      final docs = await _admin.listDoctorInvitations();
      if (!mounted) return;
      setState(() {
        _pharm = pharm;
        _docs = docs;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _pharm = [];
        _docs = [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _revoke(String id, bool isDoctor) async {
    try {
      if (isDoctor) {
        await _admin.revokeDoctorInvitation(id);
      } else {
        await _admin.revokePharmacistInvitation(id);
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    }
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
                      'Undangan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Kelola kode undangan apoteker dan dokter',
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
            ],
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
            child: Container(
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
                      _error!,
                      style: const TextStyle(color: Color(0xFF991B1B)),
                    ),
                  ),
                  TextButton(onPressed: _load, child: const Text('Coba lagi')),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: TabBar(
            controller: _tab,
            tabs: const [
              Tab(text: 'Apoteker'),
              Tab(text: 'Dokter'),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? const SizedBox.shrink()
              : TabBarView(
                  controller: _tab,
                  children: [
                    _InviteTable(
                      rows: _pharm,
                      onRevoke: (id) => _revoke(id, false),
                    ),
                    _InviteTable(
                      rows: _docs,
                      isDoctor: true,
                      onRevoke: (id) => _revoke(id, true),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _InviteTable extends StatelessWidget {
  const _InviteTable({
    required this.rows,
    required this.onRevoke,
    this.isDoctor = false,
  });

  final List<Map<String, dynamic>> rows;
  final void Function(String id) onRevoke;
  final bool isDoctor;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Center(
        child: Text(
          'Belum ada undangan',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
          columns: const [
            DataColumn(label: Text('Kode')),
            DataColumn(label: Text('Nama')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Dibuat')),
            DataColumn(label: Text('')),
          ],
          rows: rows.map((r) {
            final used = r['is_used'] == true;
            final created = DateTime.tryParse(r['created_at']?.toString() ?? '');
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    r['token']?.toString() ?? '-',
                    style: GoogleFonts.jetBrainsMono(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataCell(Text(r['name']?.toString() ?? '-')),
                DataCell(Text(r['email']?.toString() ?? '-')),
                DataCell(
                  Chip(
                    label: Text(used ? 'Digunakan' : 'Aktif'),
                    backgroundColor: used
                        ? Colors.grey.shade200
                        : const Color(0xFFD1FAE5),
                    labelStyle: TextStyle(
                      color: used
                          ? Colors.grey.shade700
                          : const Color(0xFF065F46),
                      fontSize: 12,
                    ),
                  ),
                ),
                DataCell(Text(AdminFormatters.dateTime(created))),
                DataCell(
                  used
                      ? const SizedBox.shrink()
                      : IconButton(
                          icon: const Icon(Icons.block, size: 20),
                          tooltip: 'Cabut undangan',
                          onPressed: () => onRevoke(r['id'].toString()),
                        ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
