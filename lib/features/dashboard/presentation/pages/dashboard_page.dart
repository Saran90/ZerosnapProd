import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/version_text.dart';
import '../widgets/scan_card_dialog.dart';
import '../../../settings/presentation/pages/settings_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    // Hero takes 52% of screen — leaves enough room for content on all sizes
    final heroH = screenH * 0.52;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Hero image ──────────────────────────────────────────────
          SizedBox(
            height: heroH,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipPath(
                  clipper: _BottomCurveClipper(),
                  child: Image.asset(
                    'assets/images/dashboard_image.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (_, __, ___) => const _PlaceholderHero(),
                  ),
                ),
                // Settings icon
                Positioned(
                  top: topPad + 12,
                  right: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
                    ),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.settings_outlined,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom content fills remaining space ────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset(
                    'assets/icons/logo_zerosnap.png',
                    height: 52,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 32),

                  _DashboardButton(
                    label: 'Guest List',
                    onTap: () => context.go(AppRoutes.guestList),
                  ),

                  const SizedBox(height: 14),

                  _DashboardButton(
                    label: 'Scan Card',
                    onTap: () => showScanCardDialog(context),
                  ),
                ],
              ),
            ),
          ),

          // Version
          Padding(
            padding: EdgeInsets.only(bottom: bottomPad + 16, top: 8),
            child: const VersionText(
              style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Curved bottom clipper ─────────────────────────────────────────────────────
class _BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width * 0.50, size.height);
    path.cubicTo(
      size.width * 1.10,
      size.height,
      size.width * 1.10,
      size.height * 0.55,
      size.width,
      size.height * 0.55,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ── Placeholder hero ──────────────────────────────────────────────────────────
class _PlaceholderHero extends StatelessWidget {
  const _PlaceholderHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFD6EAF8), Color(0xFFAED6F1)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.person, size: 100, color: Color(0xFF5DADE2)),
      ),
    );
  }
}

// ── Pill button ───────────────────────────────────────────────────────────────
class _DashboardButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DashboardButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF29ABE2),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF29ABE2).withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
