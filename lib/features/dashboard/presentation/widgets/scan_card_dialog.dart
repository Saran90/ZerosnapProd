import 'package:flutter/material.dart';
import 'choose_card_dialog.dart';

void showScanCardDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => const _ScanCardDialog(),
  );
}

class _ScanCardDialog extends StatelessWidget {
  const _ScanCardDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Scan icon
            const _ScanIcon(),

            const SizedBox(height: 32),

            // Scan Domestic Card
            _ScanButton(
              label: 'Scan Domestic Card',
              onTap: () {
                Navigator.of(context).pop();
                showChooseCardDialog(
                  context,
                  onSelected: (cardType) {
                    // TODO: handle selected card type
                    debugPrint('Selected: ${cardType.label}');
                  },
                );
              },
            ),

            const SizedBox(height: 14),

            // Scan Passport
            _ScanButton(
              label: 'Scan Passport',
              onTap: () {
                Navigator.of(context).pop();
                // TODO: navigate to passport scan
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Scan icon: card inside a scan frame ───────────────────────────────────────
class _ScanIcon extends StatelessWidget {
  const _ScanIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 80,
      child: CustomPaint(painter: _ScanIconPainter()),
    );
  }
}

class _ScanIconPainter extends CustomPainter {
  static const _color = Color(0xFF29ABE2);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = _color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    const corner = 10.0;
    const arm = 18.0;

    // ── Corner brackets ───────────────────────────────────────────
    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(0, arm)
        ..lineTo(0, corner)
        ..arcToPoint(Offset(corner, 0), radius: const Radius.circular(corner))
        ..lineTo(arm, 0),
      strokePaint,
    );
    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(w - arm, 0)
        ..lineTo(w - corner, 0)
        ..arcToPoint(Offset(w, corner), radius: const Radius.circular(corner))
        ..lineTo(w, arm),
      strokePaint,
    );
    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(0, h - arm)
        ..lineTo(0, h - corner)
        ..arcToPoint(
          Offset(corner, h),
          radius: const Radius.circular(corner),
          clockwise: false,
        )
        ..lineTo(arm, h),
      strokePaint,
    );
    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(w - arm, h)
        ..lineTo(w - corner, h)
        ..arcToPoint(
          Offset(w, h - corner),
          radius: const Radius.circular(corner),
          clockwise: false,
        )
        ..lineTo(w, h - arm),
      strokePaint,
    );

    // ── Card shape inside ─────────────────────────────────────────
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.12, h * 0.20, w * 0.76, h * 0.58),
      const Radius.circular(8),
    );
    canvas.drawRRect(cardRect, paint);

    // ── White stripe on card ──────────────────────────────────────
    final stripePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(w * 0.12, h * 0.34, w * 0.76, h * 0.16),
      stripePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Reusable pill button ──────────────────────────────────────────────────────
class _ScanButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ScanButton({required this.label, required this.onTap});

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
