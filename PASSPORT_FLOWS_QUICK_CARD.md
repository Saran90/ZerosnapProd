# Passport Flows - Quick Reference Card

## The 4 Flow Combinations

### ❌ FLOW 1: Domestic Card → Passport → MRZ
**Status:** NOT SUPPORTED

```
Domestic Card (Aadhar, DL, etc.)
    ↓
PassportCardScanPageDomestic
    ↓
❌ NO MRZ OPTION AVAILABLE
```

**Why?** Domestic card flow only supports OCR. MRZ is not integrated.

**If needed:** Would require adding MRZ scanner to PassportCardScanPageDomestic

---

### ✅ FLOW 2: Domestic Card → Passport → OCR
**Status:** FULLY SUPPORTED

```
Domestic Card (Aadhar, DL, etc.)
    ↓
PassportCardScanPageDomestic
    ↓
✅ OCR EXTRACTION
    ↓
Passport Form (NO VISA)
    ↓
Submit (no visa fields)
```

**Page:** `PassportCardScanPageDomestic`
**Visa:** ❌ Hidden
**Users:** Indian residents

---

### ✅ FLOW 3: Landing Screen → Passport → MRZ
**Status:** FULLY SUPPORTED

```
Landing Screen (Choose Card → Passport)
    ↓
MrzScannerPage
    ↓
✅ MRZ EXTRACTION
    ↓
PassportFormPageLanding
    ↓
Passport Form (WITH VISA)
    ↓
Submit (with visa fields)
```

**Page:** `PassportFormPageLanding`
**Visa:** ✅ Visible
**Users:** Foreign visitors

---

### ✅ FLOW 4: Landing Screen → Passport → OCR
**Status:** FULLY SUPPORTED

```
Landing Screen (Choose Card → Passport)
    ↓
PassportCardScanPageLanding
    ↓
✅ OCR EXTRACTION
    ↓
Passport Form (WITH VISA)
    ↓
Submit (with visa fields)
```

**Page:** `PassportCardScanPageLanding`
**Visa:** ✅ Visible
**Users:** Foreign visitors

---

## Quick Decision Guide

**Q: User is completing a domestic card (Aadhar, DL, etc.)**
- A: Use `PassportCardScanPageDomestic` (OCR only, no visa)

**Q: User is from landing screen and wants to use MRZ**
- A: Use `PassportFormPageLanding` (MRZ, with visa)

**Q: User is from landing screen and wants to use OCR**
- A: Use `PassportCardScanPageLanding` (OCR, with visa)

**Q: User is from domestic card and wants to use MRZ**
- A: ❌ NOT SUPPORTED (only OCR available)

---

## Page Selection Matrix

```
                    Domestic Card    Landing Screen
                    ─────────────    ──────────────
MRZ                 ❌ Not Supported  ✅ PassportFormPageLanding
OCR                 ✅ PassportCard   ✅ PassportCardScanPage
                       ScanPageDom.      Landing
```

---

## Visa Section Visibility

| Flow | Page | Visa Section | Visa Submission |
|------|------|--------------|-----------------|
| Domestic → OCR | PassportCardScanPageDomestic | ❌ Hidden | ❌ No |
| Landing → MRZ | PassportFormPageLanding | ✅ Visible | ✅ Yes |
| Landing → OCR | PassportCardScanPageLanding | ✅ Visible | ✅ Yes |

---

## Code Locations

### Domestic Card Flow
**File:** `lib/features/scan/presentation/pages/card_scan_page.dart`
```dart
Navigator.of(context).pushReplacement(
  MaterialPageRoute(
    builder: (_) => const PassportCardScanPageDomestic(),
  ),
);
```

### Landing Screen - MRZ Flow
**File:** `lib/features/scan/presentation/pages/mrz_scanner_page.dart`
```dart
Navigator.of(context).pushReplacement(
  MaterialPageRoute(
    builder: (_) => PassportFormPageLanding(scannedResult: result),
  ),
);
```

### Landing Screen - OCR Flow
**File:** `lib/features/dashboard/presentation/widgets/choose_card_dialog.dart`
```dart
// Camera
nav.push(
  MaterialPageRoute(
    builder: (_) => const PassportCardScanPageLanding(
      autoOpenCamera: true,
    ),
  ),
);

// Gallery
nav.push(
  MaterialPageRoute(
    builder: (_) => PassportCardScanPageLanding(
      initialFrontImagePath: picked.path,
    ),
  ),
);
```

---

## Summary

| # | Flow | Page | Visa | Status |
|---|------|------|------|--------|
| 1 | Domestic → MRZ | N/A | N/A | ❌ |
| 2 | Domestic → OCR | PassportCardScanPageDomestic | ❌ | ✅ |
| 3 | Landing → MRZ | PassportFormPageLanding | ✅ | ✅ |
| 4 | Landing → OCR | PassportCardScanPageLanding | ✅ | ✅ |

---

## Key Points

✅ **Domestic card flow** = OCR only, no visa
✅ **Landing screen flow** = MRZ or OCR, with visa
✅ **Visa section** = Only visible in landing screen flows
✅ **MRZ** = Only available in landing screen flows
❌ **Domestic + MRZ** = Not currently supported

---

## Testing Checklist

- [ ] Domestic → OCR: Visa section hidden ✅
- [ ] Domestic → OCR: Submission works without visa ✅
- [ ] Landing → MRZ: Visa section visible ✅
- [ ] Landing → MRZ: Can add visa details ✅
- [ ] Landing → OCR: Visa section visible ✅
- [ ] Landing → OCR: Can add visa details ✅
- [ ] All flows: Form validation works ✅
- [ ] All flows: Submission succeeds ✅
