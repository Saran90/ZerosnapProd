# Passport Title Bug - Diagnosis and Fix

## Issue
When navigating from Domestic Card → Passport flow, the AppBar shows:
- **Current (Wrong):** "Passport Details (Landing - OCR)"
- **Expected (Correct):** "Passport Details (Domestic Card)"

## Root Cause Analysis

The issue is likely one of the following:

### Possibility 1: App Cache Not Cleared
The app might be using a cached version of the code. The fix requires a **full rebuild**, not just hot reload.

### Possibility 2: Wrapper Not Being Used
Although the import looks correct, the wrapper might not be properly instantiated.

### Possibility 3: Parameter Not Being Passed
The `pageTitle` parameter might not be reaching the base page.

## Solution

### Step 1: Full Rebuild (Required)
```bash
flutter clean
flutter pub get
flutter run
```

**Important:** Hot reload will NOT work for this change. You MUST do a full rebuild.

### Step 2: Verify the Fix
After rebuilding, check:
1. Navigate to Domestic Card (e.g., Aadhar)
2. Complete the card form
3. Submit the card
4. Verify the AppBar shows: **"Passport Details (Domestic Card)"**

### Step 3: If Still Wrong
If the title is still showing "Passport Details (Landing - OCR)", then the wrapper is not being used. In that case, follow the debugging steps below.

---

## Debugging Steps

### Debug 1: Verify Wrapper is Being Used
Add a print statement to the wrapper:

**passport_card_scan_page_domestic.dart:**
```dart
@override
Widget build(BuildContext context) {
  print('DEBUG: PassportCardScanPageDomestic wrapper is being used');
  return PassportCardScanPage(
    initialFrontImagePath: initialFrontImagePath,
    autoOpenCamera: autoOpenCamera,
    showVisaSection: false,
    pageTitle: 'Passport Details (Domestic Card)',
  );
}
```

Then check the console output when navigating to the passport page.

### Debug 2: Verify Parameter is Being Passed
Add a print statement to the base page:

**passport_card_scan_page.dart (in _PassportCardScanPageState):**
```dart
@override
void initState() {
  super.initState();
  print('DEBUG: pageTitle = ${widget.pageTitle}');
  print('DEBUG: showVisaSection = ${widget.showVisaSection}');
  // ... rest of initState
}
```

Check the console to see what values are being received.

### Debug 3: Verify AppBar is Using the Parameter
Check the AppBar code in passport_card_scan_page.dart:

```dart
appBar: AppBar(
  backgroundColor: AppColors.primary,
  foregroundColor: Colors.white,
  title: Text(widget.pageTitle ?? 'Passport'),  // ← Should use pageTitle
  elevation: 0,
),
```

---

## Possible Causes

### Cause 1: Hot Reload Issue
**Symptom:** Title doesn't change after code modification
**Solution:** Do `flutter clean && flutter pub get && flutter run`

### Cause 2: Wrong Page Being Navigated To
**Symptom:** Title shows "Landing - OCR" instead of "Domestic Card"
**Solution:** Check that card_scan_page.dart is importing and using PassportCardScanPageDomestic

### Cause 3: Parameter Not Defined
**Symptom:** AppBar shows default title "Passport"
**Solution:** Verify pageTitle parameter is defined in PassportCardScanPage constructor

### Cause 4: Wrapper Not Passing Parameter
**Symptom:** Title shows wrong value
**Solution:** Verify wrapper is passing pageTitle: 'Passport Details (Domestic Card)'

---

## Verification Checklist

- [ ] Did you run `flutter clean`?
- [ ] Did you run `flutter pub get`?
- [ ] Did you run `flutter run` (not hot reload)?
- [ ] Does the AppBar show "Passport Details (Domestic Card)"?
- [ ] Is the visa section hidden?
- [ ] Can you fill and submit the form?

---

## If Still Not Working

If after a full rebuild the title is still wrong, please:

1. **Check the console output** for the debug print statements
2. **Verify the imports** in card_scan_page.dart
3. **Check if PassportCardScanPageDomestic is being used** or if PassportCardScanPage is being used directly
4. **Verify the wrapper file exists** at `lib/features/scan/presentation/pages/passport_card_scan_page_domestic.dart`

---

## Expected Behavior After Fix

### Domestic Card Flow
```
CardScanPage (Aadhar, DL, etc.)
    ↓
Submit card
    ↓
PassportCardScanPageDomestic
    ↓
AppBar: "Passport Details (Domestic Card)" ✅
    ↓
Visa section: Hidden ✅
```

### Landing Screen Flow
```
choose_card_dialog (Passport)
    ↓
PassportCardScanPageLanding
    ↓
AppBar: "Passport Details (Landing - OCR)" ✅
    ↓
Visa section: Visible ✅
```

---

## Summary

The issue is most likely due to **app cache not being cleared**. The fix is:

```bash
flutter clean
flutter pub get
flutter run
```

After this, the title should show correctly as "Passport Details (Domestic Card)" for the domestic card flow.
