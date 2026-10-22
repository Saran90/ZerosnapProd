# Implementation Plan: Visa/Entry Document Selection Dialog

## Overview
Add a bottom-sheet dialog after passport back OCR completes in the full scan flow, allowing users to choose which type of visa/entry document should be captured next (e-Visa/Regular Visa, OCI Card, Diplomat Passport, or No Visa Required).

## Codebase Context
- **Language:** Flutter/Dart
- **File:** `lib/features/scan/presentation/pages/foreign_passport_scan_page.dart`
- **Patterns:** 
  - Enums defined near top of file (after imports, before main class)
  - Bottom sheet dialogs use `showDialog` with `AlertDialog` or `showModalBottomSheet`
  - State variables in `_ForeignPassportScanPageState` class
  - Private helper methods prefixed with `_`
  - Existing error dialog pattern: `_showVisaErrorDialog` and `_VisaErrorAction` enum
- **Build Command:** `flutter build apk` or `flutter build ios`
- **Test Command:** `flutter test` (manual testing via emulator/device)
- **Verification:** Run the app, test the foreign passport scan flow, capture passport front and back, verify dialog appears and each option works correctly

---

## Implementation Steps

- [ ] 1. **Add VisaDocumentType enum near the top of the file**
      
      Add the enum definition immediately after the `ScanRetakeResult` class definition (around line 35, after line 33).
      
      **Exact enum definition:**
      ```dart
      /// Type of visa or entry document to capture after passport scan.
      enum VisaDocumentType {
        eVisaOrRegularVisa, // e-Visa / Regular Visa — advance to visa scanning
        ociCard,            // OCI Card — not yet implemented, skip to form
        diplomatPassport,   // Diplomat Passport — advance to visa scanning (optional)
        noVisaRequired,     // No Visa Required — skip to form directly
      }
      ```
      
      **Files:** `lib/features/scan/presentation/pages/foreign_passport_scan_page.dart`
      
      **Verify:** Run `flutter analyze` to ensure no syntax errors. Expected: no errors for this file.

- [ ] 2. **Add state variable for selected visa document type**
      
      Add the state variable in the `_ForeignPassportScanPageState` class, in the "State" section (around line 110, after `_elapsedSeconds` declaration and before the "Captured images" comment section).
      
      **Exact state variable:**
      ```dart
      VisaDocumentType? _selectedVisaDocType;
      ```
      
      **Files:** `lib/features/scan/presentation/pages/foreign_passport_scan_page.dart`
      
      **Verify:** Run `flutter analyze` to ensure no syntax errors. Expected: no errors for this file.

- [ ] 3. **Create the _showVisaTypeSelectionDialog method**
      
      Add this method in the "Helpers" section of the state class, after `_extractOcrData` method (around line 585, before the `_skipCurrentStep` method).
      
      **Method signature and implementation outline:**
      ```dart
      /// Shows a bottom sheet dialog allowing the user to select which type of
      /// visa or entry document should be captured next.
      /// 
      /// Returns the selected [VisaDocumentType], or null if the user dismissed
      /// the dialog (tapped barrier or pressed back).
      Future<VisaDocumentType?> _showVisaTypeSelectionDialog() async {
        return await showModalBottomSheet<VisaDocumentType>(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          isDismissible: true, // Allow dismissing by tapping barrier
          enableDrag: true,    // Allow dismissing by dragging down
          builder: (ctx) => const _VisaTypeSelectionDialog(),
        );
      }
      ```
      
      **Files:** `lib/features/scan/presentation/pages/foreign_passport_scan_page.dart`
      
      **Verify:** Run `flutter analyze` to ensure no syntax errors. Expected: no errors for this file.

