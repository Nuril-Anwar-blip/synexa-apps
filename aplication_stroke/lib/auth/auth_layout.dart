import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Layout baru untuk halaman auth
/// - Bubble gradient di atas (tidak perlu scroll)
/// - Form card putih di bawah
/// - Tidak ada marginTop yang besar
class AuthLayout extends StatelessWidget {
  final String title;
  final String desc;
  final Widget formField;
  final double marginTop;
  final bool showBackButton;
  final VoidCallback? onBack;

  const AuthLayout({
    super.key,
    required this.title,
    required this.desc,
    required this.formField,
    required this.marginTop,
    this.showBackButton = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Background dekorasi atas ──────────────────────────────────
          _BubbleBackground(),

          // ── Konten utama ─────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // AppBar transparan jika ada back button
                if (showBackButton)
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, top: 4),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                        onPressed: onBack ?? () => Navigator.pop(context),
                      ),
                    ),
                  ),

                // Header area (judul + deskripsi)
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 0),
                  child: _AuthHeader(
                    title: title,
                    desc: desc,
                    showBackButton: showBackButton,
                  ),
                ),

                const SizedBox(height: 20),

                // Form card — scrollable jika konten panjang
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ).copyWith(bottom: 24),
                      child: Column(
                        children: [
                          // Card putih berisi form
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF0A7AC1,
                                  ).withOpacity(0.10),
                                  blurRadius: 32,
                                  offset: const Offset(0, 12),
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 22,
                              ),
                              child: formField,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Support contact
                          const _SupportContact(),
                        ],
                      ),
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

// ─────────────────────────────────────────────────────────────────────────────
// BUBBLE BACKGROUND
// ─────────────────────────────────────────────────────────────────────────────

class _BubbleBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return SizedBox(
      height: size.height * 0.36,
      width: double.infinity,
      child: Stack(
        children: [
          // Gradient utama
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A7AC1), Color(0xFF0D5FAF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Bubble besar kanan atas
          Positioned(
            top: -size.height * 0.12,
            right: -size.width * 0.18,
            child: Container(
              width: size.width * 0.72,
              height: size.width * 0.72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.10),
              ),
            ),
          ),

          // Bubble kecil kiri bawah
          Positioned(
            bottom: size.height * 0.02,
            left: -size.width * 0.08,
            child: Container(
              width: size.width * 0.45,
              height: size.width * 0.45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),

          // Gelombang bawah (wave)
          Positioned(
            bottom: -1,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: _WaveClipper(),
              child: Container(height: 48, color: const Color(0xFFF5F7FA)),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(
      size.width * 0.25,
      0,
      size.width * 0.5,
      size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height,
      size.width,
      size.height * 0.2,
    );
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _AuthHeader extends StatelessWidget {
  final String title;
  final String desc;
  final bool showBackButton;

  const _AuthHeader({
    required this.title,
    required this.desc,
    required this.showBackButton,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: showBackButton ? 4 : 52),

        // Badge "Terhubung dengan tenaga kesehatan"
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.verified_rounded, color: Colors.white, size: 16),
              SizedBox(width: 6),
              Text(
                'Terhubung dengan tenaga kesehatan',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        Text(
          title,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
            height: 1.1,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          desc,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUPPORT CONTACT
// ─────────────────────────────────────────────────────────────────────────────

class _SupportContact extends StatelessWidget {
  const _SupportContact();

  Future<void> _openWhatsApp(BuildContext context) async {
    const phone = "6285879571393";
    final message = Uri.encodeComponent(
      "Halo! Saya butuh bantuan dengan aplikasi Smart Stroke.",
    );
    final url = Uri.parse("https://wa.me/$phone?text=$message");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Gagal membuka WhatsApp")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Ada kendala saat masuk?',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _openWhatsApp(context),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.10),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.green.withOpacity(0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.support_agent, color: Colors.green, size: 18),
                SizedBox(width: 8),
                Text(
                  'Hubungi via WhatsApp',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
