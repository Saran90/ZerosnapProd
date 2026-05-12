# Passport Page Titles Renamed

## Summary

All four passport pages now have descriptive titles that clearly identify which scenario they are used for. The titles appear in the AppBar when the page is displayed.

---

## Page Titles by Scenario

### 1. Domestic Card → Passport → OCR Flow
**Page:** `PassportCardScanPageDomestic`
**AppBar Title:** `Passport Details (Domestic Card)`
**Visa Section:** ❌ Hidden
**Use Case:** After user completes a domestic card (Aadhar, Driving License, etc.)

```
CardScanPage
    ↓
PassportCardScanPageDomestic
    ↓
AppBar: "Passport Details (Domestic Card)"
```

---

### 2. Landing Screen → Passport → OCR Flow
**Page:** `PassportCardScanPageLanding`
**AppBar Title:** `Passport Details (Landing - OCR)`
**Visa Section:** ✅ Visible
**Use Case:** User selects Passport from landing screen and chooses OCR (Camera or Gallery)

```
choose_card_dialog (Passport)
    ↓
PassportCardScanPageLanding
    ↓
AppBar: "Passport Details (Landing - OCR)"
```

---

### 3. Landing Screen → Passport → MRZ Flow
**Page:** `PassportFormPageLanding`
**AppBar Title:** `Passport Details (Landing - MRZ)`
**Visa Section:** ✅ Visible
**Use Case:** User selects Passport from landing screen and chooses MRZ (Camera or Gallery)

```
choose_card_dialog (Passport)
    ↓
MrzScannerPage
    ↓
PassportFormPageLanding
    ↓
AppBar: "Passport Details (Landing - MRZ)"
```

---

### 4. Domestic Card → Passport → MRZ Flow
**Page:** `PassportFormPageDomestic`
**AppBar Title:** `Passport Details (Domestic Card)`
**Visa Section:** ❌ Hidden
**Status:** ❌ NOT CURRENTLY SUPPORTED
**Use Case:** Reserved for future use if MRZ support is added to domestic card flow

```
(Not currently used)
PassportFormPageDomestic
    ↓
AppBar: "Passport Details (Domestic Card)"
```

---

## Implementation Details

### Changes Made

#### 1. Base Pages Updated
Both base pages now accept an optional `pageTitle` parameter:

**passport_card_scan_page.dart:**
```dart
class PassportCardScanPage extends StatefulWidget {
  final String? initialFrontImagePath;
  final bool autoOpenCamera;
  final bool showVisaSection;
  final String? pageTitle;  // ← NEW PARAMETER
  
  const PassportCardScanPage({
    super.key,
    this.initialFrontImagePath,
    this.autoOpenCamera = false,
    this.showVisaSection = true,
    this.pageTitle,  // ← NEW PARAMETER
  });
}
```

**passport_form_page.dart:**
```dart
class PassportFormPage extends StatefulWidget {
  final MrzResult? scannedResult;
  final bool showVisaSection;
  final String? pageTitle;  // ← NEW PARAMETER
  
  const PassportFormPage({
    super.key,
    this.scannedResult,
    this.showVisaSection = true,
    this.pageTitle,  // ← NEW PARAMETER
  });
}
```

#### 2. AppBar Updated
Both base pages now use the custom title in their AppBar:

**passport_card_scan_page.dart:**
```dart
appBar: AppBar(
  backgroundColor: AppColors.primary,
  foregroundColor: Colors.white,
  title: Text(widget.pageTitle ?? 'Passport'),  // ← Uses custom title
  elevation: 0,
),
```

**passport_form_page.dart:**
```dart
appBar: AppBar(
  backgroundColor: AppColors.primary,
  foregroundColor: Colors.white,
  title: Text(widget.pageTitle ?? 'Passport Details'),  // ← Uses custom title
  elevation: 0,
),
```

#### 3. Wrapper Pages Updated
All four wrapper pages now pass the appropriate title:

**passport_card_scan_page_domestic.dart:**
```dart
return PassportCardScanPage(
  initialFrontImagePath: initialFrontImagePath,
  autoOpenCamera: autoOpenCamera,
  showVisaSection: false,
  pageTitle: 'Passport Details (Domestic Card)',  // ← Custom title
);
```

**passport_card_scan_page_landing.dart:**
```dart
return PassportCardScanPage(
  initialFrontImagePath: initialFrontImagePath,
  autoOpenCamera: autoOpenCamera,
  showVisaSection: true,
  pageTitle: 'Passport Details (Landing - OCR)',  // ← Custom title
);
```

**passport_form_page_domestic.dart:**
```dart
return PassportFormPage(
  scannedResult: scannedResult,
  showVisaSection: false,
  pageTitle: 'Passport Details (Domestic Card)',  // ← Custom title
);
```

