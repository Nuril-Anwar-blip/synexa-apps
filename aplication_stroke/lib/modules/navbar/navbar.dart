import 'package:flutter/material.dart';

/// ===============================================================
/// CUSTOM NAVBAR (STYLE VIDEO)
/// ===============================================================
/// - Rounded / pill navbar
/// - Active tab punya background
/// - Profile tab pakai foto user (avatar)
/// - SOS tidak ada di navbar
/// ===============================================================
class CustomNavbar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// avatar untuk tab profile
  final String? photoUrl;

  const CustomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    // Kembalikan langsung _PillNavbar agar bisa digunakan di property bottomNavigationBar milik Scaffold
    return _PillNavbar(
      currentIndex: currentIndex,
      onTap: onTap,
      photoUrl: photoUrl,
    );
  }
}

class _PillNavbar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String? photoUrl;

  const _PillNavbar({
    required this.currentIndex,
    required this.onTap,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      // Margin bawah agar terlihat melayang di atas gesture bar / navigasi HP
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: SafeArea(
        top: false,
        child: Container(
          height: 64, // Lebih tinggi agar lebih proporsional
          margin: const EdgeInsets.fromLTRB(40, 0, 40, 24), // Berjarak dari kiri-kanan agar ramping ke tengah
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252525) : Colors.white,
            borderRadius: BorderRadius.circular(36), // Pill-shaped
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: isDark 
                ? Border.all(color: Colors.white.withOpacity(0.05), width: 0.5)
                : Border.all(color: Colors.black.withOpacity(0.05), width: 0.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavPillItem(
                isActive: currentIndex == 0,
                icon: Icons.home_rounded,
                activeColor: theme.primaryColor,
                onTap: () => onTap(0),
              ),
              _NavPillItem(
                isActive: currentIndex == 1,
                icon: Icons.groups_rounded,
                activeColor: theme.primaryColor,
                onTap: () => onTap(1),
              ),
              _NavPillItem(
                isActive: currentIndex == 2,
                icon: Icons.chat_bubble_rounded,
                activeColor: theme.primaryColor,
                onTap: () => onTap(2),
              ),
              _ProfileNavItem(
                isActive: currentIndex == 3,
                activeColor: theme.primaryColor,
                photoUrl: photoUrl,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Item Navigasi Standar (Icon Only)
class _NavPillItem extends StatelessWidget {
  final bool isActive;
  final IconData icon;
  final Color activeColor;
  final VoidCallback onTap;

  const _NavPillItem({
    required this.isActive,
    required this.icon,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inactive = Colors.grey[500];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.12) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon, 
          size: 26, 
          color: isActive ? activeColor : inactive
        ),
      ),
    );
  }
}

/// Item Navigasi Profil (dengan Foto Avatar)
class _ProfileNavItem extends StatelessWidget {
  final bool isActive;
  final Color activeColor;
  final String? photoUrl;
  final VoidCallback onTap;

  const _ProfileNavItem({
    required this.isActive,
    required this.activeColor,
    required this.photoUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inactive = Colors.grey[500];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.12) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? activeColor : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: isActive ? [
              BoxShadow(
                color: activeColor.withOpacity(0.2),
                blurRadius: 8,
              )
            ] : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: (photoUrl != null && photoUrl!.isNotEmpty)
                ? Image.network(
                    photoUrl!, 
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.person_rounded,
                      size: 20,
                      color: isActive ? activeColor : inactive,
                    ),
                  )
                : Icon(
                    Icons.person_rounded,
                    size: 20,
                    color: isActive ? activeColor : inactive,
                  ),
          ),
        ),
      ),
    );
  }
}

