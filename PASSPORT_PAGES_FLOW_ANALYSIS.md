# Passport Pages Flow Analysis

## Quick Answer Table

| Flow | Page Used | Visa Section | Notes |
|------|-----------|--------------|-------|
| **1. Domestic Card → Passport → MRZ** | ❌ NOT SUPPORTED | N/A | Domestic card flow only supports OCR |
| **2. Domestic Card → Passport → OCR** | ✅ **PassportCardScanPageDomestic** | Hidden | After domestic card submission |
| **3. Landing Page → Passport → MRZ** | ✅ **PassportFormPageLanding** | Visible | Via MrzScannerPage |
| **4. Landing Page → Passport → OCR** | ✅ **PassportCardScanPageLanding** | Visible | Direct OCR flow |

---

## Detailed Analysis

### 1. Domestic Card → Passport → MRZ Flow

**Status:** ❌ **NOT CURRENTLY SUPPORTED**

**Why?**
- The domestic card flow (CardScanPage) only navigates to `PassportCardScanPageDomestic` after card submission
- `PassportCardScanPageDomestic` is an OCR-based page (captures/uploads passport images)
- There is no MRZ scanner integration in the domestic card flow
- The domestic card flow is designed for Indian residents who don't need visa details

**Current Flow:**
```
CardScanPage (Domestic Card)
    ↓
Submit domestic card
    ↓
PassportCardScanPageDomestic (OCR only)
    ↓
No MRZ option available
```

**If You Need This:**
You would need to:
1. Add a "Scan Method" chooser in `PassportCardScanPageDomestic`
2. Add MRZ scanner option
3. Create navigation to `PassportFormPageDomestic` for MRZ flow
4. Update `PassportFormPageDomestic` to support MRZ results

---

### 2. Domestic Card → Passport → OCR Flow

**Status:** ✅ **FULLY SUPPORTED**

**Page Used:** `PassportCardScanPageDomestic`

**Visa Section:** ❌ Hidden

**Flow:**
```
CardScanPage (Domestic Card - Driving License, Aadhar, etc.)
    ↓
User completes card scanning/form
    ↓
Submit domestic card
    ↓
PassportCardScanPageDomestic (showVisaSection: false)
    ├─ Capture/Upload passport front image
    ├─ Capture/Upload passport back image (optional)
    ├─ Capture/Upload profile photo
    ├─ Extract passport details (OCR)
    ├─ Fill passport form (NO VISA SECTION)
    ├─ Capture signature
    └─ Submit
```

**Key Points:**
- User can capture or upload passport images
- OCR extracts passport details automatically
- Visa section is completely hidden
- Submission does NOT include visa fields
- Used for Indian residents who don't need visa

**Code Location:**
```dart
// In card_scan_page.dart (line ~523)
Navigator.of(context).pushReplacement(
  MaterialPageRoute(
    builder: (_) => const PassportCardScanPageDomestic(),
  ),
);
```

---

### 3. Landing Page → Passport → MRZ Flow

**Status:** ✅ **FULLY SUPPORTED**

**Page Used:** `PassportFormPageLanding`

**Visa Section:** ✅ Visible

**Flow:**
```
choose_card_dialog (Landing Screen)
    ↓
User selects "Passport"
    ↓
showPassportSourceDialog
    ├─ User chooses "Open Camera" or "Upload"
    └─ AppScanByMRZ setting = true (MRZ enabled)
        ↓
        MrzScannerPage (visaMode: false)
        ├─ Scan passport MRZ (camera or gallery)
        └─ Extract MRZ data
            ↓
            PassportFormPageLanding (showVisaSection: true)
            ├─ Pre-fill passport details from MRZ
            ├─ Fill remaining passport form
            ├─ Add visa details (WITH VISA SECTION)
            ├─ Select visa type
            ├─ Upload visa images (if needed)
            ├─ Capture signature
            └─ Submit (includes visa fields)
```

**Key Points:**
- User scans passport using MRZ scanner
- MRZ data is extracted and pre-fills the form
- Visa section is visible and required
- User can add visa details
- Submission includes visa fields
- Used for foreign visitors

**Code Location:**
```dart
// In choose_card_dialog.dart (Camera MRZ)
if (useMrz) {
  await _runMrzPassportScanner(nav);  // → PassportFormPageLanding
}

// In mrz_scanner_page.dart (line ~238)
Navigator.of(context).pushReplacement(
  MaterialPageRoute(
    builder: (_) => PassportFormPageLanding(scannedResult: result),
  ),
);
```

**MRZ Extraction Failure Handling:**
```dart
// If MRZ extraction fails, opens form for manual entry
nav.push(
  MaterialPageRoute(
    builder: (_) => const PassportFormPageLanding(),
  ),
);
```

---

### 4. Landing Page → Passport → OCR Flow

**Status:** ✅ **FULLY SUPPORTED**

**Page Used:** `PassportCardScanPageLanding`

**Visa Section:** ✅ Visible