**passport_form_page_landing.dart:**
```dart
return PassportFormPage(
  scannedResult: scannedResult,
  showVisaSection: true,
  pageTitle: 'Passport Details (Landing - MRZ)',  // ← Custom title
);
```

---

## Benefits

1. **Clear Identification:** Users can immediately see which flow they're in
2. **Developer Clarity:** Developers can quickly identify which page is being used
3. **Debugging:** Easier to debug issues when you know which page is active
4. **User Experience:** Users understand the context of the form they're filling
5. **Backward Compatible:** Default titles still work if `pageTitle` is not provided

---

## Title Naming Convention

The titles follow a consistent pattern:

```
"Passport Details (Context)"
```

Where Context is:
- `(Domestic Card)` - For domestic card flow (no visa)
- `(Landing - OCR)` - For landing screen OCR flow (with visa)
- `(Landing - MRZ)` - For landing screen MRZ flow (with visa)

---

## Visual Examples

### Domestic Card Flow
```
┌─────────────────────────────────────────┐
│ Passport Details (Domestic Card)        │
├─────────────────────────────────────────┤
│                                         │
│  Passport form without visa section     │
│                                         │
└─────────────────────────────────────────┘
```

### Landing Screen - OCR Flow
```
┌─────────────────────────────────────────┐
│ Passport Details (Landing - OCR)        │
├─────────────────────────────────────────┤
│                                         │
│  Passport form with visa section        │
│                                         │
└─────────────────────────────────────────┘
```

### Landing Screen - MRZ Flow
```
┌─────────────────────────────────────────┐
│ Passport Details (Landing - MRZ)        │
├─────────────────────────────────────────┤
│                                         │
│  Passport form with visa section        │
│                                         │
└─────────────────────────────────────────┘
```

---

## Testing

After rebuilding the app, verify the titles appear correctly:

- [ ] Domestic card flow shows: "Passport Details (Domestic Card)"
- [ ] Landing OCR flow shows: "Passport Details (Landing - OCR)"
- [ ] Landing MRZ flow shows: "Passport Details (Landing - MRZ)"
- [ ] All forms display correctly with appropriate visa sections
- [ ] No compilation errors

---

## Files Modified

1. `lib/features/scan/presentation/pages/passport_card_scan_page.dart`
   - Added `pageTitle` parameter
   - Updated AppBar to use custom title

2. `lib/features/scan/presentation/pages/passport_form_page.dart`
   - Added `pageTitle` parameter
   - Updated AppBar to use custom title

3. `lib/features/scan/presentation/pages/passport_card_scan_page_domestic.dart`
   - Updated to pass `pageTitle: 'Passport Details (Domestic Card)'`

4. `lib/features/scan/presentation/pages/passport_card_scan_page_landing.dart`
   - Updated to pass `pageTitle: 'Passport Details (Landing - OCR)'`

5. `lib/features/scan/presentation/pages/passport_form_page_domestic.dart`
   - Updated to pass `pageTitle: 'Passport Details (Domestic Card)'`

6. `lib/features/scan/presentation/pages/passport_form_page_landing.dart`
   - Updated to pass `pageTitle: 'Passport Details (Landing - MRZ)'`

---

## Backward Compatibility

✅ **Fully backward compatible**

- If `pageTitle` is not provided, defaults to original titles:
  - PassportCardScanPage → "Passport"
  - PassportFormPage → "Passport Details"
- Existing code that doesn't use `pageTitle` will continue to work
- No breaking changes

---

## Next Steps

1. **Rebuild the app:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Test all flows** to verify titles appear correctly

3. **Commit the changes:**
   ```bash
   git add .
   git commit -m "feat: Add descriptive titles to passport pages

   - Add pageTitle parameter to PassportCardScanPage and PassportFormPage
   - Update AppBar to display custom titles
   - Wrapper pages now pass descriptive titles:
     * Domestic Card: 'Passport Details (Domestic Card)'
     * Landing OCR: 'Passport Details (Landing - OCR)'
     * Landing MRZ: 'Passport Details (Landing - MRZ)'
   - Improves user experience and developer clarity"
   ```

---

## Summary

All four passport pages now have clear, descriptive titles that immediately identify which scenario they're used for. This makes it easy for both users and developers to understand the context of the form being displayed.

| Page | Title | Scenario |
|------|-------|----------|
| PassportCardScanPageDomestic | Passport Details (Domestic Card) | Domestic → OCR |
| PassportCardScanPageLanding | Passport Details (Landing - OCR) | Landing → OCR |
| PassportFormPageLanding | Passport Details (Landing - MRZ) | Landing → MRZ |
| PassportFormPageDomestic | Passport Details (Domestic Card) | Domestic → MRZ (Not Supported) |
