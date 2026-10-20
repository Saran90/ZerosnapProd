import 'package:flutter/material.dart';
import 'passport_form_page.dart';

/// Passport form page for landing screen flow (with visa section).
/// This is a wrapper around PassportFormPage with showVisaSection always set to true.
///
/// Scenario: Landing Screen → Passport → OCR Flow
/// Used when: User selects Passport from landing screen and chooses Camera or Gallery
/// Visa Section: Visible (visa required for foreign visitors)
class PassportFormPageLanding extends StatelessWidget {
  const PassportFormPageLanding({super.key});

  @override
  Widget build(BuildContext context) {
    return const PassportFormPage(
      showVisaSection: true,
      pageTitle: 'Passport & VISA',
    );
  }
}
