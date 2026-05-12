# Domestic Card → Passport Navigation Location

## Navigation Code Location

**File:** `lib/features/scan/presentation/pages/card_scan_page.dart`
**Lines:** 520-526

```dart
// Navigate to passport page without visa section (domestic card flow)
if (!mounted) return;
Navigator.of(context).pushReplacement(
  MaterialPageRoute(
    builder: (_) => const PassportCardScanPageDomestic(),
  ),
);
```

---

## Import Statement

**File:** `lib/features/scan/presentation/pages/card_scan_page.dart`
**Line:** 16

```dart
import 'passport_card_scan_page_domestic.dart';
```

---

## Wrapper Page

**File:** `lib/features/scan/presentation/pages/passport_card_scan_page_domestic.dart`

```dart
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
```

---

## Flow Diagram

```
CardScanPage._submit()
    ↓
Line 520-526 in card_scan_page.dart
    ↓
Navigator.of(context).pushReplacement(
  MaterialPageRoute(
    builder: (_) => const PassportCardScanPageDomestic(),
  ),
);
    ↓
PassportCardScanPageDomestic (wrapper)
    ↓
PassportCardScanPage (base page)
    ├─ showVisaSection: false
    ├─ pageTitle: 'Passport Details (Domestic Card)'
    └─ AppBar shows: "Passport Details (Domestic Card)"
```

---

## Why It Might Show Wrong Title

If you're seeing "Passport Details (Landing - OCR)" instead of "Passport Details (Domestic Card)", it means:

1. **The wrapper is not being used** - But the code shows it should be
2. **The app is using cached code** - Old version still in memory
3. **The parameter is not being passed** - But the code shows it is

---

## Verification Steps

### Step 1: Verify the Navigation Code
Check that line 523 in `card_scan_page.dart` shows:
```dart
builder: (_) => const PassportCardScanPageDomestic(),
```

NOT:
```dart
builder: (_) => const PassportCardScanPage(showVisaSection: false),
```

### Step 2: Verify the Import
Check that line 16 in `card_scan_page.dart` shows:
```dart
import 'passport_card_scan_page_domestic.dart';
```

NOT:
```dart
import 'passport_card_scan_page.dart';
```

### Step 3: Verify the Wrapper File Exists
```bash
ls -la lib/features/scan/presentation/pages/passport_card_scan_page_domestic.dart
```

Should output the file path.

### Step 4: Verify the Wrapper Passes Correct Title
Check that `passport_card_scan_page_domestic.dart` line 22-27 shows:
```dart
return PassportCardScanPage(
  initialFrontImagePath: initialFrontImagePath,
  autoOpenCamera: autoOpenCamera,
  showVisaSection: false,
  pageTitle: 'Passport Details (Domestic Card)',
);
```

---

## If Still Showing Wrong Title

If after verifying all the above, it's still showing "Passport Details (Landing - OCR)", then:

### Option 1: Add Debug Print
Add this to `passport_card_scan_page_domestic.dart`:

```dart
@override
Widget build(BuildContext context) {
  print('🔍 DEBUG: PassportCardScanPageDomestic.build() called');
  print('   pageTitle will be: Passport Details (Domestic Card)');
  print('   showVisaSection will be: false');
  
  return PassportCardScanPage(
    initialFrontImagePath: initialFrontImagePath,
    autoOpenCamera: autoOpenCamera,
    showVisaSection: false,
    pageTitle: 'Passport Details (Domestic Card)',
  );
}
```

Then check the console when navigating to the passport page. If you see the debug print, the wrapper is being used correctly.

### Option 2: Check if PassportCardScanPage is Being Used Directly
Add this to `passport_card_scan_page.dart` in `_PassportCardScanPageState.initState()`:

```dart
@override
void initState() {
  super.initState();
  print('🔍 DEBUG: PassportCardScanPage.initState() called');
  print('   pageTitle: ${widget.pageTitle}');
  print('   showVisaSection: ${widget.showVisaSection}');
  // ... rest of initState
}
```

Check the console output to see what values are being received.

---

## Possible Issues

### Issue 1: Wrong Page Being Navigated To
**Symptom:** Title shows "Landing - OCR"
**Cause:** Navigation is using `PassportCardScanPageLanding` instead of `PassportCardScanPageDomestic`
**Check:** Line 523 in `card_scan_page.dart`

### Issue 2: Wrapper Not Passing Parameter
**Symptom:** Title shows default "Passport"
**Cause:** Wrapper not passing `pageTitle` parameter
**Check:** `passport_card_scan_page_domestic.dart` line 22-27

### Issue 3: App Cache Not Cleared
**Symptom:** Title doesn't change after code modification
**Cause:** Old compiled code still in memory
**Fix:** `flutter clean && flutter pub get && flutter run`

### Issue 4: Parameter Not Defined in Base Page
**Symptom:** AppBar shows default title
**Cause:** `pageTitle` parameter not in constructor
**Check:** `passport_card_scan_page.dart` constructor

---

## Summary

| Component | Location | Expected Value |
|-----------|----------|-----------------|
| Navigation | card_scan_page.dart:523 | `PassportCardScanPageDomestic()` |
| Import | card_scan_page.dart:16 | `passport_card_scan_page_domestic.dart` |
| Wrapper | passport_card_scan_page_domestic.dart | Passes `pageTitle: 'Passport Details (Domestic Card)'` |
| Base Page | passport_card_scan_page.dart | Uses `widget.pageTitle ?? 'Passport'` |
| AppBar | passport_card_scan_page.dart:729 | Shows custom title |

---

## Next Steps

1. **Verify all components** using the verification steps above
2. **Add debug prints** if needed to trace the issue
3. **Run full rebuild** if cache might be stale: `flutter clean && flutter pub get && flutter run`
4. **Check console output** for debug information

If you're still seeing the wrong title after verifying all of this, please share:
- The console output with debug prints
- A screenshot of the AppBar
- The exact line numbers from your files
