import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ================================================================
/// CUSTOM NAVBAR — Glassmorphism Floating Pill
/// ================================================================
/// Desain:
/// - Melayang dengan efek glass blur transparan
/// - Tab aktif: pill berwarna gradient dengan label muncul
/// - Tab tidak aktif: ikon abu minimalis
/// - Tab profil: foto avatar user
/// - Tombol SOS merah di tengah (opsional)
/// - Animasi smooth perpindahan tab
/// - Haptic feedback tiap tap
/// ================================================================
class CustomNavbar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String? photoUrl;

  /// Callback tombol SOS (null = tombol SOS tidak ditampilkan)
  final VoidCallback? onSosTap;

  const CustomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.photoUrl,
    this.onSosTap,
  });

  @override
  State<CustomNavbar> createState() => _CustomNavbarState();
}

class _CustomNavbarState extends State<CustomNavbar>
    with TickerProviderStateMixin {
  // Controller animasi untuk setiap item
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _expandAnims;
  late final List<Animation<double>> _fadeAnims;

  // Data tab
  static const _tabs = [
    _TabData(icon: Icons.home_rounded, label: 'Beranda'),
    _TabData(icon: Icons.groups_rounded, label: 'Komunitas'),
    _TabData(icon: Icons.chat_bubble_rounded, label: 'Konsultasi'),
    _TabData(icon: Icons.person_rounded, label: 'Profil'),
  ];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _tabs.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 350),
        value: i == widget.currentIndex ? 1.0 : 0.0,
      ),
    );

    _expandAnims = _controllers.map((c) {
      return CurvedAnimation(parent: c, curve: Curves.easeOutCubic);
    }).toList();

    _fadeAnims = _controllers.map((c) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: c,
          curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
        ),
      );
    }).toList();
  }

  @override
  void didUpdateWidget(CustomNavbar old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _controllers[old.currentIndex].reverse();
      _controllers[widget.currentIndex].forward();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  void _handleTap(int index) {
    HapticFeedback.selectionClick();
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final hasSos = widget.onSosTap != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 12),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A7AC1).withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Tab Beranda
            _buildTab(0),
            // Tab Komunitas
            _buildTab(1),

            // Tombol SOS di tengah (jika ada)
            if (hasSos) _SosButton(onTap: widget.onSosTap!),

            // Tab Konsultasi
            _buildTab(2),
            // Tab Profil
            _buildProfileTab(3),
          ],
        ),
      ),
    );
  }

  /// Build tab standar
  Widget _buildTab(int index) {
    final tab = _tabs[index];
    final isActive = widget.currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _handleTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _expandAnims[index],
          builder: (_, __) {
            return Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                height: 40,
                padding: EdgeInsets.symmetric(horizontal: isActive ? 14 : 0),
                decoration: BoxDecoration(
                  gradient: isActive
                      ? const LinearGradient(
                          colors: [Color(0xFF0A7AC1), Color(0xFF0B5EA8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ikon
                    Icon(
                      tab.icon,
                      size: 22,
                      color: isActive ? Colors.white : Colors.grey.shade400,
                    ),

                    // Label — muncul saat aktif
                    ClipRect(
                      child: SizeTransition(
                        sizeFactor: _expandAnims[index],
                        axis: Axis.horizontal,
                        child: FadeTransition(
                          opacity: _fadeAnims[index],
                          child: Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Text(
                              tab.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Build tab profil dengan foto user
  Widget _buildProfileTab(int index) {
    final isActive = widget.currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _handleTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _expandAnims[index],
          builder: (_, __) {
            return Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                height: 40,
                padding: EdgeInsets.symmetric(horizontal: isActive ? 10 : 0),
                decoration: BoxDecoration(
                  gradient: isActive
                      ? const LinearGradient(
                          colors: [Color(0xFF0A7AC1), Color(0xFF0B5EA8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Avatar
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isActive
                              ? Colors.white.withOpacity(0.6)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: ClipOval(child: _buildAvatar(isActive)),
                    ),

                    // Label — muncul saat aktif
                    ClipRect(
                      child: SizeTransition(
                        sizeFactor: _expandAnims[index],
                        axis: Axis.horizontal,
                        child: FadeTransition(
                          opacity: _fadeAnims[index],
                          child: const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Text(
                              'Profil',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isActive) {
    final url = widget.photoUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _avatarFallback(isActive),
      );
    }
    return _avatarFallback(isActive);
  }

  Widget _avatarFallback(bool isActive) {
    return Container(
      color: isActive ? Colors.white.withOpacity(0.2) : Colors.grey.shade100,
      child: Icon(
        Icons.person_rounded,
        size: 16,
        color: isActive ? Colors.white : Colors.grey.shade400,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TOMBOL SOS
// ─────────────────────────────────────────────

/// Tombol SOS merah berkedip di tengah navbar
class _SosButton extends StatefulWidget {
  const _SosButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<_SosButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.heavyImpact();
          widget.onTap();
        },
        child: AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, child) =>
              Transform.scale(scale: _pulseAnim.value, child: child),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.red.shade500, Colors.red.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.4),
                  blurRadius: 14,
                  spreadRadius: -2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'SOS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────

class _TabData {
  final IconData icon;
  final String label;
  const _TabData({required this.icon, required this.label});
}
