# Exact Navigation Code - Domestic Card → Passport

## File: card_scan_page.dart

### Location: Lines 1-16 (Imports)
```dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/image_crop_helper.dart';
import '../../../../core/widgets/image_source_dialog.dart';
import '../../../dashboard/presentation/widgets/choose_card_dialog.dart';
import '../../data/repositories/card_scan_repository.dart';
import '../widgets/duplicate_guest_checker.dart';
import '../widgets/signature_pad.dart';
import 'passport_card_scan_page_domestic.dart';  // ← CORRECT IMPORT
import 'profile_crop_page.dart';
```

### Location: Lines 520-526 (Navigation)
```dart
        _snack(
          '${widget.cardType.label} submitted successfully',
          isError: false,
        );
        // Navigate to passport page without visa section (domestic card flow)
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const PassportCardScanPageDomestic(),  // ← CORRECT PAGE
          ),
        );
```

---

## File: passport_card_scan_page_domestic.dart

### Complete File Content
```dart
import 'package:flutter/material.dart';
import 'passport_card_scan_page.dart';

/// Passport card scan page for domestic card flow (without visa section).
/// This is a wrapper around PassportCardScanPage with showVisaSection always set to false.
///
/// Scenario: Domestic Card → Passport → OCR Flow
/// Used when: User completes a domestic card (Aadhar, Driving License, etc.)
/// Visa Section: Hidden (no visa needed for domestic residents)
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
      showVisaSection: false,                                    // ← HIDES VISA
      pageTitle: 'Passport Details (Domestic Card)',             // ← CORRECT TITLE
    );
  }
}
```

---

## File: passport_card_scan_page.dart

### Constructor (Lines 38-46)
```dart
  const PassportCardScanPage({
    super.key,
    this.initialFrontImagePath,
    this.autoOpenCamera = false,
    this.showVisaSection = true,
    this.pageTitle,  // ← ACCEPTS CUSTOM TITLE
  });
```

### AppBar (Lines 728-732)
```dart
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(widget.pageTitle ?? 'Passport'),  // ← USES CUSTOM TITLE
        elevation: 0,
      ),
```

---

## Expected Flow

```
┌─────────────────────────────────────────────────────────────────┐
│ CardScanPage._submit()                                          │
│ (After domestic card submission)                                │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ card_scan_page.dart:523                                         │
│ Navigator.of(context).pushReplacement(                          │
│   MaterialPageRoute(                                            │
│     builder: (_) => const PassportCardScanPageDomestic(),       │
│   ),                                                            │
│ );                                                              │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ PassportCardScanPageDomestic (Wrapper)                          │
│ passport_card_scan_page_domestic.dart                           │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ PassportCardScanPage (Base Page)                                │
│ passport_card_scan_page.dart                                    │
│                                                                 │
│ Parameters:                                                     │
│ ├─ showVisaSection: false                                       │
│ ├─ pageTitle: 'Passport Details (Domestic Card)'                │
│ └─ autoOpenCamera: false                                        │
│                                                                 │
│ AppBar:                                                         │
│ └─ title: Text(widget.pageTitle ?? 'Passport')                 │
│    = "Passport Details (Domestic Card)" ✅                      │
│                                                                 │
│ Visa Section:                                                   │
│ └─ if (widget.showVisaSection) ... ← FALSE, so HIDDEN ✅        │
└─────────────────────────────────────────────────────────────────┘
```

---

## What Should Happen

### Step 1: User Completes Domestic Card
```
CardScanPage (Aadhar, DL, etc.)
    ↓
User fills form
    ↓
User clicks SUBMIT
```

### Step 2: Navigation Triggered
```
card_scan_page.dart:520-526
    ↓
Navigator.of(context).pushReplacement(
  MaterialPageRoute(
    builder: (_) => const PassportCardScanPageDomestic(),
  ),
);
```

### Step 3: Wrapper Page Instantiated
```
PassportCardScanPageDomestic()
    ↓
build() method called
    ↓
Returns PassportCardScanPage with:
├─ showVisaSection: false
└─ pageTitle: 'Passport Details (Domestic Card)'
```

### Step 4: Base Page Displayed
```
PassportCardScanPage
    ↓
AppBar shows: "Passport Details (Domestic Card)" ✅
    ↓
Visa section: HIDDEN ✅
    ↓
User can fill passport details
```

---

## If Showing Wrong Title

If you're seeing "Passport Details (Landing - OCR)" instead:

### Check 1: Is the Wrapper Being Used?
Add this to `passport_card_scan_page_domestic.dart`:
```dart
@override
Widget build(BuildContext context) {
  print('✅ PassportCardScanPageDomestic wrapper is being used');
  return PassportCardScanPage(
    initialFrontImagePath: initialFrontImagePath,
    autoOpenCamera: autoOpenCamera,
    showVisaSection: false,
    pageTitle: 'Passport Details (Domestic Card)',
  );
}
```

Check console - if you see the print, wrapper is being used.

### Check 2: Is the Parameter Being Passed?
Add this to `passport_card_scan_page.dart` in `_PassportCardScanPageState.initState()`:
```dart
@override
void initState() {
  super.initState();
  print('pageTitle received: ${widget.pageTitle}');
  print('showVisaSection received: ${widget.showVisaSection}');
  // ... rest of code
}
```

Check console to see what values are received.

### Check 3: Is the AppBar Using the Parameter?
Verify line 729 in `passport_card_scan_page.dart`:
```dart
title: Text(widget.pageTitle ?? 'Passport'),
```

Should show the custom title if `pageTitle` is provided.

---

## Summary

| Component | File | Line | Code |
|-----------|------|------|------|
| Import | card_scan_page.dart | 16 | `import 'passport_card_scan_page_domestic.dart';` |
| Navigation | card_scan_page.dart | 523 | `builder: (_) => const PassportCardScanPageDomestic(),` |
| Wrapper | passport_card_scan_page_domestic.dart | 22-27 | Returns PassportCardScanPage with correct params |
| Base Page | passport_card_scan_page.dart | 38-46 | Constructor accepts pageTitle |
| AppBar | passport_card_scan_page.dart | 729 | `title: Text(widget.pageTitle ?? 'Passport')` |

---

## Verification Command

To verify the navigation code is correct:
```bash
grep -n "PassportCardScanPageDomestic" lib/features/scan/presentation/pages/card_scan_page.dart
```

Should show:
```
16:import 'passport_card_scan_page_domestic.dart';
523:            builder: (_) => const PassportCardScanPageDomestic(),
```

If it shows something different, the navigation code has been changed.
