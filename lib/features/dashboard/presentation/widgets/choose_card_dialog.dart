import 'package:flutter/material.dart';
import '../../../scan/presentation/pages/card_scan_page.dart';
import '../../../scan/presentation/pages/mrz_scanner_page.dart';
import '../../../scan/presentation/pages/passport_card_scan_page.dart';

enum DomesticCardType { drivingLicense, aadhar, votersId, panCard, otherId }

extension DomesticCardTypeLabel on DomesticCardType {
  String get label {
    switch (this) {
      case DomesticCardType.drivingLicense:
        return 'Driving License';
      case DomesticCardType.aadhar:
        return 'Aadhar';
      case DomesticCardType.votersId:
        return 'Voters ID';
      case DomesticCardType.panCard:
        return 'PAN Card';
      case DomesticCardType.otherId:
        return 'Other ID';
    }
  }
}

/// Shows the passport source picker (Camera / Upload).
/// Extracted here so both [showChooseCardDialog] and [scan_card_dialog] can use it.
void showPassportSourceDialog(BuildContext context) {
  final nav = Navigator.of(context);
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (dialogCtx) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icons/ic_upload.png',
              width: 72,
              height: 72,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 28),
            _PassportOptionButton(
              label: 'Open Camera',
              onTap: () {
                Navigator.of(dialogCtx).pop();
                nav.push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const MrzScannerPage(title: 'Scan Passport'),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _PassportOptionButton(
              label: 'Upload',
              onTap: () {
                Navigator.of(dialogCtx).pop();
                nav.push(
                  MaterialPageRoute(
                    builder: (_) => const MrzScannerPage(
                      title: 'Upload Passport',
                      fromGallery: true,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _PassportOptionButton(
              label: 'Cancel',
              filled: false,
              onTap: () => Navigator.of(dialogCtx).pop(),
            ),
          ],
        ),
      ),
    ),
  );
}

void showChooseCardDialog(
  BuildContext context, {
  required void Function(DomesticCardType) onSelected,
}) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => _ChooseCardDialog(onSelected: onSelected),
  );
}

class _ChooseCardDialog extends StatelessWidget {
  final void Function(DomesticCardType) onSelected;
  const _ChooseCardDialog({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final options = DomesticCardType.values;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────
          Container(
            width: double.infinity,
            color: const Color(0xFFDCF0FA),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: const Text(
              'Choose Card',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),

          // ── Domestic card options ────────────────────────────────
          ...List.generate(options.length, (i) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    final nav = Navigator.of(context);
                    nav.pop();
                    nav.push(
                      MaterialPageRoute(
                        builder: (_) => CardScanPage(cardType: options[i]),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        options[i].label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                  ),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFE0E0E0),
                ),
              ],
            );
          }),

          // ── Passport option ──────────────────────────────────────
          InkWell(
            onTap: () {
              final nav = Navigator.of(context);
              nav.pop();
              nav.push(
                MaterialPageRoute(builder: (_) => const PassportCardScanPage()),
              );
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Passport',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _PassportOptionButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _PassportOptionButton({
    required this.label,
    required this.onTap,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: filled ? const Color(0xFF29ABE2) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: filled
              ? null
              : Border.all(color: const Color(0xFF29ABE2), width: 1.5),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: const Color(0xFF29ABE2).withValues(alpha: 0.30),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: filled ? Colors.white : const Color(0xFF2C3E50),
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
