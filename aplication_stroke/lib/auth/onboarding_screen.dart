import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _controller = PageController();
  int _currentIndex = 0;

  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnim;
  late Animation<double> _pulseAnim;

  final _pages = const [
    _PageData(
      title: 'Deteksi Risiko\nStroke Lebih Awal',
      description:
          'Pantau tekanan darah, detak jantung, dan faktor risiko stroke setiap hari. '
          'Dapatkan peringatan dini sebelum terlambat.',
      icon: Icons.monitor_heart_rounded,
      gradient: [Color(0xFF0A7AC1), Color(0xFF0E5FAF)],
      accentColor: Color(0xFF38BDF8),
      stats: [
        _StatData(value: '87%', label: 'Stroke\ndapat dicegah'),
        _StatData(value: '2×', label: 'Deteksi lebih\ncepat'),
        _StatData(value: '24/7', label: 'Pemantauan\naktif'),
      ],
      features: [
        _FeatureData(
          icon: Icons.favorite_rounded,
          label: 'Monitor tekanan darah',
        ),
        _FeatureData(
          icon: Icons.warning_amber_rounded,
          label: 'Peringatan risiko dini',
        ),
        _FeatureData(
          icon: Icons.bar_chart_rounded,
          label: 'Grafik tren kesehatan',
        ),
      ],
    ),
    _PageData(
      title: 'Rehabilitasi\nTerstruktur & Terarah',
      description:
          'Program latihan rehabilitasi pascastroke yang dirancang oleh tenaga medis, '
          'fase demi fase sesuai kondisi Anda.',
      icon: Icons.self_improvement_rounded,
      gradient: [Color(0xFF059669), Color(0xFF047857)],
      accentColor: Color(0xFF34D399),
      stats: [
        _StatData(value: '3×', label: 'Lebih cepat\npulih'),
        _StatData(value: '50+', label: 'Latihan\ntersedia'),
        _StatData(value: '95%', label: 'Pengguna\npuas'),
      ],
      features: [
        _FeatureData(
          icon: Icons.fitness_center_rounded,
          label: 'Latihan terpandu',
        ),
        _FeatureData(
          icon: Icons.timeline_rounded,
          label: 'Progres fase per fase',
        ),
        _FeatureData(
          icon: Icons.video_library_rounded,
          label: 'Panduan gerakan visual',
        ),
      ],
    ),
    _PageData(
      title: 'Terapi Obat\nTidak Terlewat',
      description:
          'Pengingat obat cerdas dan jadwal terapi yang dipantau langsung oleh apoteker '
          'terpercaya untuk hasil terbaik.',
      icon: Icons.medication_rounded,
      gradient: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
      accentColor: Color(0xFFA78BFA),
      stats: [
        _StatData(value: '99%', label: 'Tidak ada\nobat terlewat'),
        _StatData(value: '30+', label: 'Apoteker\naktif'),
        _StatData(value: '1 jam', label: 'Respons\nkonsultasi'),
      ],
      features: [
        _FeatureData(
          icon: Icons.alarm_rounded,
          label: 'Pengingat obat otomatis',
        ),
        _FeatureData(
          icon: Icons.local_pharmacy_rounded,
          label: 'Pantauan apoteker',
        ),
        _FeatureData(icon: Icons.chat_rounded, label: 'Konsultasi realtime'),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_currentIndex < _pages.length - 1) {
      _fadeController.reset();
      _controller.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _fadeController.forward();
      });
    } else {
      _finish();
    }
  }

  void _finish() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, anim, __) =>
            FadeTransition(opacity: anim, child: const LoginScreen()),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentIndex];
    final size = MediaQuery.sizeOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // ── Background gradient berubah per slide ──────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutCubic,
              height: size.height * 0.52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: page.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

            // ── Wave clipper di batas gradient ─────────────────────────
            Positioned(
              top: size.height * 0.48,
              left: 0,
              right: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOutCubic,
                child: ClipPath(
                  clipper: _WaveClipper(),
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: page.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Dekorasi lingkaran translucent ─────────────────────────
            Positioned(
              top: -40,
              right: -40,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.07),
                ),
              ),
            ),
            Positioned(
              top: 60,
              left: -60,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // ── Top bar ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // App name
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.favorite_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Smart Stroke',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        // Skip button
                        TextButton(
                          onPressed: _finish,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white.withOpacity(0.85),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                          ),
                          child: const Text(
                            'Lewati',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── PageView ─────────────────────────────────────────
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _pages.length,
                      onPageChanged: (i) {
                        HapticFeedback.selectionClick();
                        setState(() => _currentIndex = i);
                        _fadeController.reset();
                        _fadeController.forward();
                      },
                      itemBuilder: (_, i) => _OnboardPage(
                        page: _pages[i],
                        fadeAnim: _fadeAnim,
                        pulseAnim: _pulseAnim,
                        isActive: i == _currentIndex,
                      ),
                    ),
                  ),

                  // ── Bottom controls ───────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    child: Column(
                      children: [
                        // Dots indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_pages.length, (i) {
                            final isActive = i == _currentIndex;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              width: isActive ? 28 : 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: isActive
                                    ? page.gradient.first
                                    : Colors.grey.shade300,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 20),

                        // Tombol Lanjut / Mulai
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: page.gradient,
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: page.gradient.first.withOpacity(0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _goNext,
                                borderRadius: BorderRadius.circular(16),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _currentIndex == _pages.length - 1
                                            ? 'Mulai Sekarang'
                                            : 'Lanjut',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        _currentIndex == _pages.length - 1
                                            ? Icons.rocket_launch_rounded
                                            : Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ONBOARD PAGE
// ─────────────────────────────────────────────────────────────────────────────

class _OnboardPage extends StatelessWidget {
  const _OnboardPage({
    required this.page,
    required this.fadeAnim,
    required this.pulseAnim,
    required this.isActive,
  });

  final _PageData page;
  final Animation<double> fadeAnim;
  final Animation<double> pulseAnim;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          // ── Ilustrasi ikon di area gradient ──────────────────────────
          SizedBox(
            height: 210,
            child: Center(
              child: FadeTransition(
                opacity: fadeAnim,
                child: AnimatedBuilder(
                  animation: pulseAnim,
                  builder: (_, child) => Transform.scale(
                    scale: isActive ? pulseAnim.value : 1.0,
                    child: child,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Lingkaran luar glow
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      // Lingkaran tengah
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                      // Ikon utama
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          page.icon,
                          size: 50,
                          color: page.gradient.first,
                        ),
                      ),
                      // Badge accent di pojok kanan atas
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: page.accentColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Konten teks & info ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
            child: FadeTransition(
              opacity: fadeAnim,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul
                  Text(
                    page.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      height: 1.2,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Deskripsi
                  Text(
                    page.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Stats row
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: page.stats
                          .map(
                            (s) =>
                                _StatItem(stat: s, color: page.gradient.first),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Feature list
                  ...page.features.map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: page.gradient.first.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              f.icon,
                              size: 18,
                              color: page.gradient.first,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            f.label,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.stat, required this.color});

  final _StatData stat;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          stat.value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          stat.label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade500,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WAVE CLIPPER
// ─────────────────────────────────────────────────────────────────────────────

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, 0);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.8,
      size.width * 0.5,
      size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.2,
      size.width,
      size.height * 0.6,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

class _PageData {
  const _PageData({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.accentColor,
    required this.stats,
    required this.features,
  });

  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradient;
  final Color accentColor;
  final List<_StatData> stats;
  final List<_FeatureData> features;
}

class _StatData {
  const _StatData({required this.value, required this.label});
  final String value;
  final String label;
}

class _FeatureData {
  const _FeatureData({required this.icon, required this.label});
  final IconData icon;
  final String label;
}
