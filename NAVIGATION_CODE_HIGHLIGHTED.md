# Navigation Code - Highlighted Locations

## 🎯 DOMESTIC CARD → PASSPORT NAVIGATION

### Location 1: Import Statement
**File:** `lib/features/scan/presentation/pages/card_scan_page.dart`
**Line:** 16

```dart
01  import 'dart:convert';
02  import 'dart:io';
03  import 'dart:typed_data';
04  
05  import 'package:flutter/material.dart';
06  import 'package:image_picker/image_picker.dart';
07  
08  import '../../../../core/theme/app_colors.dart';
09  import '../../../../core/utils/image_crop_helper.dart';
10  import '../../../../core/widgets/image_source_dialog.dart';
11  import '../../../dashboard/presentation/widgets/choose_card_dialog.dart';
12  import '../../data/repositories/card_scan_repository.dart';
13  import '../widgets/duplicate_guest_checker.dart';
14  import '../widgets/signature_pad.dart';
15  import 'passport_card_scan_page_domestic.dart';  ← ⭐ LINE 16 - CORRECT IMPORT
16  import 'profile_crop_page.dart';
```

✅ **Correct:** Imports `passport_card_scan_page_domestic.dart`
❌ **Wrong:** Would import `passport_card_scan_page.dart` or `passport_card_scan_page_landing.dart`

---

### Location 2: Navigation Code
**File:** `lib/features/scan/presentation/pages/card_scan_page.dart`
**Lines:** 520-526

```dart
515  _snack(
516    '${widget.cardType.label} submitted successfully',
517    isError: false,
518  );
519  // Navigate to passport page without visa section (domestic card flow)
520  if (!mounted) return;
521  Navigator.of(context).pushReplacement(
522    MaterialPageRoute(
523      builder: (_) => const PassportCardScanPageDomestic(),  ← ⭐ LINE 523 - CORRECT PAGE
524    ),
525  );
526  } else {
```

✅ **Correct:** Uses `PassportCardScanPageDomestic()`
❌ **Wrong:** Would use `PassportCardScanPage()` or `PassportCardScanPageLanding()`

---

## 🎯 WRAPPER PAGE

### Location 3: Wrapper Implementation
**File:** `lib/features/scan/presentation/pages/passport_card_scan_page_domestic.dart`
**Lines:** 1-28

```dart
01  import 'package:flutter/material.dart';
02  import 'passport_card_scan_page.dart';
03  
04  /// Passport card scan page for domestic card flow (without visa section).
05  /// This is a wrapper around PassportCardScanPage with showVisaSection always set to false.
06  ///
07  /// Scenario: Domestic Card → Passport → OCR Flow
08  /// Used when: User completes a domestic card (Aadhar, Driving License, etc.)
09  /// Visa Section: Hidden (no visa needed for domestic residents)
10  class PassportCardScanPageDomestic extends StatelessWidget {
11    final String? initialFrontImagePath;
12    final bool autoOpenCamera;
13  
14    const PassportCardScanPageDomestic({
15      super.key,
16      this.initialFrontImagePath,
17      this.autoOpenCamera = false,
18    });
19  
20    @override
21    Widget build(BuildContext context) {
22      return PassportCardScanPage(
23        initialFrontImagePath: initialFrontImagePath,
24        autoOpenCamera: autoOpenCamera,
25        showVisaSection: false,                                    ← ⭐ HIDES VISA
26        pageTitle: 'Passport Details (Domestic Card)',             ← ⭐ CORRECT TITLE
27      );
28    }
29  }
```

✅ **Correct:** 
- Line 25: `showVisaSection: false` (hides visa)
- Line 26: `pageTitle: 'Passport Details (Domestic Card)'` (correct title)

❌ **Wrong:** Would have:
- `showVisaSection: true` (shows visa)
- `pageTitle: 'Passport Details (Landing - OCR)'` (wrong title)

---

## 🎯 BASE PAGE

### Location 4: Constructor
**File:** `lib/features/scan/presentation/pages/passport_card_scan_page.dart`
**Lines:** 38-46

```dart
35  class PassportCardScanPage extends StatefulWidget {
36    final String? initialFrontImagePath;
37    final bool autoOpenCamera;
38    final bool showVisaSection;
39    final String? pageTitle;  ← ⭐ ACCEPTS CUSTOM TITLE
40  
41    const PassportCardScanPage({
42      super.key,
43      this.initialFrontImagePath,
44      this.autoOpenCamera = false,
45      this.showVisaSection = true,
46      this.pageTitle,  ← ⭐ PARAMETER DEFINED
47    });
48  }
```

