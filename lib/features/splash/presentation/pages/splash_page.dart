import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/shared_preferences_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/version_text.dart';
import '../../../auth/data/auth_repository.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  // Set to true once you've added the SVG assets
  static const bool _useImageAssets = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // Fire the post-splash work as soon as the screen is up so the latest
    // mobile settings from the server are fetched in parallel with the
    // splash animation. We don't await it here — `_navigateNext` will
    // await the result before deciding where to go.
    unawaited(_bootstrap());
  }

  /// Performs startup work:
  /// 1. Tries to refresh the mobile settings from `/api/GetSettingMobile`
  ///    (only when the user is already logged in — i.e. a base URL + token
  ///    exist). Failures are silently ignored so a flaky network never
  ///    blocks the user from reaching the app.
  /// 2. Once done, navigates to login (no session) or dashboard.
  Future<void> _bootstrap() async {
    final prefs = SharedPreferencesProvider();
    final authRepo = AuthRepository(prefs: prefs);

    // Refresh mobile settings from the server (only if we already have a
    // logged-in session — this API requires Bearer auth).
    try {
      await authRepo.fetchAndSaveMobileSettings();
    } catch (_) {
      // Ignore — the locally cached settings (from the previous login)
      // remain in place and the app stays usable.
    }

    // Small delay so the splash screen stays visible long enough to be seen.
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    final baseUrl = await prefs.getBaseUrl();
    final token = await prefs.getAccessToken();
    if (!mounted) return;
    if (baseUrl.isEmpty || token.isEmpty) {
      context.go(AppRoutes.login);
    } else {
      context.go(AppRoutes.dashboard);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          children: [
            // ── True center logo ─────────────────────────────────────
            Center(
              child: _useImageAssets
                  ? Image.asset(
                      'assets/icons/logo_zerosnap.png',
                      width: 260,
                      fit: BoxFit.contain,
                    )
                  : const _ZeroSnapLogoWidget(),
            ),

            // ── Bottom branding pinned to bottom ─────────────────────
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 44),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Powered by text
                    const Text(
                      'Powered by',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF757575),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 0),
                    // Intellilabs logo
                    Image.asset(
                      'assets/images/intellilabs_logo.png',
                      width: 180,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 4),
                    // Version text
                    const VersionText(
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9E9E9E),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ZeroSnap main logo: Z icon + "ZeroSnap" + "Smart Checkin"
// ─────────────────────────────────────────────────────────────────────────────
class _ZeroSnapLogoWidget extends StatelessWidget {
  const _ZeroSnapLogoWidget();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: CustomPaint(painter: _ZIconPainter()),
            ),
            const SizedBox(width: 10),
            const Text(
              'ZeroSnap',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Color(0xFF29ABE2),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Smart Checkin',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF29ABE2),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

/// Accurately paints the ZeroSnap "Z" icon:
/// - Gold gradient diagonal slash (top-right area)
/// - Blue top-left arc / rounded rectangle
/// - Blue bottom-right semicircle
class _ZIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Gold diagonal bar (center slash) ──────────────────────────
    final goldGradient = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [const Color(0xFFE8C96A), const Color(0xFFB8860B)],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    final goldPaint = Paint()
      ..shader = goldGradient
      ..style = PaintingStyle.fill;

    final goldPath = Path()
      ..moveTo(w * 0.30, h * 0.08)
      ..lineTo(w * 0.92, h * 0.08)
      ..lineTo(w * 0.92, h * 0.28)
      ..lineTo(w * 0.30, h * 0.92)
      ..lineTo(w * 0.08, h * 0.92)
      ..lineTo(w * 0.08, h * 0.72)
      ..close();
    canvas.drawPath(goldPath, goldPaint);

    final bluePaint = Paint()
      ..color = const Color(0xFF29ABE2)
      ..style = PaintingStyle.fill;

    // ── Blue top-left rounded cap ──────────────────────────────────
    final topCapRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.04, h * 0.04, w * 0.44, h * 0.26),
      topLeft: const Radius.circular(6),
      topRight: const Radius.circular(6),
      bottomLeft: const Radius.circular(4),
      bottomRight: const Radius.circular(4),
    );
    canvas.drawRRect(topCapRect, bluePaint);

    // ── Blue bottom-right semicircle ───────────────────────────────
    final bottomArcRect = Rect.fromLTWH(w * 0.30, h * 0.68, w * 0.62, h * 0.28);
    canvas.drawArc(bottomArcRect, 0, 3.14159, false, bluePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
