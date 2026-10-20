import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../scan/presentation/pages/domestic_card_scan_page.dart';
import '../../../scan/presentation/pages/domestic_passport_scan_page.dart';
import '../../../scan/presentation/pages/passport_card_scan_page_domestic.dart';
import '../../../scan/presentation/pages/passport_card_scan_page_landing.dart';

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

// ── Passport entry point ──────────────────────────────────────────────────────

/// Entry point for passport scanning.
/// Always shows Camera / Gallery chooser using OCR-based flow.
///
/// [isDomesticCardFlow] indicates whether this is being called from:
/// - true: Domestic card flow (use PassportCardScanPageDomestic - no visa)
/// - false: Landing screen flow (use PassportCardScanPageLanding - with visa)
void showPassportSourceDialog(
  BuildContext context, {
  bool isDomesticCardFlow = false,
}) {
  // Always use the root navigator to ensure pushes work correctly even when
  // called from inside a dialog (where the local navigator may be stale).
  final nav = Navigator.of(context, rootNavigator: true);

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
            // ── Camera ──────────────────────────────────────────────
            _PassportOptionButton(
              label: 'Open Camera',
              onTap: () async {
                Navigator.of(dialogCtx).pop();
                if (!nav.context.mounted) return;
                // OCR flow — open appropriate page with camera auto-launch
                final targetPage = isDomesticCardFlow
                    ? const PassportCardScanPageDomestic(autoOpenCamera: true)
                    : const PassportCardScanPageLanding(autoOpenCamera: true);
                nav.push(MaterialPageRoute(builder: (_) => targetPage));
              },
            ),
            const SizedBox(height: 12),
            // ── Gallery ─────────────────────────────────────────────
            _PassportOptionButton(
              label: 'Upload',
              onTap: () async {
                Navigator.of(dialogCtx).pop();
                if (!nav.context.mounted) return;
                // OCR flow — pick image then open appropriate page
                final picked = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 100,
                );
                if (picked == null || !nav.context.mounted) return;
                final targetPage = isDomesticCardFlow
                    ? PassportCardScanPageDomestic(
                        initialFrontImagePath: picked.path,
                      )
                    : PassportCardScanPageLanding(
                        initialFrontImagePath: picked.path,
                      );
                nav.push(MaterialPageRoute(builder: (_) => targetPage));
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

// ── Choose card dialog ────────────────────────────────────────────────────────

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
            color: AppColors.primary.withValues(alpha: 0.08),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: const Text(
              'Choose Card',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),

          ..._buildItem(
            context,
            label: 'Driving License',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (_) => const DomesticCardScanPage(
                    cardType: DomesticCardType.drivingLicense,
                  ),
                ),
              );
            },
          ),
          ..._buildItem(
            context,
            label: 'Aadhar',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (_) => const DomesticCardScanPage(
                    cardType: DomesticCardType.aadhar,
                  ),
                ),
              );
            },
          ),
          ..._buildItem(
            context,
            label: 'Voters ID',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (_) => const DomesticCardScanPage(
                    cardType: DomesticCardType.votersId,
                  ),
                ),
              );
            },
          ),
          ..._buildItem(
            context,
            label: 'PAN Card',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (_) => const DomesticCardScanPage(
                    cardType: DomesticCardType.panCard,
                  ),
                ),
              );
            },
          ),
          // ── Passport ─────────────────────────────────────────────
          ..._buildItem(
            context,
            label: 'Passport',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (_) => const DomesticPassportScanPage(),
                ),
              );
            },
          ),
          ..._buildItem(
            context,
            label: 'Other ID',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (_) => const DomesticCardScanPage(
                    cardType: DomesticCardType.otherId,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  List<Widget> _buildItem(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
  }) {
    return [
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
      const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
    ];
  }
}

// ── Passport option button ────────────────────────────────────────────────────

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
          color: filled ? AppColors.accent : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: filled
              ? null
              : Border.all(color: AppColors.accent, width: 1.5),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.30),
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
            color: filled ? Colors.white : AppColors.primary,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
