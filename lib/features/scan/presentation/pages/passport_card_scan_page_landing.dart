import 'package:flutter/material.dart';
import 'foreign_passport_scan_page.dart';

/// Entry point for the Foreign Passport scanning flow from the landing screen.
///
/// Replaces the old wrapper that forwarded directly to PassportCardScanPage.
/// Now opens [ForeignPassportScanPage] which handles all 3 capture steps
/// (passport front → OCR → passport back → OCR → visa → OCR) and then
/// navigates to PassportCardScanPage with all data pre-filled.
class PassportCardScanPageLanding extends StatelessWidget {
  // Legacy params kept for API compatibility with choose_card_dialog.dart
  // They are no longer used because the new scan page manages its own flow.
  final String? initialFrontImagePath;
  final bool autoOpenCamera;

  const PassportCardScanPageLanding({
    super.key,
    this.initialFrontImagePath,
    this.autoOpenCamera = false,
  });

  @override
  Widget build(BuildContext context) {
    return const ForeignPassportScanPage();
  }
}
