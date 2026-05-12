# Complete Passport Flow Diagram - All 4 Scenarios

## Overview
This document shows all 4 possible passport flow combinations and which page is used for each.

---

## Scenario 1: Domestic Card → Passport → OCR Flow ✅

```
┌─────────────────────────────────────────────────────────────────────────┐
│                                                                          │
│  FLOW: Domestic Card → Passport → OCR                                   │
│                                                                          │
│  Status: ✅ FULLY SUPPORTED                                             │
│  Page: PassportCardScanPageDomestic                                     │
│  Visa Section: ❌ HIDDEN                                                │
│  Visa Fields: ❌ NOT SUBMITTED                                          │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘

Step 1: User selects domestic card (Driving License, Aadhar, etc.)
        ↓
        CardScanPage
        ├─ Capture front image
        ├─ Capture profile photo
        ├─ Extract details (OCR)
        ├─ Verify document
        └─ Submit card

Step 2: After successful submission
        ↓
        Navigator.pushReplacement(
          MaterialPageRoute(
            builder: (_) => const PassportCardScanPageDomestic(),
          ),
        );

Step 3: PassportCardScanPageDomestic wrapper
        ↓
        return PassportCardScanPage(
          pageTitle: 'Passport Details (Domestic Card)',
          showVisaSection: false,  ← Visa hidden
        );

Step 4: User sees
        ├─ AppBar: "Passport Details (Domestic Card)" ✅
        ├─ Passport form WITHOUT visa section ✅
        ├─ Camera/Gallery options for passport
        └─ Submit button (no visa fields)

Step 5: User can
        ├─ Capture passport via camera
        ├─ Upload passport from gallery
        └─ Submit passport details (no visa)
```

---

## Scenario 2: Domestic Card → Passport → MRZ Flow ❌

```
┌─────────────────────────────────────────────────────────────────────────┐
│                                                                          │
│  FLOW: Domestic Card → Passport → MRZ                                   │
│                                                                          │
│  Status: ❌ NOT SUPPORTED                                               │
│  Reason: Domestic card flow only supports OCR, not MRZ                  │
│  Page: N/A                                                              │
│  Visa Section: N/A                                                      │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘

Note: The domestic card flow does not provide an MRZ option.
      Users can only use OCR to capture passport details.
      If MRZ support is needed for domestic card flow in the future,
      PassportFormPageDomestic is already prepared for this.
```

---

## Scenario 3: Landing Screen → Passport → OCR Flow ✅

```
┌─────────────────────────────────────────────────────────────────────────┐
│                                                                          │
│  FLOW: Landing Screen → Passport → OCR                                  │
│                                                                          │
│  Status: ✅ FULLY SUPPORTED                                             │
│  Page: PassportCardScanPageLanding                                      │
│  Visa Section: ✅ VISIBLE                                               │
│  Visa Fields: ✅ SUBMITTED                                              │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘

Step 1: User on landing screen
        ↓
        Click "Passport" button

Step 2: showChooseCardDialog() opens
        ├─ Driving License
        ├─ Aadhar
        ├─ Voters ID
        ├─ PAN Card
        ├─ Passport ← User clicks here
        └─ Other ID

Step 3: Passport option clicked
        ↓
        showPassportSourceDialog(
          context,
          isDomesticCardFlow: false  ← Landing screen flow
        );

Step 4: Camera/Gallery dialog appears
        ├─ Open Camera
        ├─ Upload
        └─ Cancel

Step 5: User chooses Camera or Upload
        ↓
        PassportCardScanPageLanding(
          autoOpenCamera: true,  // if camera selected
          initialFrontImagePath: path,  // if gallery selected
        )

Step 6: PassportCardScanPageLanding wrapper
        ↓
        return PassportCardScanPage(
          pageTitle: 'Passport Details (Landing - OCR)',
          showVisaSection: true,  ← Visa visible
        );

Step 7: User sees
        ├─ AppBar: "Passport Details (Landing - OCR)" ✅
        ├─ Passport form WITH visa section ✅
        ├─ Camera/Gallery options for passport
        └─ Submit button (includes visa fields)

Step 8: User can
        ├─ Capture passport via camera
        ├─ Upload passport from gallery
        ├─ Fill visa details
        └─ Submit passport + visa details
```

---

## Scenario 4: Landing Screen → Passport → MRZ Flow ✅

