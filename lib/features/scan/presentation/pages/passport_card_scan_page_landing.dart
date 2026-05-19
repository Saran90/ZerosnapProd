import 'package:flutter/material.dart';
import 'passport_card_scan_page.dart';

/// Passport card scan page for landing screen flow (with visa section).
/// This is a wrapper around PassportCardScanPage with showVisaSection always set to true.
///
/// Scenario: Landing Screen → Passport → OCR Flow
/// Used when: User selects Passport from landing screen and chooses OCR (Camera or Gallery)
/// Visa Section: Visible (visa required for foreign visitors)
class PassportCardScanPageLanding extends StatelessWidget {
  final String? initialFrontImagePath;
  final bool autoOpenCamera;

  const PassportCardScanPageLanding({
    super.key,
    this.initialFrontImagePath,
    this.autoOpenCamera = false,
  });

  @override
  Widget build(BuildContext context) {
    return PassportCardScanPage(
      initialFrontImagePath: initialFrontImagePath,
      autoOpenCamera: autoOpenCamera,
      showVisaSection: true,
      pageTitle: 'Passport & VISA',
    );
  }
}
