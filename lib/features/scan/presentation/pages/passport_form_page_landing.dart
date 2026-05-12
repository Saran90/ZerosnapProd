import 'package:flutter/material.dart';
import '../../domain/entities/mrz_result.dart';
import 'passport_form_page.dart';

/// Passport form page for landing screen flow (with visa section).
/// This is a wrapper around PassportFormPage with showVisaSection always set to true.
///
/// Scenario: Landing Screen → Passport → MRZ Flow
/// Used when: User selects Passport from landing screen and chooses MRZ (Camera or Gallery)
/// Visa Section: Visible (visa required for foreign visitors)
class PassportFormPageLanding extends StatelessWidget {
  final MrzResult? scannedResult;

  const PassportFormPageLanding({super.key, this.scannedResult});

  @override
  Widget build(BuildContext context) {
    return PassportFormPage(
      scannedResult: scannedResult,
      showVisaSection: true,
      pageTitle: 'Passport Details (Landing - MRZ)',
    );
  }
}
