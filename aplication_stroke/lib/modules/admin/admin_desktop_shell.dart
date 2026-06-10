import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_login_screen.dart';
import 'pages/admin_invitations_page.dart';
import 'pages/admin_overview_page.dart';
import 'pages/admin_patients_page.dart';
import 'pages/admin_staff_page.dart';
import 'services/admin_service.dart';

enum _AdminNav { overview, patients, staff, invitations }

class AdminDesktopShell extends StatefulWidget {
  const AdminDesktopShell({super.key});

  @override
  State<AdminDesktopShell> createState() => _AdminDesktopShellState();
}

class _AdminDesktopShellState extends State<AdminDesktopShell> {
  final _admin = AdminService();
  _AdminNav _nav = _AdminNav.overview;
  bool _loading = true;
  String? _loadError;
  AdminDashboardStats? _stats;
  String? _adminEmail;

  @override
  void initState() {
    super.initState();
    _adminEmail = Supabase.instance.client.auth.currentUser?.email;
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final stats = await _admin.loadStats();
      if (!mounted) return;
      setState(() => _stats = stats);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          _Sidebar(
            current: _nav,
            adminEmail: _adminEmail,
            onSelect: (n) => setState(() => _nav = n),
            onLogout: _logout,
            onRefresh: _refresh,
          ),
          Expanded(
            child: Column(
              children: [
                if (_loadError != null)
                  MaterialBanner(
                    content: Text(_loadError!),
                    leading: const Icon(Icons.warning_amber_rounded),
                    actions: [
                      TextButton(onPressed: _refresh, child: const Text('Coba lagi')),
                    ],
                  ),
                Expanded(
                  child: _loading && _stats == null
                      ? const Center(child: CircularProgressIndicator())
                      : _buildPage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage() {
    switch (_nav) {
      case _AdminNav.overview:
        return AdminOverviewPage(stats: _stats ?? const AdminDashboardStats(
          patients: 0,
          pharmacists: 0,
          doctors: 0,
          activeChats: 0,
          reminders: 0,
          pendingPharmacistInvites: 0,
          pendingDoctorInvites: 0,
        ));
      case _AdminNav.patients:
        return const AdminPatientsPage();
      case _AdminNav.staff:
        return const AdminStaffPage();
      case _AdminNav.invitations:
        return const AdminInvitationsPage();
    }
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.current,
    required this.onSelect,
    required this.onLogout,
    required this.onRefresh,
    this.adminEmail,
  });

  final _AdminNav current;
  final ValueChanged<_AdminNav> onSelect;
  final VoidCallback onLogout;
  final VoidCallback onRefresh;
  final String? adminEmail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFF38BDF8),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Smart Stroke',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Admin Console',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF1E293B), height: 1),
          const SizedBox(height: 8),
          _NavItem(
            icon: Icons.dashboard_rounded,
            label: 'Ringkasan',
            selected: current == _AdminNav.overview,
            onTap: () => onSelect(_AdminNav.overview),
          ),
          _NavItem(
            icon: Icons.people_alt_rounded,
            label: 'Pasien',
            selected: current == _AdminNav.patients,
            onTap: () => onSelect(_AdminNav.patients),
          ),
          _NavItem(
            icon: Icons.person_add_rounded,
            label: 'Daftar Staff',
            selected: current == _AdminNav.staff,
            onTap: () => onSelect(_AdminNav.staff),
          ),
          _NavItem(
            icon: Icons.vpn_key_rounded,
            label: 'Undangan',
            selected: current == _AdminNav.invitations,
            onTap: () => onSelect(_AdminNav.invitations),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (adminEmail != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      adminEmail!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Muat Ulang'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Color(0xFF334155)),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Keluar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
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

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected
            ? const Color(0xFF1E3A5F)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected ? const Color(0xFF38BDF8) : Colors.white54,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
