/// ====================================================================
/// File: navbar.dart
/// --------------------------------------------------------------------
/// Widget CustomNavbar - Navigasi Bawah (Bottom Navigation)
///
/// Dokumen ini berisi komponen navigasi bottom bar dengan desain:
/// - 5 item: Home, Menu, SOS (darurat), Chat, Profile
/// - Tombol SOS di tengah dengan warna merah mencolok
/// - Desain floating dengan bayangan (shadow)
/// - Responsif terhadap tema gelap/terang
///
/// Penggunaan:
///   CustomNavbar(
///     currentIndex: _currentIndex,
///     onTap: (index) => setState(() => _currentIndex = index),
///     photoUrl: _photoUrl,
///     onSosTap: () => _showEmergencyDialog(),
///   )
///
/// Author: Tim Developer Synexa
/// ====================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Custom Navbar dengan SOS Button di tengah
class CustomNavbar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String? photoUrl;
  final VoidCallback? onSosTap;

  const CustomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.photoUrl,
    this.onSosTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    // Adjusted index:
    // 0 = Home, 1 = Menu, 2 = SOS (handled separately), 3 = Chat, 4 = Profile
    // When user taps 0-1, they go to indices 0-1
    // When user taps SOS, onSosTap is called
    // When user taps 3-4 (chat/profile), they go to indices 2-3

    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, bottomPad + 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Home
          _NavItem(
            icon: Icons.home_rounded,
            isActive: currentIndex == 0,
            onTap: () => onTap(0),
            isDark: isDark,
          ),
          // Menu/Forum
          _NavItem(
            icon: Icons.grid_view_rounded,
            isActive: currentIndex == 1,
            onTap: () => onTap(1),
            isDark: isDark,
          ),
          // SOS Button (Center - Red)
          _SosButton(onTap: onSosTap ?? () {}, isDark: isDark),
          // Chat
          _NavItem(
            icon: Icons.chat_bubble_rounded,
            isActive: currentIndex == 2,
            onTap: () => onTap(2),
            isDark: isDark,
          ),
          // Profile
          _ProfileNavItem(
            isActive: currentIndex == 3,
            photoUrl: photoUrl,
            onTap: () => onTap(3),
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

/// Nav Item biasa (Home, Menu, Chat)
class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final bool isDark;

  const _NavItem({
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark
                    ? Colors.teal.withValues(alpha: 0.2)
                    : Colors.teal.withValues(alpha: 0.1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          size: 26,
          color: isActive
              ? Colors.teal
              : (isDark ? Colors.white54 : Colors.grey.shade500),
        ),
      ),
    );
  }
}

/// SOS Button - Merah di tengah
class _SosButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;

  const _SosButton({required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        onTap();
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE53935), Color(0xFFC62828)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE53935).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.sos_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}

/// Profile Nav Item dengan avatar
class _ProfileNavItem extends StatelessWidget {
  final bool isActive;
  final String? photoUrl;
  final VoidCallback onTap;
  final bool isDark;

  const _ProfileNavItem({
    required this.isActive,
    required this.photoUrl,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark
                    ? Colors.teal.withValues(alpha: 0.2)
                    : Colors.teal.withValues(alpha: 0.1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            // Avatar
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? Colors.teal : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: photoUrl != null && photoUrl!.isNotEmpty
                    ? Image.network(
                        photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.person_rounded,
                          size: 18,
                          color: isActive
                              ? Colors.teal
                              : (isDark
                                    ? Colors.white54
                                    : Colors.grey.shade500),
                        ),
                      )
                    : Icon(
                        Icons.person_rounded,
                        size: 18,
                        color: isActive
                            ? Colors.teal
                            : (isDark ? Colors.white54 : Colors.grey.shade500),
                      ),
              ),
            ),
            // Notification dot
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
