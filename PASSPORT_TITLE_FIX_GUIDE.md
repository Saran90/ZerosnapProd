# Passport Title Bug - Fix Guide

## Issue Summary
**Problem:** Domestic Card → Passport flow shows "Passport Details (Landing - OCR)" instead of "Passport Details (Domestic Card)"

**Root Cause:** App cache not cleared after code changes

**Solution:** Full rebuild required

---

## Quick Fix

### Step 1: Clean and Rebuild
```bash
# Stop the running app first (Ctrl+C)

# Then run:
flutter clean
flutter pub get
flutter run
```

**⚠️ IMPORTANT:** Do NOT use hot reload. You MUST do a full rebuild.

### Step 2: Test the Fix
1. Open the app
2. Go to Dashboard
3. Select "Choose Card"
4. Select any domestic card (Aadhar, Driving License, etc.)
5. Complete the card form and submit
6. **Verify:** AppBar should show **"Passport Details (Domestic Card)"**
7. **Verify:** Visa section should be **HIDDEN**

---

## Why This Happens

### Constructor Parameter Changes
When you add a new parameter to a StatefulWidget constructor (like `pageTitle`), Flutter needs to rebuild the entire widget tree. Hot reload doesn't handle this properly.

### What Happens with Hot Reload
```
❌ Hot Reload (WRONG)
├─ Updates code
├─ Keeps old widget instances
└─ New parameter not recognized

✅ Full Rebuild (CORRECT)
├─ Cleans build artifacts
├─ Rebuilds entire app
└─ New parameter properly initialized
```

---

## Detailed Fix Steps

### Step 1: Stop the App
Press `Ctrl+C` in the terminal where the app is running.

### Step 2: Clean Build Artifacts
```bash
flutter clean
```

This removes all cached build files.

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

### Step 5: Verify the Fix
Navigate through the domestic card flow and check:
- [ ] AppBar shows "Passport Details (Domestic Card)"
- [ ] Visa section is hidden
- [ ] Form works correctly
- [ ] Submission succeeds

---

## What Was Changed

### Base Page: PassportCardScanPage
**Added parameter:**
```dart
final String? pageTitle;
```

**Updated constructor:**
```dart
const PassportCardScanPage({
  super.key,
  this.initialFrontImagePath,
  this.autoOpenCamera = false,
  this.showVisaSection = true,
  this.pageTitle,  // ← NEW
});
```

**Updated AppBar:**
```dart
title: Text(widget.pageTitle ?? 'Passport'),  // ← Uses new parameter
```

### Wrapper Page: PassportCardScanPageDomestic
**Passes the title:**
```dart
return PassportCardScanPage(
  initialFrontImagePath: initialFrontImagePath,
  autoOpenCamera: autoOpenCamera,
  showVisaSection: false,
  pageTitle: 'Passport Details (Domestic Card)',  // ← Passes title
);
```

---

## Verification

### Before Fix
```
Domestic Card → Passport
    ↓
AppBar: "Passport Details (Landing - OCR)"  ❌ WRONG
Visa Section: Visible  ❌ WRONG
```

### After Fix
```
Domestic Card → Passport
    ↓
AppBar: "Passport Details (Domestic Card)"  ✅ CORRECT
Visa Section: Hidden  ✅ CORRECT
```

---

## If Still Not Working

If after a full rebuild the title is still wrong, follow these debugging steps:

### Debug Step 1: Check File Exists
Verify the wrapper file exists:
```bash
ls -la lib/features/scan/presentation/pages/passport_card_scan_page_domestic.dart
```

Should output the file path.

### Debug Step 2: Check Import
Verify card_scan_page.dart imports the wrapper:
```bash
grep "passport_card_scan_page_domestic" lib/features/scan/presentation/pages/card_scan_page.dart
```

Should show:
```
import 'passport_card_scan_page_domestic.dart';
```

### Debug Step 3: Check Navigation
Verify card_scan_page.dart uses the wrapper:
```bash
grep "PassportCardScanPageDomestic" lib/features/scan/presentation/pages/card_scan_page.dart
```

Should show:
```
builder: (_) => const PassportCardScanPageDomestic(),
```

### Debug Step 4: Add Debug Prints
Add this to passport_card_scan_page_domestic.dart:
```dart
@override
Widget build(BuildContext context) {
  print('✅ PassportCardScanPageDomestic wrapper is being used');
  print('   pageTitle will be: Passport Details (Domestic Card)');
  return PassportCardScanPage(
    initialFrontImagePath: initialFrontImagePath,
    autoOpenCamera: autoOpenCamera,
    showVisaSection: false,
    pageTitle: 'Passport Details (Domestic Card)',
  );
}
```

Then check the console output when navigating to the passport page.

---

## Expected Console Output

After the fix, you should see in the console:
```
✅ PassportCardScanPageDomestic wrapper is being used
   pageTitle will be: Passport Details (Domestic Card)
```

---

## Troubleshooting

### Issue: Still Shows "Passport Details (Landing - OCR)"
**Cause:** App cache not fully cleared
**Solution:** 
```bash
flutter clean
rm -rf build/
flutter pub get
flutter run
```

### Issue: Shows Default "Passport"
**Cause:** pageTitle parameter not being passed
**Solution:** Verify wrapper is passing the parameter (see Debug Step 4)

### Issue: App Won't Build
**Cause:** Dependency issues
**Solution:**
```bash
flutter clean
flutter pub get
flutter pub upgrade
flutter run
```

---

## Summary

| Step | Command | Purpose |
|------|---------|---------|
| 1 | `flutter clean` | Remove cached build files |
| 2 | `flutter pub get` | Resolve dependencies |
| 3 | `flutter run` | Full rebuild and run |
| 4 | Test app | Verify fix works |

---

## Expected Result

After following these steps:

✅ Domestic Card → Passport shows: **"Passport Details (Domestic Card)"**
✅ Landing Screen → OCR shows: **"Passport Details (Landing - OCR)"**
✅ Landing Screen → MRZ shows: **"Passport Details (Landing - MRZ)"**
✅ All visa sections visible/hidden correctly
✅ All forms work correctly

---

## Prevention

To avoid this issue in the future:

1. **Always do full rebuild** when adding constructor parameters
2. **Don't rely on hot reload** for StatefulWidget changes
3. **Test all flows** after making changes
4. **Use descriptive titles** to catch issues early

---

## Next Steps

1. Run the fix commands above
2. Test all flows
3. Verify titles are correct
4. Commit the changes if everything works

If you still have issues after following these steps, please provide:
- Console output
- Screenshots of the AppBar
- Steps to reproduce the issue
