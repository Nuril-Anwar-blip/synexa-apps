import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Bagian bawah form auth
///
/// Menampilkan tombol login/register via Google dan Facebook.
/// Menggunakan Supabase sebagai backend auth.
class AuthBottomSection extends StatefulWidget {
  const AuthBottomSection({super.key});

  @override
  State<AuthBottomSection> createState() => _AuthBottomSectionState();
}

class _AuthBottomSectionState extends State<AuthBottomSection> {
  final _supabase = Supabase.instance.client;

  bool _googleLoading = false;
  bool _facebookLoading = false;

  // ─── Google Sign In ──────────────────────────────────────────────────────

  Future<void> _signInWithGoogle() async {
    if (_googleLoading || _facebookLoading) return;
    setState(() => _googleLoading = true);
    HapticFeedback.lightImpact();

    try {
      const webClientId = 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';
      const iosClientId = 'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com';

      final googleSignIn = GoogleSignIn(
        clientId: iosClientId,
        serverClientId: webClientId,
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw Exception('Token Google tidak valid');
      }

      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e) {
      if (mounted) _showError('Gagal login dengan Google. Coba lagi.');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  // ─── Facebook Sign In ────────────────────────────────────────────────────

  Future<void> _signInWithFacebook() async {
    if (_googleLoading || _facebookLoading) return;
    setState(() => _facebookLoading = true);
    HapticFeedback.lightImpact();

    try {
      final result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.cancelled) return;

      if (result.status != LoginStatus.success || result.accessToken == null) {
        throw Exception('Login Facebook gagal');
      }

      final token = result.accessToken!.tokenString;

      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.facebook,
        idToken: token,
      );
    } catch (e) {
      if (mounted) _showError('Gagal login dengan Facebook. Coba lagi.');
    } finally {
      if (mounted) setState(() => _facebookLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Divider ────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: Divider(color: Colors.grey.shade200, thickness: 1.2),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'atau lanjutkan dengan',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Divider(color: Colors.grey.shade200, thickness: 1.2),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── Tombol Google & Facebook ────────────────────
        // FIX: logo dibuat di dalam builder, bukan sebagai parameter langsung
        Row(
          children: [
            Expanded(
              child: _SocialButton(
                label: 'Google',
                isLoading: _googleLoading,
                onTap: _signInWithGoogle,
                logoBuilder: () => const _GoogleLogo(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SocialButton(
                label: 'Facebook',
                isLoading: _facebookLoading,
                onTap: _signInWithFacebook,
                logoBuilder: () => const _FacebookLogo(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// HELPER WIDGETS
// ─────────────────────────────────────────────

/// Tombol social login dengan animasi press
///
/// FIX: logo diterima sebagai [logoBuilder] (fungsi) bukan Widget langsung,
/// agar Flutter tidak kehilangan track element saat rebuild.
class _SocialButton extends StatefulWidget {
  const _SocialButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
    required this.logoBuilder,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  /// FIX: pakai builder function, bukan Widget parameter
  final Widget Function() logoBuilder;

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        if (!widget.isLoading) widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: widget.isLoading
              ? Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey.shade400,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // FIX: logo dibuat di sini via builder
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: widget.logoBuilder(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─── Logo Google ─────────────────────────────────────────────────────────────

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GoogleLogoPainter());
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.46;

    void drawArcSegment(double start, double sweep, Color color) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        start,
        sweep,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.5
          ..strokeCap = StrokeCap.butt,
      );
    }

    // 4 warna logo Google
    drawArcSegment(-1.05, 2.09, const Color(0xFF4285F4)); // Biru (kanan)
    drawArcSegment(1.05, 2.09, const Color(0xFF34A853)); // Hijau (bawah)
    drawArcSegment(3.14, 1.05, const Color(0xFFFBBC05)); // Kuning (kiri bawah)
    drawArcSegment(-2.09, 1.05, const Color(0xFFEA4335)); // Merah (kiri atas)

    // Bar horizontal "G"
    canvas.drawRect(
      Rect.fromLTWH(cx - r * 0.08, cy - r * 0.22, r * 0.9, r * 0.44),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Logo Facebook ────────────────────────────────────────────────────────────

class _FacebookLogo extends StatelessWidget {
  const _FacebookLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1877F2),
        borderRadius: BorderRadius.circular(5),
      ),
      alignment: Alignment.center,
      child: const Text(
        'f',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          height: 1.25,
        ),
      ),
    );
  }
}

/**
 * import 'package:flutter/material.dart';

class AuthBottomSection extends StatefulWidget {
  const AuthBottomSection({super.key});

  @override
  State<AuthBottomSection> createState() => _AuthBottomSectionState();
}

class _AuthBottomSectionState extends State<AuthBottomSection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          spacing: 5,
          children: [
            Expanded(child: Divider()),
            Text(
              "atau",
              style: TextStyle(color: Colors.blueGrey, fontSize: 12),
            ),
            Expanded(child: Divider()),
          ],
        ),
        SizedBox(height: 20),
        OutlinedButton(
          onPressed: () {},
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 10,
            children: [
              Image.asset("assets/images/ic_google.png", height: 20),
              Text("Login dengan Google"),
            ],
          ),
        ),
      ],
    );
  }
}

 */
