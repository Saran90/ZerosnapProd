import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/scan_card_dialog.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  // Set to true once assets/images/dashboard_character.png is added
  static const bool _useCharacterAsset = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Top hero image expands to fill remaining space ──────────
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Character / hero image
                ClipPath(
                  clipper: _BottomCurveClipper(),
                  child: _useCharacterAsset
                      ? Image.asset(
                          'assets/images/dashboard_image.png',
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          errorBuilder: (context, error, stackTrace) =>
                              const _PlaceholderHero(),
                        )
                      : const _PlaceholderHero(),
                ),

                // Settings icon top-right
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  right: 16,
                  child: GestureDetector(
                    onTap: () {},
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

          // ── Bottom content — takes only its natural height ──────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 40),

                // ZeroSnap logo
                Image.asset(
                  'assets/icons/logo_zerosnap.png',
                  height: 60,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 36),

                // Guest List button
                _DashboardButton(
                  label: 'Guest List',
                  onTap: () => context.go(AppRoutes.guestList),
                ),

                const SizedBox(height: 12),

                // Scan Card button
                _DashboardButton(
                  label: 'Scan Card',
                  onTap: () => showScanCardDialog(context),
                ),
              ],
            ),
          ),

          // Version pinned to bottom
          const Padding(
            padding: EdgeInsets.only(bottom: 30, top: 24),
            child: Text(
              'version 1.0',
              style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Clips the hero image with a curved bottom ─────────────────────────────────
class _BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width * 0.50, size.height);
    // Convex (outward) curve — control points pushed beyond the right edge
    path.cubicTo(
      size.width * 1.10,
      size.height, // cp1: far right, stays at bottom
      size.width * 1.10,
      size.height * 0.55, // cp2: far right, pulls up
      size.width,
      size.height * 0.55, // end: right edge at ~55% height
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ── Placeholder when character image is not yet added ────────────────────────
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

// ── Dashboard pill button matching Figma style ────────────────────────────────
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
