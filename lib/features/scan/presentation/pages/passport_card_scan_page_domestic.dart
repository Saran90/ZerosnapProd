import 'package:flutter/material.dart';
import 'passport_card_scan_page.dart';

/// Passport card scan page for domestic card flow (without visa section).
/// This is a wrapper around PassportCardScanPage with showVisaSection always set to false.
///
/// Scenario: Domestic Card → Passport → OCR Flow
/// Used when: User completes a domestic card (Aadhar, Driving License, etc.)
/// Visa Section: Hidden (no visa needed for domestic residents)
class PassportCardScanPageDomestic extends StatelessWidget {
  final String? initialFrontImagePath;
  final bool autoOpenCamera;

  const PassportCardScanPageDomestic({
    super.key,
    this.initialFrontImagePath,
    this.autoOpenCamera = false,
  });

  @override
  Widget build(BuildContext context) {
    return PassportCardScanPage(
      initialFrontImagePath: initialFrontImagePath,
      autoOpenCamera: autoOpenCamera,
      showVisaSection: false,
      pageTitle: 'Passport Details (Domestic Card)',
    );
  }
}
