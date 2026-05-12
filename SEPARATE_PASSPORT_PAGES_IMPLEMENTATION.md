# Separate Passport Pages Implementation

## Overview
Created dedicated passport pages for domestic card flow and landing screen flow instead of using the `showVisaSection` boolean flag. This provides better type safety, clearer intent, and easier maintenance.

## New Files Created

### 1. **PassportCardScanPageDomestic** 
- **File:** `lib/features/scan/presentation/pages/passport_card_scan_page_domestic.dart`
- **Purpose:** Wrapper around PassportCardScanPage for domestic card flow
- **Visa Section:** Always hidden (showVisaSection: false)
- **Use Case:** When user completes domestic card (Driving License, Aadhar, etc.) and needs to fill passport details
- **Navigation Source:** CardScanPage

### 2. **PassportCardScanPageLanding**
- **File:** `lib/features/scan/presentation/pages/passport_card_scan_page_landing.dart`
- **Purpose:** Wrapper around PassportCardScanPage for landing screen flow
- **Visa Section:** Always visible (showVisaSection: true)
- **Use Case:** When user selects Passport from landing screen (Choose Card dialog)
- **Navigation Sources:** choose_card_dialog.dart (Camera OCR, Gallery OCR)

### 3. **PassportFormPageDomestic**
- **File:** `lib/features/scan/presentation/pages/passport_form_page_domestic.dart`
- **Purpose:** Wrapper around PassportFormPage for domestic card flow
- **Visa Section:** Always hidden (showVisaSection: false)
- **Use Case:** For future domestic card MRZ flows (if needed)

### 4. **PassportFormPageLanding**
- **File:** `lib/features/scan/presentation/pages/passport_form_page_landing.dart`
- **Purpose:** Wrapper around PassportFormPage for landing screen flow
- **Visa Section:** Always visible (showVisaSection: true)
- **Use Case:** When user scans passport via MRZ from landing screen
- **Navigation Sources:** choose_card_dialog.dart (Camera MRZ, Gallery MRZ), MrzScannerPage

## Navigation Updates

### CardScanPage (Domestic Card Flow)
**Before:**
```dart
Navigator.of(context).pushReplacement(
  MaterialPageRoute(
    builder: (_) => PassportCardScanPage(showVisaSection: false),
  ),
);
```

**After:**
```dart
Navigator.of(context).pushReplacement(
  MaterialPageRoute(
    builder: (_) => const PassportCardScanPageDomestic(),
  ),
);
```

### choose_card_dialog.dart (Landing Screen - Camera OCR)
**Before:**
```dart
nav.push(
  MaterialPageRoute(
    builder: (_) => const PassportCardScanPage(
      autoOpenCamera: true,
      showVisaSection: true,
    ),
  ),
);
```

**After:**
```dart
nav.push(
  MaterialPageRoute(
    builder: (_) => const PassportCardScanPageLanding(
      autoOpenCamera: true,
    ),
  ),
);
```

### choose_card_dialog.dart (Landing Screen - Gallery OCR)
**Before:**
```dart
nav.push(
  MaterialPageRoute(
    builder: (_) => PassportCardScanPage(
      initialFrontImagePath: picked.path,
      showVisaSection: true,
    ),
  ),
);
```

**After:**
```dart
nav.push(
  MaterialPageRoute(
    builder: (_) => PassportCardScanPageLanding(
      initialFrontImagePath: picked.path,
    ),
  ),
);
```

### choose_card_dialog.dart (Landing Screen - Camera MRZ)
**Before:**
```dart
nav.push(
  MaterialPageRoute(
    builder: (_) =>
        PassportFormPage(scannedResult: result, showVisaSection: true),
  ),
);
```

**After:**
```dart
nav.push(
  MaterialPageRoute(
    builder: (_) =>
        PassportFormPageLanding(scannedResult: result),
  ),
);
```

### choose_card_dialog.dart (Landing Screen - Gallery MRZ)
**Before:**
```dart
nav.push(
  MaterialPageRoute(
    builder: (_) => const PassportFormPage(showVisaSection: true),
  ),
);
```

**After:**
```dart
nav.push(
  MaterialPageRoute(
    builder: (_) => const PassportFormPageLanding(),
  ),
);
```

### MrzScannerPage (Passport MRZ Scan)
**Before:**
```dart
Navigator.of(context).pushReplacement(
  MaterialPageRoute(
    builder: (_) =>
        PassportFormPage(scannedResult: result, showVisaSection: true),
  ),
);
```

**After:**
```dart
Navigator.of(context).pushReplacement(
  MaterialPageRoute(
    builder: (_) =>
        PassportFormPageLanding(scannedResult: result),
  ),
);
```

## Benefits

1. **Type Safety:** No more boolean flag confusion - class names clearly indicate the flow
2. **Clear Intent:** Reading `PassportCardScanPageDomestic` immediately tells you it's for domestic card flow
3. **Maintainability:** If domestic and landing flows need different logic in the future, it's easy to diverge
4. **Reduced Cognitive Load:** Developers don't need to remember which boolean value means what
5. **Easier Testing:** Can test domestic and landing flows independently
6. **Better Documentation:** Class names serve as self-documenting code

## Current Navigation Flow

### Domestic Card Flow
```
CardScanPage (Driving License, Aadhar, etc.)
    ↓
PassportCardScanPageDomestic (no visa section)
    ↓
Submit → API
```

### Landing Screen - OCR Flow
```
choose_card_dialog → Passport
    ↓
PassportCardScanPageLanding (with visa section)
    ↓
Extract Details
    ↓
Fill Form
    ↓
Add Visa
    ↓
Sign
    ↓
Submit → API
```

### Landing Screen - MRZ Flow
```
choose_card_dialog → Passport
    ↓
MrzScannerPage
    ↓
PassportFormPageLanding (with visa section)
    ↓
Fill Form
    ↓
Add Visa
    ↓
Sign
    ↓
Submit → API
```

## Files Modified

1. **lib/features/scan/presentation/pages/card_scan_page.dart**
   - Updated import to use PassportCardScanPageDomestic
   - Updated navigation to use PassportCardScanPageDomestic

2. **lib/features/scan/presentation/pages/mrz_scanner_page.dart**
   - Updated import to use PassportFormPageLanding
   - Updated navigation to use PassportFormPageLanding

3. **lib/features/dashboard/presentation/widgets/choose_card_dialog.dart**
   - Updated imports to use PassportCardScanPageLanding and PassportFormPageLanding
   - Updated all navigation calls to use the new dedicated pages

## Testing Recommendations

1. **Domestic Card Flow:** Complete a domestic card (Driving License, Aadhar) and verify:
   - Visa section is NOT visible in the passport form
   - Submission works correctly without visa fields

2. **Landing Screen - OCR Flow:** Select Passport from landing screen and verify:
   - Visa section IS visible in the passport form
   - Can add visa details
   - Submission includes visa fields

3. **Landing Screen - MRZ Flow:** Select Passport and use MRZ scanner, verify:
   - Visa section IS visible in the passport form
   - Can add visa details
   - Submission includes visa fields

## Notes

- The original `PassportFormPage` and `PassportCardScanPage` still support the `showVisaSection` parameter for backward compatibility
- The wrapper pages are simple and lightweight - they just pass the correct boolean value
- No changes to the underlying business logic - only navigation and page selection
- All existing functionality is preserved
