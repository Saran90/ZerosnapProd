import 'package:flutter/material.dart';
import 'passport_form_page.dart';

/// Passport form page for domestic card flow (without visa section).
/// This is a wrapper around PassportFormPage with showVisaSection always set to false.
///
/// Scenario: Domestic Card → Passport → OCR Flow
/// Used when: User selects Passport from domestic card flow
/// Visa Section: Hidden (no visa needed for domestic residents)
class PassportFormPageDomestic extends StatelessWidget {
  const PassportFormPageDomestic({super.key});

  @override
  Widget build(BuildContext context) {
    return const PassportFormPage(
      showVisaSection: false,
      pageTitle: 'Passport',
    );
  }
}