✅ **Correct:** Constructor accepts `pageTitle` parameter

---

### Location 5: AppBar
**File:** `lib/features/scan/presentation/pages/passport_card_scan_page.dart`
**Lines:** 728-732

```dart
725  return Scaffold(
726    appBar: AppBar(
727      backgroundColor: AppColors.primary,
728      foregroundColor: Colors.white,
729      title: Text(widget.pageTitle ?? 'Passport'),  ← ⭐ USES CUSTOM TITLE
730      elevation: 0,
731    ),
732    body: SingleChildScrollView(
```

✅ **Correct:** AppBar uses `widget.pageTitle ?? 'Passport'`

---

## 📊 COMPLETE FLOW

```
┌─────────────────────────────────────────────────────────────────┐
│ STEP 1: User Completes Domestic Card                            │
│ CardScanPage._submit()                                          │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 2: Navigation Triggered                                    │
│ card_scan_page.dart:521-525                                     │
│                                                                 │
│ Navigator.of(context).pushReplacement(                          │
│   MaterialPageRoute(                                            │
│     builder: (_) => const PassportCardScanPageDomestic(),       │
│   ),                                                            │
│ );                                                              │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 3: Wrapper Instantiated                                    │
│ PassportCardScanPageDomestic()                                  │
│ passport_card_scan_page_domestic.dart:22-27                     │
│                                                                 │
│ return PassportCardScanPage(                                    │
│   showVisaSection: false,                                       │
│   pageTitle: 'Passport Details (Domestic Card)',                │
│ );                                                              │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 4: Base Page Displayed                                     │
│ PassportCardScanPage                                            │
│ passport_card_scan_page.dart                                    │
│                                                                 │
│ AppBar (line 729):                                              │
│ title: Text(widget.pageTitle ?? 'Passport')                     │
│ = "Passport Details (Domestic Card)" ✅                         │
│                                                                 │
│ Visa Section (conditional rendering):                          │
│ if (widget.showVisaSection) ... ← FALSE, so HIDDEN ✅           │
└─────────────────────────────────────────────────────────────────┘
```

---

## ✅ VERIFICATION CHECKLIST

- [ ] Line 16 in card_scan_page.dart: `import 'passport_card_scan_page_domestic.dart';`
- [ ] Line 523 in card_scan_page.dart: `builder: (_) => const PassportCardScanPageDomestic(),`
- [ ] Line 25 in passport_card_scan_page_domestic.dart: `showVisaSection: false,`
- [ ] Line 26 in passport_card_scan_page_domestic.dart: `pageTitle: 'Passport Details (Domestic Card)',`
- [ ] Line 46 in passport_card_scan_page.dart: `this.pageTitle,` (in constructor)
- [ ] Line 729 in passport_card_scan_page.dart: `title: Text(widget.pageTitle ?? 'Passport'),`

---

## 🔍 IF SHOWING WRONG TITLE

If you're seeing "Passport Details (Landing - OCR)" instead of "Passport Details (Domestic Card)":

### Check 1: Verify Line 523
```bash
sed -n '523p' lib/features/scan/presentation/pages/card_scan_page.dart
```

Should show:
```
            builder: (_) => const PassportCardScanPageDomestic(),
```

### Check 2: Verify Line 26
```bash
sed -n '26p' lib/features/scan/presentation/pages/passport_card_scan_page_domestic.dart
```

Should show:
```
        pageTitle: 'Passport Details (Domestic Card)',
```

### Check 3: Full Rebuild
```bash
flutter clean
flutter pub get
flutter run
```

---

## 📝 SUMMARY

| What | Where | Line | Expected |
|------|-------|------|----------|
| Import | card_scan_page.dart | 16 | `passport_card_scan_page_domestic.dart` |
| Navigation | card_scan_page.dart | 523 | `PassportCardScanPageDomestic()` |
| Visa Hidden | passport_card_scan_page_domestic.dart | 25 | `showVisaSection: false` |
| Title | passport_card_scan_page_domestic.dart | 26 | `'Passport Details (Domestic Card)'` |
| Constructor | passport_card_scan_page.dart | 46 | `this.pageTitle` |
| AppBar | passport_card_scan_page.dart | 729 | `widget.pageTitle ?? 'Passport'` |

All of these should match the expected values for the domestic card flow to work correctly.
