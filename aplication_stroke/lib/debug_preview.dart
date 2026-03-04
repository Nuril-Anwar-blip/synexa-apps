import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ================================================================
// PREVIEW — jalankan: flutter run -t lib/debug_preview.dart
// Semua kode navbar ada di file ini, TIDAK import widgets/navbar.dart
// ================================================================

void main() {
  runApp(const DebugPreviewApp());
}

class DebugPreviewApp extends StatelessWidget {
  const DebugPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Preview Navbar',
      theme: ThemeData(
        primaryColor: const Color(0xFF0A7AC1),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0A7AC1)),
      ),
      home: const _PreviewPage(),
    );
  }
}

class _PreviewPage extends StatefulWidget {
  const _PreviewPage();

  @override
  State<_PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<_PreviewPage> {
  int _index = 0;

  static const _names = ['Beranda', 'Komunitas', 'Konsultasi', 'Profil'];
  static const _colors = [
    Color(0xFFE3F2FD),
    Color(0xFFF3E8FF),
    Color(0xFFD1FAE5),
    Color(0xFFFEE2E2),
  ];
  static const _icons = [
    Icons.home_rounded,
    Icons.groups_rounded,
    Icons.chat_bubble_rounded,
    Icons.person_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: _colors[_index],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _icons[_index],
              size: 72,
              color: const Color(0xFF0A7AC1).withOpacity(0.25),
            ),
            const SizedBox(height: 16),
            Text(
              _names[_index],
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tab ${_index + 1} dari 4',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _Navbar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        onSosTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(
                    Icons.local_hospital_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Text('SOS ditekan!'),
                ],
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        },
      ),
    );
  }
}

// ================================================================
// NAVBAR — StatelessWidget, zero overflow, zero late field
// ================================================================

const _kBlue = Color(0xFF0A7AC1);

class _Navbar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback? onSosTap;
  final String? photoUrl;

  const _Navbar({
    required this.currentIndex,
    required this.onTap,
    this.onSosTap,
    this.photoUrl,
  });

  void _tap(int i) {
    HapticFeedback.selectionClick();
    onTap(i);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(28, 8, 28, bottom + 14),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.09),
              blurRadius: 20,
              offset: const Offset(0, 6),
              spreadRadius: -2,
            ),
            BoxShadow(
              color: _kBlue.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _Tab(
              icon: Icons.home_rounded,
              isActive: currentIndex == 0,
              onTap: () => _tap(0),
            ),
            _Tab(
              icon: Icons.groups_rounded,
              isActive: currentIndex == 1,
              onTap: () => _tap(1),
            ),
            if (onSosTap != null)
              _Sos(
                onTap: () {
                  HapticFeedback.heavyImpact();
                  onSosTap!();
                },
              ),
            _Tab(
              icon: Icons.chat_bubble_rounded,
              isActive: currentIndex == 2,
              onTap: () => _tap(2),
            ),
            _Tab(
              icon: Icons.person_rounded,
              isActive: currentIndex == 3,
              onTap: () => _tap(3),
              photoUrl: photoUrl,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Item Tab ──────────────────────────────────────────────────────

class _Tab extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final String? photoUrl;

  const _Tab({
    required this.icon,
    required this.isActive,
    required this.onTap,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ikon / avatar
            AnimatedScale(
              scale: isActive ? 1.18 : 1.0,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              child: photoUrl != null
                  ? _Avatar(isActive: isActive, url: photoUrl!)
                  : Icon(
                      icon,
                      size: 24,
                      color: isActive ? _kBlue : Colors.grey.shade400,
                    ),
            ),

            const SizedBox(height: 5),

            // dot indikator
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              width: isActive ? 16 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: _kBlue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Avatar profil ─────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final bool isActive;
  final String url;

  const _Avatar({required this.isActive, required this.url});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? _kBlue : Colors.grey.shade300,
          width: 1.8,
        ),
        color: isActive ? _kBlue.withOpacity(0.08) : Colors.grey.shade50,
      ),
      child: ClipOval(
        child: url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _personIcon(),
              )
            : _personIcon(),
      ),
    );
  }

  Widget _personIcon() => Icon(
    Icons.person_rounded,
    size: 15,
    color: isActive ? _kBlue : Colors.grey.shade400,
  );
}

// ── Tombol SOS ────────────────────────────────────────────────────

class _Sos extends StatefulWidget {
  final VoidCallback onTap;
  const _Sos({required this.onTap});

  @override
  State<_Sos> createState() => _SosState();
}

class _SosState extends State<_Sos> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) =>
              Transform.scale(scale: 0.9 + _ctrl.value * 0.1, child: child),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEF4444),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444).withOpacity(0.38),
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
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