**Flow:**
```
choose_card_dialog (Landing Screen)
    ↓
User selects "Passport"
    ↓
showPassportSourceDialog
    ├─ User chooses "Open Camera" or "Upload"
    └─ AppScanByMRZ setting = false (OCR enabled)
        ↓
        Camera Flow:
        ├─ PassportCardScanPageLanding (autoOpenCamera: true)
        └─ Camera opens automatically
        
        Gallery Flow:
        ├─ User picks image from gallery
        └─ PassportCardScanPageLanding (initialFrontImagePath: picked.path)
            ↓
            PassportCardScanPageLanding (showVisaSection: true)
            ├─ Capture/Upload passport front image
            ├─ Capture/Upload passport back image (optional)
            ├─ Capture/Upload profile photo
            ├─ Extract passport details (OCR)
            ├─ Fill passport form (WITH VISA SECTION)
            ├─ Add visa details
            ├─ Select visa type
            ├─ Upload visa images (if needed)
            ├─ Capture signature
            └─ Submit (includes visa fields)
```

**Key Points:**
- User captures or uploads passport images
- OCR extracts passport details automatically
- Visa section is visible and required
- User can add visa details
- Submission includes visa fields
- Used for foreign visitors

**Code Location:**
```dart
// In choose_card_dialog.dart (Camera OCR)
nav.push(
  MaterialPageRoute(
    builder: (_) => const PassportCardScanPageLanding(
      autoOpenCamera: true,
    ),
  ),
);

// In choose_card_dialog.dart (Gallery OCR)
nav.push(
  MaterialPageRoute(
    builder: (_) => PassportCardScanPageLanding(
      initialFrontImagePath: picked.path,
    ),
  ),
);
```

---

## Comparison Table

| Aspect | Domestic OCR | Landing MRZ | Landing OCR |
|--------|-------------|------------|------------|
| **Page** | PassportCardScanPageDomestic | PassportFormPageLanding | PassportCardScanPageLanding |
| **Entry Point** | CardScanPage | choose_card_dialog | choose_card_dialog |
| **Visa Section** | ❌ Hidden | ✅ Visible | ✅ Visible |
| **Visa Required** | No | Yes | Yes |
| **Scan Method** | OCR only | MRZ | OCR |
| **Image Capture** | Yes | No | Yes |
| **Auto-fill** | OCR extraction | MRZ extraction | OCR extraction |
| **Use Case** | Indian residents | Foreign visitors | Foreign visitors |
| **Visa Submission** | No visa fields | With visa fields | With visa fields |

---

## Decision Tree

```
START: User wants to add passport
    │
    ├─ From Domestic Card (Driving License, Aadhar, etc.)
    │   └─ PassportCardScanPageDomestic (OCR only, no visa)
    │
    └─ From Landing Screen (Choose Card → Passport)
        │
        ├─ MRZ Enabled (AppScanByMRZ = true)
        │   ├─ Camera
        │   │   └─ MrzScannerPage → PassportFormPageLanding (with visa)
        │   │
        │   └─ Gallery
        │       └─ MrzScannerPage → PassportFormPageLanding (with visa)
        │
        └─ OCR Enabled (AppScanByMRZ = false)
            ├─ Camera
            │   └─ PassportCardScanPageLanding (autoOpenCamera: true, with visa)
            │
            └─ Gallery
                └─ PassportCardScanPageLanding (initialFrontImagePath, with visa)
```

---

## Important Notes

### 1. Domestic Card Flow Limitation
- **Currently:** Only supports OCR (PassportCardScanPageDomestic)
- **MRZ is NOT available** in domestic card flow
- **Reason:** Domestic card flow is for Indian residents who don't need visa
- **If needed:** Would require significant changes to add MRZ support

### 2. Landing Screen Flexibility
- **MRZ or OCR:** Depends on AppScanByMRZ setting
- **Both support visa:** Visa section is always visible
- **User choice:** User can choose Camera or Gallery for both MRZ and OCR

### 3. Visa Section Behavior
- **Domestic flow:** Visa section is hidden, visa fields not submitted
- **Landing flow:** Visa section is visible, visa fields are required and submitted
- **Validation:** Visa validation only runs when visa section is visible

### 4. MRZ Extraction Failure
- If MRZ extraction fails, user can manually fill the form
- Opens PassportFormPageLanding for manual entry
- Visa section is still visible

---

## Summary

| # | Flow | Page | Visa | Status |
|---|------|------|------|--------|
| 1 | Domestic → Passport → MRZ | N/A | N/A | ❌ Not Supported |
| 2 | Domestic → Passport → OCR | PassportCardScanPageDomestic | Hidden | ✅ Supported |
| 3 | Landing → Passport → MRZ | PassportFormPageLanding | Visible | ✅ Supported |
| 4 | Landing → Passport → OCR | PassportCardScanPageLanding | Visible | ✅ Supported |

**Key Takeaway:** 
- Domestic card flow only supports OCR (no MRZ)
- Landing screen supports both MRZ and OCR
- Visa section is only visible in landing screen flows