```
┌─────────────────────────────────────────────────────────────────────────┐
│                                                                          │
│  FLOW: Landing Screen → Passport → MRZ                                  │
│                                                                          │
│  Status: ✅ FULLY SUPPORTED                                             │
│  Page: PassportFormPageLanding                                          │
│  Visa Section: ✅ VISIBLE                                               │
│  Visa Fields: ✅ SUBMITTED                                              │
│                                                                          │
│  Condition: Only available if AppScanByMRZ = 1 in settings              │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘

Step 1: User on landing screen
        ↓
        Click "Passport" button

Step 2: showChooseCardDialog() opens
        ↓
        User clicks "Passport"

Step 3: showPassportSourceDialog() opens
        ↓
        showPassportSourceDialog(
          context,
          isDomesticCardFlow: false  ← Landing screen flow
        );

Step 4: Camera/Gallery dialog appears
        ├─ Open Camera
        ├─ Upload
        └─ Cancel

Step 5: User chooses Camera or Upload
        ↓
        Check: session?.scanByMrz == true?
        ├─ YES: Use MRZ scanner
        └─ NO: Use OCR (Scenario 3)

Step 6: MRZ Scanner runs
        ↓
        _runMrzPassportScanner(
          nav,
          isDomesticCardFlow: false  ← Landing screen flow
        );

Step 7: MRZ extraction successful
        ↓
        PassportFormPageLanding(
          scannedResult: result,
        )

Step 8: PassportFormPageLanding wrapper
        ↓
        return PassportFormPage(
          scannedResult: scannedResult,
          pageTitle: 'Passport Details (Landing - MRZ)',
          showVisaSection: true,  ← Visa visible
        );

Step 9: User sees
        ├─ AppBar: "Passport Details (Landing - MRZ)" ✅
        ├─ Passport form WITH visa section ✅
        ├─ Pre-filled MRZ data
        └─ Submit button (includes visa fields)

Step 10: User can
         ├─ Review/edit MRZ extracted data
         ├─ Fill visa details
         └─ Submit passport + visa details
```

---

## Quick Reference Table

| Scenario | Entry Point | Page Used | Title | Visa | Status |
|----------|-------------|-----------|-------|------|--------|
| 1 | Domestic Card → Submit | `PassportCardScanPageDomestic` | "Domestic Card" | ❌ Hidden | ✅ |
| 2 | Domestic Card → MRZ | N/A | N/A | N/A | ❌ |
| 3 | Landing → Passport → Camera/Gallery | `PassportCardScanPageLanding` | "Landing - OCR" | ✅ Visible | ✅ |
| 4 | Landing → Passport → MRZ | `PassportFormPageLanding` | "Landing - MRZ" | ✅ Visible | ✅ |

---

## Navigation Logic

### From Domestic Card Flow
```
CardScanPage
    ↓
Submit successful
    ↓
PassportCardScanPageDomestic (wrapper)
    ↓
PassportCardScanPage(showVisaSection: false)
```

### From Landing Screen - Choose Card Dialog
```
Landing Screen
    ↓
Click "Passport"
    ↓
showChooseCardDialog()
    ↓
showPassportSourceDialog(context, isDomesticCardFlow: false)
    ↓
Choose Camera/Gallery
    ↓
Check AppScanByMRZ setting
├─ true: MRZ flow → PassportFormPageLanding
└─ false: OCR flow → PassportCardScanPageLanding
```

---

## Key Implementation Details

### 1. Flow Differentiation
The `isDomesticCardFlow` parameter in `showPassportSourceDialog()` allows the function to:
- Know which flow is calling it
- Navigate to the correct page
- Pass the correct `showVisaSection` value

### 2. Wrapper Pages
Each wrapper page is responsible for:
- Passing the correct `pageTitle`
- Passing the correct `showVisaSection` value
- Forwarding any additional parameters (like `scannedResult`)

### 3. Base Pages
The base pages (`PassportCardScanPage`, `PassportFormPage`) are:
- Reusable for both flows
- Configurable via parameters
- Unaware of which flow is using them

### 4. Backward Compatibility
The `isDomesticCardFlow` parameter has a default value of `false`, ensuring:
- Existing code continues to work
- Landing screen flow is the default
- No breaking changes

---

## Testing Checklist

### Scenario 1: Domestic Card → Passport → OCR
- [ ] Complete a domestic card (Driving License, Aadhar, etc.)
- [ ] Verify AppBar shows "Passport Details (Domestic Card)"
- [ ] Verify visa section is NOT visible
- [ ] Capture/upload passport
- [ ] Submit and verify no visa fields are sent

### Scenario 2: Domestic Card → Passport → MRZ
- [ ] N/A (not supported)

### Scenario 3: Landing Screen → Passport → OCR
- [ ] Click "Passport" from landing screen
- [ ] Choose Camera or Upload
- [ ] Verify AppBar shows "Passport Details (Landing - OCR)"
- [ ] Verify visa section IS visible
- [ ] Fill visa details
- [ ] Submit and verify visa fields are sent

### Scenario 4: Landing Screen → Passport → MRZ
- [ ] Enable MRZ in settings (AppScanByMRZ = 1)
- [ ] Click "Passport" from landing screen
- [ ] Choose Camera or Upload
- [ ] Verify MRZ extraction works
- [ ] Verify AppBar shows "Passport Details (Landing - MRZ)"
- [ ] Verify visa section IS visible
- [ ] Fill visa details
- [ ] Submit and verify visa fields are sent
