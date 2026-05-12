# Navigation Fix - Before & After Comparison

## BEFORE (Bug)

### Domestic Card Flow
```
CardScanPage (Driving License, Aadhar, etc.)
    ↓
Submit card
    ↓
PassportCardScanPageDomestic
    ↓
showPassportSourceDialog(context)  ← No parameter to differentiate flows
    ↓
❌ ALWAYS navigates to PassportCardScanPageLanding
    ↓
AppBar: "Passport Details (Landing - OCR)" ❌ WRONG!
Visa Section: Visible ❌ WRONG!
```

### Landing Screen Flow
```
Landing Screen
    ↓
Click "Passport"
    ↓
showPassportSourceDialog(context)  ← No parameter to differentiate flows
    ↓
✅ Navigates to PassportCardScanPageLanding
    ↓
AppBar: "Passport Details (Landing - OCR)" ✅ CORRECT
Visa Section: Visible ✅ CORRECT
```

**Issue**: Both flows use the same function with no way to differentiate, causing the domestic card flow to show the wrong page.

---

## AFTER (Fixed)

### Domestic Card Flow
```
CardScanPage (Driving License, Aadhar, etc.)
    ↓
Submit card
    ↓
PassportCardScanPageDomestic
    ↓
showPassportSourceDialog(context, isDomesticCardFlow: true)  ← Parameter added
    ↓
✅ Navigates to PassportCardScanPageDomestic (OCR) or PassportFormPageDomestic (MRZ)
    ↓
AppBar: "Passport Details (Domestic Card)" ✅ CORRECT!
Visa Section: Hidden ✅ CORRECT!
```

### Landing Screen Flow
```
Landing Screen
    ↓
Click "Passport"
    ↓
showPassportSourceDialog(context, isDomesticCardFlow: false)  ← Parameter added
    ↓
✅ Navigates to PassportCardScanPageLanding (OCR) or PassportFormPageLanding (MRZ)
    ↓
AppBar: "Passport Details (Landing - OCR/MRZ)" ✅ CORRECT
Visa Section: Visible ✅ CORRECT
```

**Solution**: Added `isDomesticCardFlow` parameter to differentiate between flows and navigate to the correct page.

---

## Code Changes Summary

### Function Signature Change

**BEFORE:**
```dart
void showPassportSourceDialog(BuildContext context) {
  // Always uses PassportCardScanPageLanding
}
```

**AFTER:**
```dart
void showPassportSourceDialog(
  BuildContext context, {
  bool isDomesticCardFlow = false,
}) {
  // Uses appropriate page based on isDomesticCardFlow
}
```

### MRZ Scanner Function Change

**BEFORE:**
```dart
Future<void> _runMrzPassportScanner(NavigatorState nav) async {
  // Always navigates to PassportFormPageLanding
  nav.push(
    MaterialPageRoute(
      builder: (_) => PassportFormPageLanding(scannedResult: result),
    ),
  );
}
```

**AFTER:**
```dart
Future<void> _runMrzPassportScanner(
  NavigatorState nav,
  bool isDomesticCardFlow,
) async {
  // Navigates to appropriate page based on flow
  if (isDomesticCardFlow) {
    nav.push(
      MaterialPageRoute(
        builder: (_) => PassportFormPageDomestic(scannedResult: result),
      ),
    );
  } else {
    nav.push(
      MaterialPageRoute(
        builder: (_) => PassportFormPageLanding(scannedResult: result),
      ),
    );
  }
}
```

### Gallery Scan Function Change

**BEFORE:**
```dart
Future<void> _runMrzGalleryScan(NavigatorState nav) async {
  // Always navigates to PassportFormPageLanding
}
```

**AFTER:**
```dart
Future<void> _runMrzGalleryScan(
  NavigatorState nav,
  bool isDomesticCardFlow,
) async {
  // Navigates to appropriate page based on flow
  if (isDomesticCardFlow) {
    // Use PassportFormPageDomestic
  } else {
    // Use PassportFormPageLanding
  }
}
```

### Call Site Change

**BEFORE:**
```dart
showPassportSourceDialog(ctx);  // No way to differentiate
```

**AFTER:**
```dart
showPassportSourceDialog(ctx, isDomesticCardFlow: false);  // Explicitly specify flow
```

---

## Impact

| Aspect | Before | After |
|--------|--------|-------|
| Domestic Card → Passport | ❌ Wrong page shown | ✅ Correct page shown |
| Landing Screen → Passport | ✅ Correct page shown | ✅ Correct page shown |
| Visa Section in Domestic Flow | ❌ Visible (wrong) | ✅ Hidden (correct) |
| Visa Section in Landing Flow | ✅ Visible (correct) | ✅ Visible (correct) |
| Page Title in Domestic Flow | ❌ "Landing - OCR" | ✅ "Domestic Card" |
| Page Title in Landing Flow | ✅ "Landing - OCR/MRZ" | ✅ "Landing - OCR/MRZ" |

---

## Files Changed
- `lib/features/dashboard/presentation/widgets/choose_card_dialog.dart`

## Lines Changed
- Added `isDomesticCardFlow` parameter to `showPassportSourceDialog()` function
- Updated `_runMrzPassportScanner()` to accept and use `isDomesticCardFlow` parameter
- Updated `_runMrzGalleryScan()` to accept and use `isDomesticCardFlow` parameter
- Updated all navigation logic to use the appropriate page based on flow type
- Added import for `passport_form_page_domestic.dart`
- Updated call in `_ChooseCardDialog` to pass `isDomesticCardFlow: false`

## Backward Compatibility
✅ Fully backward compatible - the `isDomesticCardFlow` parameter has a default value of `false`, so existing calls without the parameter will continue to work as before (landing screen flow).
