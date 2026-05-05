import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/shared_preferences_provider.dart';
import '../../../../core/router/app_router.dart';

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

    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;
      // If no domain saved yet, go to login; otherwise go to dashboard
      final prefs = SharedPreferencesProvider();
      final baseUrl = await prefs.getBaseUrl();
      final token = await prefs.getAccessToken();
      if (!mounted) return;
      if (baseUrl.isEmpty || token.isEmpty) {
        context.go(AppRoutes.login);
      } else {
        context.go(AppRoutes.dashboard);
      }
    });
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
                    _useImageAssets
                        ? Image.asset(
                            'assets/icons/logo_z.png',
                            width: 72,
                            fit: BoxFit.contain,
                          )
                        : const _OzoLogoWidget(),
                    const SizedBox(height: 6),
                    const Text(
                      'version 1.0',
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

// ─────────────────────────────────────────────────────────────────────────────
// OZO infinity logo: two loops with a Z-shaped connector, blue gradient
// ─────────────────────────────────────────────────────────────────────────────
class _OzoLogoWidget extends StatelessWidget {
  const _OzoLogoWidget();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 40,
      child: CustomPaint(painter: _OzoPainter()),
    );
  }
}

class _OzoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [const Color(0xFF3B5BDB), const Color(0xFF74C0FC)],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    final paint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Left loop (C shape opening right)
    final leftLoop = Path()
      ..moveTo(w * 0.32, h * 0.18)
      ..cubicTo(w * 0.10, h * 0.05, w * -0.02, h * 0.35, w * 0.05, h * 0.55)
      ..cubicTo(w * 0.10, h * 0.72, w * 0.28, h * 0.82, w * 0.38, h * 0.72)
      ..cubicTo(w * 0.46, h * 0.62, w * 0.44, h * 0.48, w * 0.36, h * 0.42)
      ..cubicTo(w * 0.28, h * 0.36, w * 0.20, h * 0.40, w * 0.20, h * 0.50);
    canvas.drawPath(leftLoop, paint);

    // Center Z connector
    final zPath = Path()
      ..moveTo(w * 0.36, h * 0.22)
      ..lineTo(w * 0.62, h * 0.22)
      ..lineTo(w * 0.36, h * 0.78)
      ..lineTo(w * 0.62, h * 0.78);
    canvas.drawPath(zPath, paint);

    // Right loop (D shape opening left)
    final rightLoop = Path()
      ..moveTo(w * 0.62, h * 0.28)
      ..cubicTo(w * 0.72, h * 0.18, w * 0.90, h * 0.18, w * 0.96, h * 0.38)
      ..cubicTo(w * 1.02, h * 0.58, w * 0.90, h * 0.80, w * 0.72, h * 0.82)
      ..cubicTo(w * 0.58, h * 0.84, w * 0.52, h * 0.68, w * 0.58, h * 0.58)
      ..cubicTo(w * 0.62, h * 0.50, w * 0.72, h * 0.48, w * 0.76, h * 0.52);
    canvas.drawPath(rightLoop, paint);

    // TM superscript
    final tmPaint = Paint()
      ..color = const Color(0xFF3B5BDB)
      ..style = PaintingStyle.fill;
    final tmStyle = const TextStyle(
      fontSize: 7,
      fontWeight: FontWeight.w700,
      color: Color(0xFF3B5BDB),
    );
    final tmSpan = TextSpan(text: '™', style: tmStyle);
    final tmPainter = TextPainter(
      text: tmSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    tmPainter.paint(canvas, Offset(w - 10, 0));
    tmPaint.toString(); // suppress unused warning
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
