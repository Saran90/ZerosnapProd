import 'package:flutter/material.dart';
import '../../domain/entities/mrz_result.dart';
import 'passport_form_page.dart';

/// Passport form page for domestic card flow (without visa section).
/// This is a wrapper around PassportFormPage with showVisaSection always set to false.
///
/// Scenario: Domestic Card → Passport → MRZ Flow (NOT CURRENTLY SUPPORTED)
/// Used when: (Reserved for future use if MRZ support is added to domestic card flow)
/// Visa Section: Hidden (no visa needed for domestic residents)
class PassportFormPageDomestic extends StatelessWidget {
  final MrzResult? scannedResult;

  const PassportFormPageDomestic({super.key, this.scannedResult});

  @override
  Widget build(BuildContext context) {
    return PassportFormPage(
      scannedResult: scannedResult,
      showVisaSection: false,
      pageTitle: 'Passport Details (Domestic Card)',
    );
  }
}
