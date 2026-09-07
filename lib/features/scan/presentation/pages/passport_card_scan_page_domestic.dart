import 'package:flutter/material.dart';
import 'domestic_passport_scan_page.dart';

/// Entry point for the Domestic Card → Passport scanning flow.
///
/// Opens [DomesticPassportScanPage] which handles 2-step capture
/// (passport front → OCR → passport back → OCR) then navigates to
/// PassportCardScanPage with the visa section hidden.
class PassportCardScanPageDomestic extends StatelessWidget {
  // Legacy params kept for API compatibility with choose_card_dialog.dart
  final String? initialFrontImagePath;
  final bool autoOpenCamera;

  const PassportCardScanPageDomestic({
    super.key,
    this.initialFrontImagePath,
    this.autoOpenCamera = false,
  });

  @override
  Widget build(BuildContext context) {
    return const DomesticPassportScanPage();
  }
}
