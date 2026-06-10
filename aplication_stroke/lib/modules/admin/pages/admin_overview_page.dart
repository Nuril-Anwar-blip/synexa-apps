import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/admin_service.dart';

class AdminOverviewPage extends StatelessWidget {
  const AdminOverviewPage({super.key, required this.stats});

  final AdminDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pantau aktivitas Smart Stroke secara real-time',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _StatTile(
                label: 'Pasien',
                value: '${stats.patients}',
                icon: Icons.people_alt_rounded,
                color: const Color(0xFF0A7AC1),
              ),
              _StatTile(
                label: 'Apoteker',
                value: '${stats.pharmacists}',
                icon: Icons.local_pharmacy_rounded,
                color: const Color(0xFF059669),
              ),
              _StatTile(
                label: 'Dokter',
                value: '${stats.doctors}',
                icon: Icons.medical_services_rounded,
                color: const Color(0xFF7C3AED),
              ),
              _StatTile(
                label: 'Chat Aktif',
                value: '${stats.activeChats}',
                icon: Icons.forum_rounded,
                color: const Color(0xFFD97706),
              ),
              _StatTile(
                label: 'Pengingat Obat',
                value: '${stats.reminders}',
                icon: Icons.alarm_rounded,
                color: const Color(0xFFDC2626),
              ),
              _StatTile(
                label: 'Undangan Apoteker',
                value: '${stats.pendingPharmacistInvites}',
                icon: Icons.vpn_key_rounded,
                color: const Color(0xFF0891B2),
              ),
              _StatTile(
                label: 'Undangan Dokter',
                value: '${stats.pendingDoctorInvites}',
                icon: Icons.key_rounded,
                color: const Color(0xFF4F46E5),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF0369A1)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Daftarkan apoteker dan dokter melalui menu "Daftar Staff". '
                    'Sistem akan membuat kode undangan yang digunakan saat registrasi di aplikasi mobile.',
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      height: 1.5,
                    ),
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

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
