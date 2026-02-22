import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import Screens
import 'package:aplication_stroke/modules/community/community_screen.dart';
import 'package:aplication_stroke/modules/consultation/patient_chat_dashboard_screen.dart';
import 'package:aplication_stroke/modules/profile/profile_screen.dart';
import 'widgets/enhanced_home_tab.dart';

// Import Modular Components
import 'package:aplication_stroke/modules/navbar/navbar.dart';

/// Halaman Dashboard Utama
/// 
/// Halaman ini berfungsi sebagai kontainer utama aplikasi yang mengatur navigasi antar tab
/// menggunakan komponen CustomNavbar (Pill Style).
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _supabase = Supabase.instance.client;

  int _currentIndex = 0;
  String? _userPhotoUrl;

  // Daftar halaman yang dapat diakses melalui Navbar
  final List<Widget> _pages = [
    const EnhancedHomeTab(),
    const CommunityScreen(),
    const PatientChatDashboardScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  /// Memuat profil pengguna untuk menampilkan foto di Navbar
  Future<void> _loadUserProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final data = await _supabase
          .from('users')
          .select('photo_url')
          .eq('id', userId)
          .maybeSingle();

      if (mounted && data != null) {
        setState(() {
          _userPhotoUrl = data['photo_url']?.toString();
        });
      }
    } catch (e) {
      debugPrint('Error loading navbar photo: $e');
    }
  }

  /// Fungsi untuk menangani perpindahan tab
  void _onNavTap(int index) {
    if (!mounted) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Memungkinkan konten terlihat mengalir di belakang navbar transparan
      body: _pages[_currentIndex],
      bottomNavigationBar: CustomNavbar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        photoUrl: _userPhotoUrl,
      ),
    );
  }
}
