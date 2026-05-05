import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mrzscanner_flutter/mrzscanner_flutter.dart';
import '../../../../core/network/shared_preferences_provider.dart';
import '../../../scan/presentation/pages/card_scan_page.dart';
import '../../../scan/presentation/pages/mrz_scanner_page.dart';
import '../../../scan/presentation/pages/passport_card_scan_page.dart';
import '../../../scan/presentation/pages/passport_form_page.dart';
import '../../../scan/presentation/widgets/duplicate_guest_checker.dart';

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

// ── MRZ scanner helper ────────────────────────────────────────────────────────

/// Runs the MRZ passport camera scanner directly (no intermediate Flutter page).
/// On success navigates to [PassportFormPage]. On cancel/error does nothing.
Future<void> _runMrzPassportScanner(NavigatorState nav) async {
  try {
    MrzScannerPage.setupForPassport();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!nav.context.mounted) return;
    final String raw = await Mrzflutterplugin.startScanner;
    if (!nav.context.mounted) return;
    if (raw.isEmpty || raw == 'null' || raw.startsWith('Error:')) return;
    final result = MrzScannerPage.parseMrz(raw);
    // Check for duplicate before navigating to the form
    final isDuplicate = await checkAndHandleDuplicate(
      nav.context,
      documentNo: result.documentNumber ?? '',
      cardType: GuestCardType.passport,
    );
    if (isDuplicate || !nav.context.mounted) return;
    nav.push(
      MaterialPageRoute(
        builder: (_) => PassportFormPage(scannedResult: result),
      ),
    );
  } on PlatformException catch (ex) {
    if (!nav.context.mounted) return;
    if (ex.message?.contains('scannerWasDismissed') == true) return;
    ScaffoldMessenger.of(nav.context).showSnackBar(
      SnackBar(
        content: Text(ex.message ?? 'Scanner failed'),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Runs the MRZ gallery scan directly (no intermediate Flutter page).
/// On success navigates to [PassportFormPage]. On cancel/error does nothing.
Future<void> _runMrzGalleryScan(NavigatorState nav) async {
  try {
    MrzScannerPage.setupForPassport();
    // Longer delay for gallery scan — more config messages need to be
    // processed by the native side before scanFromGallery is called.
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!nav.context.mounted) return;
    final String raw = await Mrzflutterplugin.scanFromGallery;
    if (!nav.context.mounted) return;

    // User cancelled
    if (raw.isEmpty || raw == 'null') return;

    // MRZ extraction failed — open form for manual entry
    if (raw.startsWith('Error:')) {
      if (raw.contains('scannerWasDismissed')) return;
      ScaffoldMessenger.of(nav.context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not read MRZ from image. Please fill in details manually.',
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      nav.push(MaterialPageRoute(builder: (_) => const PassportFormPage()));
      return;
    }

    final result = MrzScannerPage.parseMrz(raw);
    // Check for duplicate before navigating to the form
    final isDuplicate = await checkAndHandleDuplicate(
      nav.context,
      documentNo: result.documentNumber ?? '',
      cardType: GuestCardType.passport,
    );
    if (isDuplicate || !nav.context.mounted) return;
    nav.push(
      MaterialPageRoute(
        builder: (_) => PassportFormPage(scannedResult: result),
      ),
    );
  } on PlatformException catch (ex) {
    if (!nav.context.mounted) return;
    if (ex.message?.contains('scannerWasDismissed') == true) return;
    // scanImageFailed — open form for manual entry
    if (ex.message?.contains('scanImageFailed') == true) {
      ScaffoldMessenger.of(nav.context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not read MRZ from image. Please fill in details manually.',
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      nav.push(MaterialPageRoute(builder: (_) => const PassportFormPage()));
      return;
    }
    ScaffoldMessenger.of(nav.context).showSnackBar(
      SnackBar(
        content: Text(ex.message ?? 'Gallery scan failed'),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ── Passport entry point ──────────────────────────────────────────────────────

/// Entry point for passport scanning.
/// Always shows Camera / Gallery chooser.
/// - AppScanByMRZ=1 → Camera calls MRZ scanner, Gallery calls MRZ gallery scan
/// - AppScanByMRZ=0 → Camera opens PassportCardScanPage, Gallery uses ImagePicker
void showPassportSourceDialog(BuildContext context) {
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
                final session = await SharedPreferencesProvider()
                    .getLoginSession();
                final useMrz = session?.scanByMrz ?? true;
                if (!nav.context.mounted) return;
                if (useMrz) {
                  // MRZ camera scan → PassportFormPage
                  await _runMrzPassportScanner(nav);
                } else {
                  // OCR flow
                  nav.push(
                    MaterialPageRoute(
                      builder: (_) => const PassportCardScanPage(),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            // ── Gallery ─────────────────────────────────────────────
            _PassportOptionButton(
              label: 'Upload',
              onTap: () async {
                Navigator.of(dialogCtx).pop();
                final session = await SharedPreferencesProvider()
                    .getLoginSession();
                final useMrz = session?.scanByMrz ?? true;
                if (!nav.context.mounted) return;
                if (useMrz) {
                  // MRZ gallery scan → PassportFormPage
                  await _runMrzGalleryScan(nav);
                } else {
                  // OCR flow — pick image then open PassportCardScanPage
                  final picked = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 100,
                  );
                  if (picked == null || !nav.context.mounted) return;
                  nav.push(
                    MaterialPageRoute(
                      builder: (_) => PassportCardScanPage(
                        initialFrontImagePath: picked.path,
                      ),
                    ),
                  );
                }
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

          ..._buildItem(
            context,
            label: 'Driving License',
            onTap: () {
              final nav = Navigator.of(context);
              nav.pop();
              nav.push(
                MaterialPageRoute(
                  builder: (_) =>
                      CardScanPage(cardType: DomesticCardType.drivingLicense),
                ),
              );
            },
          ),
          ..._buildItem(
            context,
            label: 'Aadhar',
            onTap: () {
              final nav = Navigator.of(context);
              nav.pop();
              nav.push(
                MaterialPageRoute(
                  builder: (_) =>
                      CardScanPage(cardType: DomesticCardType.aadhar),
                ),
              );
            },
          ),
          ..._buildItem(
            context,
            label: 'Voters ID',
            onTap: () {
              final nav = Navigator.of(context);
              nav.pop();
              nav.push(
                MaterialPageRoute(
                  builder: (_) =>
                      CardScanPage(cardType: DomesticCardType.votersId),
                ),
              );
            },
          ),
          ..._buildItem(
            context,
            label: 'PAN Card',
            onTap: () {
              final nav = Navigator.of(context);
              nav.pop();
              nav.push(
                MaterialPageRoute(
                  builder: (_) =>
                      CardScanPage(cardType: DomesticCardType.panCard),
                ),
              );
            },
          ),
          // ── Passport ─────────────────────────────────────────────
          ..._buildItem(
            context,
            label: 'Passport',
            onTap: () {
              // Capture context before popping — nav.context is stale after pop
              final ctx = context;
              Navigator.of(context).pop();
              showPassportSourceDialog(ctx);
            },
          ),
          ..._buildItem(
            context,
            label: 'Other ID',
            onTap: () {
              final nav = Navigator.of(context);
              nav.pop();
              nav.push(
                MaterialPageRoute(
                  builder: (_) =>
                      CardScanPage(cardType: DomesticCardType.otherId),
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
                color: Color(0xFF2C3E50),
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
