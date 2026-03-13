/// ====================================================================
/// File: unified_main_screen.dart
/// --------------------------------------------------------------------
/// Layar Utama dengan Navigasi Bottom Bar
///
/// Dokumen ini berisi layar utama aplikasi yang menggabungkan
/// semua tab utama dalam satu layar dengan bottom navigation.
///
/// Tab yang tersedia:
/// - Tab 0: EnhancedHomeTab (Dashboard/Home)
/// - Tab 1: CommunityScreen (Forum/Komunitas)
/// - Tab 2: PatientChatDashboardScreen (Chat Konsultasi)
/// - Tab 3: ProfileScreen (Profil Pengguna)
///
/// Komponen:
/// - Scaffold dengan extendBody: true (untuk navbar floating)
/// - CustomNavbar (dengan tombol SOS di tengah)
/// - stream photoUrl dari Supabase untuk profile tab
///
/// Author: Tim Developer Synexa
/// ====================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import Custom Widgets
import '../../widgets/navbar.dart';
import 'widgets/enhanced_home_tab.dart';

// Import Sub-Screens
import '../consultation/patient_chat_dashboard_screen.dart';
import '../community/community_screen.dart';
import '../profile/profile_screen.dart';
import '../emergency_call/emergency_call_screen.dart';

/// UnifiedMainScreen: wrapper for all main tabs with bottom navbar.
class UnifiedMainScreen extends StatefulWidget {
  const UnifiedMainScreen({super.key});

  @override
  State<UnifiedMainScreen> createState() => _UnifiedMainScreenState();
}

class _UnifiedMainScreenState extends State<UnifiedMainScreen> {
  final _supabase = Supabase.instance.client;

  int _currentIndex = 0;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadPhotoUrl();
  }

  Future<void> _loadPhotoUrl() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      final data = await _supabase
          .from('users')
          .select('photo_url')
          .eq('id', userId)
          .maybeSingle();
      if (mounted && data != null) {
        setState(() => _photoUrl = data['photo_url']?.toString());
      }
    } catch (_) {}
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
  }

  void _showEmergencyCall() {
    HapticFeedback.heavyImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EmergencyCallScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _buildCurrentTab(),
      bottomNavigationBar: CustomNavbar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        photoUrl: _photoUrl,
        onSosTap: _showEmergencyCall,
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentIndex) {
      case 0:
        return const EnhancedHomeTab();
      case 1:
        return const CommunityScreen();
      case 2:
        return const PatientChatDashboardScreen();
      case 3:
        return const ProfileScreen();
      default:
        return const EnhancedHomeTab();
    }
  }
}