- [ ] 4. **Modify _runPassportBackOcr to show the dialog in full flow mode**
      
      Update the `_runPassportBackOcr` method (starts around line 477) to show the visa type selection dialog after OCR completes, but only in full flow mode (when `widget.retakeTarget == null`).
      
      **Current code (lines 492-506):**
      ```dart
      if (widget.retakeTarget != null) {
        // Retake mode — pop back with result (return the raw back data, not merged)
        Navigator.of(context).pop(
          ScanRetakeResult(
            target: ScanRetakeTarget.passportBack,
            imagePath: path,
            ocrData: data,
          ),
        );
      } else {
        // Full flow — advance to visa step
        setState(() => _currentStep = _ScanStep.visa);
      }
      ```
      
      **Replace with:**
      ```dart
      if (widget.retakeTarget != null) {
        // Retake mode — pop back with result (return the raw back data, not merged)
        Navigator.of(context).pop(
          ScanRetakeResult(
            target: ScanRetakeTarget.passportBack,
            imagePath: path,
            ocrData: data,
          ),
        );
      } else {
        // Full flow — show visa type selection dialog
        final selectedType = await _showVisaTypeSelectionDialog();
        if (!mounted) return;
        
        if (selectedType == null) {
          // User dismissed dialog — stay on passport back step
          setState(() => _currentStep = _ScanStep.passportBack);
          return;
        }
        
        // Store the selection
        _selectedVisaDocType = selectedType;
        
        // Handle each option
        switch (selectedType) {
          case VisaDocumentType.eVisaOrRegularVisa:
          case VisaDocumentType.diplomatPassport:
            // Advance to visa scanning step
            setState(() => _currentStep = _ScanStep.visa);
            break;
          
          case VisaDocumentType.ociCard:
            // OCI not yet implemented — show snackbar and navigate to form
            _showSnack('OCI Card scanning is not yet implemented.');
            _navigateToForm();
            break;
          
          case VisaDocumentType.noVisaRequired:
            // Skip visa capture and navigate directly to form
            _navigateToForm();
            break;
        }
      }
      ```
      
      **Files:** `lib/features/scan/presentation/pages/foreign_passport_scan_page.dart`
      
      **Verify:** Run `flutter analyze` to ensure no syntax errors, then test manually: capture passport front and back, verify dialog appears after back OCR completes, and test each option.

- [ ] 5. **Update _navigateToForm to pass selected visa type if needed**
      
      The `_navigateToForm` method (around line 595) currently navigates to `PassportCardScanPage` with `showVisaSection: true`. We need to pass information about the selected visa document type so the form can pre-select the appropriate visa type field.
      
      **Current code (lines 595-609):**
      ```dart
      void _navigateToForm() {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PassportCardScanPage(
              showVisaSection: true,
              pageTitle: 'Passport & VISA',
              initialFrontImagePath: _frontImagePath,
              initialBackImagePath: _backImagePath,
              initialVisaImagePath: _visaImagePath,
              initialPassportOcrData: _passportOcrData,
              initialVisaOcrData: _visaOcrData,
              skipExtraction: true,
            ),
          ),
        );
      }
      ```
      
      **Analysis:** After reviewing `PassportCardScanPage` (line 18-60 of passport_card_scan_page.dart), it does not currently have a parameter to accept the pre-selected visa type. Since the visa type in `PassportCardScanPage` uses a local String variable `_visaType` with values like 'e-Visa', 'OCI', 'Diplomat', 'No Visa' (line 56 in passport_card_scan_page.dart), we have two options:
      
      **Option A (Recommended):** Add a new optional parameter `initialVisaType` to `PassportCardScanPage` constructor and use it to pre-fill the visa type field. This would require modifying passport_card_scan_page.dart as well.
      
      **Option B (Simpler for this task):** Leave `_navigateToForm()` unchanged since the form's visa section will still allow manual selection. The user's choice in the dialog controls the navigation flow (whether to show visa scanning step or skip to form), but doesn't need to pre-fill the form's visa type dropdown.
      
      **Decision:** Use Option B for now to keep changes contained to a single file. The dialog controls the flow; the form's visa type field can be selected manually by the user if needed.
      
      **No changes needed to _navigateToForm method.**
      
      **Files:** None (no change)
      
      **Verify:** N/A

