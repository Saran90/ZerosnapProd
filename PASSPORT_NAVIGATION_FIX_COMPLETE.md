# Passport Navigation Fix - Complete

## Problem Identified
The `choose_card_dialog.dart` was shared between two different flows:
1. **Landing Screen Flow** - User clicks "Passport" from landing screen
2. **Domestic Card Flow** - User completes a domestic card and clicks "Passport"

However, the `showPassportSourceDialog()` function always navigated to `PassportCardScanPageLanding` (with visa section), regardless of which flow it was called from. This caused the wrong page to be displayed for the domestic card flow.

## Root Cause
The `showPassportSourceDialog()` function had no way to differentiate between the two flows. It always used:
- `PassportCardScanPageLanding` for OCR flow
- `PassportFormPageLanding` for MRZ flow

## Solution Implemented
Modified `showPassportSourceDialog()` to accept an `isDomesticCardFlow` parameter:

```dart
void showPassportSourceDialog(
  BuildContext context, {
  bool isDomesticCardFlow = false,
}) {
  // ... implementation
}
```

### Changes Made

#### 1. Updated `showPassportSourceDialog()` Function
- Added `isDomesticCardFlow` parameter (default: `false`)
- Uses this parameter to determine which page to navigate to:
  - **Domestic Card Flow** (`isDomesticCardFlow: true`):
    - OCR: `PassportCardScanPageDomestic` (no visa)
    - MRZ: `PassportFormPageDomestic` (no visa)
  - **Landing Screen Flow** (`isDomesticCardFlow: false`):
    - OCR: `PassportCardScanPageLanding` (with visa)
    - MRZ: `PassportFormPageLanding` (with visa)

#### 2. Updated `_runMrzPassportScanner()` Function
- Changed signature from `_runMrzPassportScanner(NavigatorState nav, Widget targetPage)`
- To: `_runMrzPassportScanner(NavigatorState nav, bool isDomesticCardFlow)`
- Now navigates to the correct page based on the flow type

#### 3. Updated `_runMrzGalleryScan()` Function
- Changed signature to accept `bool isDomesticCardFlow` parameter
- Navigates to the correct page based on the flow type

#### 4. Updated Imports
- Added import for `passport_form_page_domestic.dart`
- Removed unused import for `passport_form_page.dart`

#### 5. Updated Call in `_ChooseCardDialog`
- When "Passport" is clicked from the choose card dialog, it now calls:
  ```dart
  showPassportSourceDialog(ctx, isDomesticCardFlow: false);
  ```
- This ensures the landing screen flow is used (since this dialog is only used from the landing screen)

## Navigation Flow After Fix

### Domestic Card Flow
```
CardScanPage (Driving License, Aadhar, etc.)
    ↓
Submit card
    ↓
PassportCardScanPageDomestic
    ↓
AppBar: "Passport Details (Domestic Card)" ✅
Visa Section: Hidden ✅
```

### Landing Screen Flow - From Choose Card Dialog
```
Landing Screen
    ↓
Click "Passport"
    ↓
showPassportSourceDialog(context, isDomesticCardFlow: false)
    ↓
Choose Camera/Gallery
    ↓
PassportCardScanPageLanding (OCR) OR PassportFormPageLanding (MRZ)
    ↓
AppBar: "Passport Details (Landing - OCR/MRZ)" ✅
Visa Section: Visible ✅
```

## Files Modified
1. **lib/features/dashboard/presentation/widgets/choose_card_dialog.dart**
   - Added `isDomesticCardFlow` parameter to `showPassportSourceDialog()`
   - Updated `_runMrzPassportScanner()` to use boolean parameter
   - Updated `_runMrzGalleryScan()` to use boolean parameter
   - Updated imports to include `passport_form_page_domestic.dart`
   - Updated call in `_ChooseCardDialog` to pass `isDomesticCardFlow: false`

## Verification
✅ All files compile without errors
✅ No unused imports
✅ All wrapper pages correctly configured
✅ Navigation logic properly differentiated between flows

## Key Points
- The fix is minimal and focused on the root cause
- No changes to the base pages (`PassportCardScanPage`, `PassportFormPage`)
- No changes to the wrapper pages
- The `choose_card_dialog` is only used from the landing screen, so it always passes `isDomesticCardFlow: false`
- The domestic card flow navigates directly to `PassportCardScanPageDomestic` from `card_scan_page.dart`

## Testing Recommendations
1. **Domestic Card Flow**: Complete a domestic card (Driving License, Aadhar, etc.) and verify:
   - AppBar shows "Passport Details (Domestic Card)"
   - Visa section is hidden
   - Submission works correctly

2. **Landing Screen Flow**: Click "Passport" from landing screen and verify:
   - AppBar shows "Passport Details (Landing - OCR)" or "Passport Details (Landing - MRZ)"
   - Visa section is visible
   - Both Camera and Gallery options work

3. **MRZ Flows**: If MRZ is enabled, test both:
   - Domestic card → Passport → MRZ (should use `PassportFormPageDomestic`)
   - Landing screen → Passport → MRZ (should use `PassportFormPageLanding`)
