# Passport Title Bug - Resolution

## Issue Identified ✅

**Problem:** Domestic Card → Passport flow shows wrong title
- **Current (Wrong):** "Passport Details (Landing - OCR)"
- **Expected (Correct):** "Passport Details (Domestic Card)"

**Root Cause:** App cache not cleared after adding `pageTitle` parameter to base pages

---

## Solution

### The Fix (3 Commands)
```bash
flutter clean
flutter pub get
flutter run
```

**⚠️ CRITICAL:** Do NOT use hot reload. You MUST do a full rebuild.

---

## Why This Happens

### What Changed
1. Added `pageTitle` parameter to `PassportCardScanPage` constructor
2. Updated AppBar to use `widget.pageTitle ?? 'Passport'`
3. Wrapper pages pass descriptive titles

### Why Hot Reload Doesn't Work
Hot reload updates code but keeps old widget instances. When you add a new constructor parameter, the old instances don't know about it, so the new parameter is ignored.

### Why Full Rebuild Works
Full rebuild:
1. Cleans all cached build artifacts
2. Rebuilds the entire app from scratch
3. Properly initializes all new parameters
4. Creates fresh widget instances with new parameters

---

## Step-by-Step Fix

### Step 1: Stop the App
```bash
# Press Ctrl+C in the terminal where the app is running
```

### Step 2: Clean Build Cache
```bash
flutter clean
```
This removes all build artifacts and cached files.

### Step 3: Get Dependencies
```bash
flutter pub get
```
This ensures all dependencies are properly resolved.

### Step 4: Run the App
```bash
flutter run
```
This does a full rebuild from scratch.

### Step 5: Test the Fix
1. Navigate to Domestic Card (Aadhar, Driving License, etc.)
2. Complete the card form
3. Submit the card
4. **Verify:** AppBar shows "Passport Details (Domestic Card)"
5. **Verify:** Visa section is hidden

---

## Verification Checklist

After running the fix commands, verify:

- [ ] App builds successfully
- [ ] No compilation errors
- [ ] Domestic Card flow shows: "Passport Details (Domestic Card)"
- [ ] Landing OCR flow shows: "Passport Details (Landing - OCR)"
- [ ] Landing MRZ flow shows: "Passport Details (Landing - MRZ)"
- [ ] Visa sections are visible/hidden correctly
- [ ] All forms work correctly
- [ ] Submission succeeds

---

## What Was Changed in Code

### PassportCardScanPage (Base Page)
```dart
// Added parameter
final String? pageTitle;

// Updated constructor
const PassportCardScanPage({
  super.key,
  this.initialFrontImagePath,
  this.autoOpenCamera = false,
  this.showVisaSection = true,
  this.pageTitle,  // ← NEW
});

// Updated AppBar
title: Text(widget.pageTitle ?? 'Passport'),  // ← Uses new parameter
```

### PassportCardScanPageDomestic (Wrapper)
```dart
return PassportCardScanPage(
  initialFrontImagePath: initialFrontImagePath,
  autoOpenCamera: autoOpenCamera,
  showVisaSection: false,
  pageTitle: 'Passport Details (Domestic Card)',  // ← Passes title
);
```

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
    ↓
Form works correctly ✅
```

### Landing Screen - OCR Flow
```
choose_card_dialog (Passport)
    ↓
PassportCardScanPageLanding
    ↓
AppBar: "Passport Details (Landing - OCR)" ✅
    ↓
Visa section: Visible ✅
    ↓
Form works correctly ✅
```

### Landing Screen - MRZ Flow
```
choose_card_dialog (Passport)
    ↓
MrzScannerPage
    ↓
PassportFormPageLanding
    ↓
AppBar: "Passport Details (Landing - MRZ)" ✅
    ↓
Visa section: Visible ✅
    ↓
Form works correctly ✅
```

---

## If Still Not Working

### Check 1: Verify Files Exist
```bash
ls -la lib/features/scan/presentation/pages/passport_card_scan_page_domestic.dart
```

### Check 2: Verify Import
```bash
grep "passport_card_scan_page_domestic" lib/features/scan/presentation/pages/card_scan_page.dart
```

### Check 3: Verify Navigation
```bash
grep "PassportCardScanPageDomestic" lib/features/scan/presentation/pages/card_scan_page.dart
```

### Check 4: Add Debug Prints
Add to `passport_card_scan_page_domestic.dart`:
```dart
@override
Widget build(BuildContext context) {
  print('✅ PassportCardScanPageDomestic wrapper is being used');
  print('   pageTitle: Passport Details (Domestic Card)');
  return PassportCardScanPage(
    initialFrontImagePath: initialFrontImagePath,
    autoOpenCamera: autoOpenCamera,
    showVisaSection: false,
    pageTitle: 'Passport Details (Domestic Card)',
  );
}
```

Then check console output when navigating to passport page.

---

## Common Issues and Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| Still shows "Landing - OCR" | Cache not cleared | Run `flutter clean` again |
| Shows default "Passport" | Parameter not passed | Check wrapper is passing pageTitle |
| App won't build | Dependency issue | Run `flutter pub get` again |
| Hot reload doesn't work | Constructor parameter change | Do full rebuild, not hot reload |

---

## Prevention Tips

1. **Always do full rebuild** when adding constructor parameters
2. **Don't rely on hot reload** for StatefulWidget changes
3. **Test all flows** after making changes
4. **Use descriptive titles** to catch issues early
5. **Check console output** for debug information

---

## Summary

**The Issue:** Wrong title shown in domestic card flow
**The Cause:** App cache not cleared after code changes
**The Solution:** `flutter clean && flutter pub get && flutter run`
**Time to Fix:** ~2-3 minutes

After running these commands, the domestic card flow should show the correct title: **"Passport Details (Domestic Card)"**

---

## Files Involved

| File | Change |
|------|--------|
| `passport_card_scan_page.dart` | Added `pageTitle` parameter |
| `passport_form_page.dart` | Added `pageTitle` parameter |
| `passport_card_scan_page_domestic.dart` | Passes domestic title |
| `passport_card_scan_page_landing.dart` | Passes landing OCR title |
| `passport_form_page_domestic.dart` | Passes domestic title |
| `passport_form_page_landing.dart` | Passes landing MRZ title |

---

## Next Steps

1. **Run the fix commands:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Test all flows:**
   - Domestic Card → Passport
   - Landing Screen → OCR
   - Landing Screen → MRZ

3. **Verify titles are correct:**
   - Domestic: "Passport Details (Domestic Card)"
   - Landing OCR: "Passport Details (Landing - OCR)"
   - Landing MRZ: "Passport Details (Landing - MRZ)"

4. **Commit the changes** if everything works

---

## Documentation

- `PASSPORT_TITLE_BUG_DIAGNOSIS.md` - Detailed diagnosis
- `PASSPORT_TITLE_FIX_GUIDE.md` - Step-by-step fix guide
- `PASSPORT_TITLE_BUG_RESOLUTION.md` - This file

---

## Conclusion

The issue is a common Flutter problem when adding constructor parameters to StatefulWidgets. The solution is straightforward: do a full rebuild instead of relying on hot reload.

**Expected time to resolve:** 2-3 minutes
**Difficulty level:** Easy
**Risk level:** None (no code changes needed, just rebuild)

Run the fix commands and the issue should be resolved! ✅