- [ ] 6. **Create the _VisaTypeSelectionDialog widget**
      
      Add this widget at the bottom of the file, after the `_PortraitPassportPreset` class (after line 1346).
      
      **Widget structure:**
      ```dart
      // ─────────────────────────────────────────────────────────────────────────────
      // Visa Type Selection Dialog
      // ─────────────────────────────────────────────────────────────────────────────
      
      /// Bottom sheet dialog shown after passport back OCR completes.
      /// Allows the user to choose which type of visa/entry document to capture next.
      class _VisaTypeSelectionDialog extends StatelessWidget {
        const _VisaTypeSelectionDialog();
      
        @override
        Widget build(BuildContext context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  
                  // Title
                  const Text(
                    'Select Visa/Entry Document Type',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Choose which document to scan next',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 20),
      
                  // Option 1: e-Visa / Regular Visa
                  _VisaTypeOption(
                    icon: Icons.assignment_outlined,
                    title: 'e-Visa / Regular Visa',
                    subtitle: 'Scan visa document',
                    onTap: () => Navigator.of(context).pop(
                      VisaDocumentType.eVisaOrRegularVisa,
                    ),
                  ),
      
                  const SizedBox(height: 12),
      
                  // Option 2: OCI Card
                  _VisaTypeOption(
                    icon: Icons.credit_card_outlined,
                    title: 'OCI Card',
                    subtitle: 'Overseas Citizen of India card',
                    onTap: () => Navigator.of(context).pop(
                      VisaDocumentType.ociCard,
                    ),
                  ),
      
                  const SizedBox(height: 12),
      
                  // Option 3: Diplomat Passport
                  _VisaTypeOption(
                    icon: Icons.military_tech_outlined,
                    title: 'Diplomat Passport',
                    subtitle: 'Diplomatic or official passport',
                    onTap: () => Navigator.of(context).pop(
                      VisaDocumentType.diplomatPassport,
                    ),
                  ),
      
                  const SizedBox(height: 12),
      
                  // Option 4: No Visa Required
                  _VisaTypeOption(
                    icon: Icons.block_outlined,
                    title: 'No Visa Required',
                    subtitle: 'Skip visa scanning',
                    onTap: () => Navigator.of(context).pop(
                      VisaDocumentType.noVisaRequired,
                    ),
                  ),
      
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        }
      }
      
      /// Individual option card in the visa type selection dialog.
      class _VisaTypeOption extends StatelessWidget {
        final IconData icon;
        final String title;
        final String subtitle;
        final VoidCallback onTap;
      
        const _VisaTypeOption({
          required this.icon,
          required this.title,
          required this.subtitle,
          required this.onTap,
        });
      
        @override
        Widget build(BuildContext context) {
          return InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE0E0E0)),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Title and subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Arrow icon
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Color(0xFF9CA3AF),
                  ),
                ],
              ),
            ),
          );
        }
      }
      ```
      
      **Icons chosen:**
      - **e-Visa / Regular Visa:** `Icons.assignment_outlined` — represents a document/form
      - **OCI Card:** `Icons.credit_card_outlined` — represents a card
      - **Diplomat Passport:** `Icons.military_tech_outlined` — represents diplomatic/official status
      - **No Visa Required:** `Icons.block_outlined` — represents "not needed"
      
      **Files:** `lib/features/scan/presentation/pages/foreign_passport_scan_page.dart`
      
      **Verify:** Run `flutter analyze` to ensure no syntax errors. Expected: no errors for this file.

- [ ] 7. **Manual end-to-end testing**
      
      Test the complete flow to ensure all scenarios work correctly:
      
      **Test Cases:**
      1. **e-Visa / Regular Visa option:**
         - Capture passport front → back
         - Dialog appears after back OCR
         - Select "e-Visa / Regular Visa"
         - Verify: advances to visa scanning step
         - Capture visa
         - Verify: navigates to form with all three images
      
      2. **OCI Card option:**
         - Capture passport front → back
         - Dialog appears after back OCR
         - Select "OCI Card"
         - Verify: snackbar shows "OCI Card scanning is not yet implemented."
         - Verify: navigates directly to form (no visa step)
      
      3. **Diplomat Passport option:**
         - Capture passport front → back
         - Dialog appears after back OCR
         - Select "Diplomat Passport"
         - Verify: advances to visa scanning step (same as e-Visa)
         - Capture visa (optional)
         - Verify: navigates to form
      
      4. **No Visa Required option:**
         - Capture passport front → back
         - Dialog appears after back OCR
         - Select "No Visa Required"
         - Verify: navigates directly to form (skips visa step)
      
      5. **Dialog dismissal:**
         - Capture passport front → back
         - Dialog appears after back OCR
         - Tap outside dialog (barrier) or press back button
         - Verify: dialog closes and stays on passport back step
         - User can tap shutter to capture back again or tap the "Skip this step" button
      
      6. **Retake mode (existing behavior unchanged):**
         - From PassportCardScanPage, tap to retake passport back
         - Verify: opens directly on passport back step
         - Capture back image
         - Verify: pops back to form immediately (no dialog shown)
      
      **Commands:**
      - Run on Android: `flutter run -d <device-id>`
      - Run on iOS: `flutter run -d <device-id>`
      - Build APK: `flutter build apk`
      
      **Verify:** All test cases pass as described above.

---

## Summary

This plan adds a visa/entry document selection dialog to the foreign passport scan flow. The dialog appears after passport back OCR completes in full flow mode, allowing users to choose between:
1. e-Visa / Regular Visa (advances to visa scanning)
2. OCI Card (shows "not implemented" snackbar, navigates to form)
3. Diplomat Passport (advances to visa scanning like e-Visa)
4. No Visa Required (skips visa capture, navigates to form)

Key implementation points:
- **Line 35:** Add `VisaDocumentType` enum
- **Line 110:** Add `_selectedVisaDocType` state variable
- **Line 585:** Add `_showVisaTypeSelectionDialog()` method
- **Lines 492-506:** Modify `_runPassportBackOcr()` to show dialog and handle user selection
- **After line 1346:** Add `_VisaTypeSelectionDialog` and `_VisaTypeOption` widgets

The dialog follows the existing codebase patterns (bottom sheet with option cards, same styling as profile photo options dialog in passport_card_scan_page.dart). If the user dismisses the dialog, the flow stays on the passport back step.
