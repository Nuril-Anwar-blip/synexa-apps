/// ====================================================================
/// File: navbar.dart
/// --------------------------------------------------------------------
/// Widget CustomNavbar - Navigasi Bawah (Bottom Navigation)
///
/// Dokumen ini berisi komponen navigasi bottom bar yang浮动 (floating)
/// dengan desain icon-only (hanya ikon, tanpa teks).
///
/// Fitur:
/// - 4 tab: Home, Forum, Chat, Profile
/// - Desain浮动 dengan bayangan (shadow)
/// - Tab aktif menunjukkan gradient teal
/// - Tab Profile menampilkan avatar foto pengguna
/// - Responsif terhadap tema gelap/terang
///
/// Penggunaan:
///   CustomNavbar(
///     currentIndex: _currentIndex,
///     onTap: (index) => setState(() => _currentIndex = index),
///     photoUrl: _photoUrl,
///   )
///
/// Author: Tim Developer Synexa
/// ====================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Simple Icon-Only Floating Navbar
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

  static const _icons = [
    Icons.home_rounded,
    Icons.groups_rounded,
    Icons.chat_bubble_rounded,
    Icons.person_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 12),
      height: 62,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E2A3A).withValues(alpha: 0.97)
            : Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: List.generate(4, (i) => _buildItem(context, i, isDark)),
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index, bool isDark) {
    final isActive = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap(index);
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    colors: [Color(0xFF009688), Color(0xFF00695C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(22),
          ),
          child: _buildIcon(index, isActive, isDark),
        ),
      ),
    );
  }

  Widget _buildIcon(int index, bool isActive, bool isDark) {
    // Profile tab shows avatar
    if (index == 3) {
      return Center(
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? Colors.white : Colors.transparent,
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
                          ? Colors.white
                          : (isDark ? Colors.white54 : Colors.grey.shade500),
                    ),
                  )
                : Icon(
                    Icons.person_rounded,
                    size: 18,
                    color: isActive
                        ? Colors.white
                        : (isDark ? Colors.white54 : Colors.grey.shade500),
                  ),
          ),
        ),
      );
    }

    return Center(
      child: Icon(
        _icons[index],
        size: 24,
        color: isActive
            ? Colors.white
            : (isDark ? Colors.white38 : Colors.grey.shade400),
      ),
    );
  }
}
