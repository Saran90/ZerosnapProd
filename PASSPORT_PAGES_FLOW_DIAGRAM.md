# Passport Pages Flow Diagram

## Visual Flow Chart

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          PASSPORT FLOW DECISION TREE                         │
└─────────────────────────────────────────────────────────────────────────────┘

                              START: Add Passport
                                      │
                    ┌─────────────────┴─────────────────┐
                    │                                   │
            ┌───────▼────────┐              ┌──────────▼──────────┐
            │ Domestic Card  │              │  Landing Screen    │
            │ (Aadhar, DL,   │              │  (Choose Card →    │
            │  Voters ID,    │              │   Passport)        │
            │  PAN, Other)   │              │                    │
            └───────┬────────┘              └──────────┬──────────┘
                    │                                   │
                    │                    ┌──────────────┴──────────────┐
                    │                    │                             │
                    │            ┌───────▼────────┐         ┌─────────▼────────┐
                    │            │ MRZ Enabled    │         │ OCR Enabled      │
                    │            │ (AppScanByMRZ) │         │ (AppScanByMRZ)   │
                    │            └───────┬────────┘         └─────────┬────────┘
                    │                    │                           │
                    │        ┌───────────┴───────────┐    ┌──────────┴──────────┐
                    │        │                       │    │                     │
                    │    ┌───▼────┐         ┌───────▼──┐ ┌▼────┐         ┌─────▼──┐
                    │    │ Camera │         │ Gallery  │ │Cam. │         │Gallery │
                    │    └───┬────┘         └───┬──────┘ └┬────┘         └────┬──┘
                    │        │                  │        │                    │
                    │        │                  │        │                    │
                    │        │                  │        │                    │
        ┌───────────▼────────▼──────────────────▼────────▼────────────────────▼──┐
        │                                                                          │
        │  ┌──────────────────────────────────────────────────────────────────┐  │
        │  │ FLOW 1: Domestic Card → Passport → OCR                          │  │
        │  │ ❌ MRZ NOT SUPPORTED                                             │  │
        │  │ ✅ OCR SUPPORTED                                                │  │
        │  │                                                                  │  │
        │  │ Page: PassportCardScanPageDomestic                              │  │
        │  │ Visa Section: ❌ HIDDEN                                          │  │
        │  │ Visa Fields: ❌ NOT SUBMITTED                                    │  │
        │  └──────────────────────────────────────────────────────────────────┘  │
        │                                                                          │
        │  ┌──────────────────────────────────────────────────────────────────┐  │
        │  │ FLOW 2: Landing → Passport → MRZ                                │  │
        │  │ ✅ MRZ SUPPORTED                                                │  │
        │  │ ❌ OCR NOT AVAILABLE (MRZ takes precedence)                     │  │
        │  │                                                                  │  │
        │  │ Page: PassportFormPageLanding                                   │  │
        │  │ Visa Section: ✅ VISIBLE                                        │  │
        │  │ Visa Fields: ✅ SUBMITTED                                       │  │
        │  └──────────────────────────────────────────────────────────────────┘  │
        │                                                                          │
        │  ┌──────────────────────────────────────────────────────────────────┐  │
        │  │ FLOW 3: Landing → Passport → OCR                                │  │
        │  │ ✅ OCR SUPPORTED                                                │  │
        │  │ ❌ MRZ NOT AVAILABLE (OCR takes precedence)                     │  │
        │  │                                                                  │  │
        │  │ Page: PassportCardScanPageLanding                               │  │
        │  │ Visa Section: ✅ VISIBLE                                        │  │
        │  │ Visa Fields: ✅ SUBMITTED                                       │  │
        │  └──────────────────────────────────────────────────────────────────┘  │
        │                                                                          │
        └──────────────────────────────────────────────────────────────────────────┘
```

---

## Detailed Flow Diagrams

### FLOW 1: Domestic Card → Passport → OCR

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    DOMESTIC CARD → PASSPORT → OCR                       │
│                                                                          │
│  Status: ✅ FULLY SUPPORTED                                             │
│  Page: PassportCardScanPageDomestic                                     │
│  Visa Section: ❌ HIDDEN                                                │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘

CardScanPage
│
├─ User selects domestic card type
│  (Driving License, Aadhar, Voters ID, PAN Card, Other ID)
│
├─ Capture/Upload front image
├─ Capture/Upload back image (optional)
├─ Capture/Upload profile photo
│
├─ Extract details (OCR)
├─ Fill form
├─ Verify (if applicable)
│
├─ Capture signature
│
└─ Submit domestic card
   │
   └─ ✅ PassportCardScanPageDomestic
      │
      ├─ Capture/Upload passport front image
      ├─ Capture/Upload passport back image (optional)
      ├─ Capture/Upload profile photo
      │
      ├─ Extract passport details (OCR)
      │
      ├─ Fill passport form
      │  ├─ Surname
      │  ├─ Given Names
      │  ├─ Document Number
      │  ├─ Nationality
      │  ├─ Date of Birth
      │  ├─ Gender
      │  ├─ Issuing Date
      │  ├─ Expiry Date
      │  ├─ Address
      │  ├─ Email
      │  ├─ Phone
      │  ├─ Arrival in India
      │  ├─ Duration of Stay
      │  ├─ Checkout Date
      │  └─ ❌ NO VISA SECTION
      │
      ├─ Capture signature
      │
      └─ Submit
         └─ API: savePassport (WITHOUT visa fields)
```

---

### FLOW 2: Landing → Passport → MRZ

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    LANDING → PASSPORT → MRZ                             │
│                                                                          │
│  Status: ✅ FULLY SUPPORTED                                             │
│  Page: PassportFormPageLanding                                          │
│  Visa Section: ✅ VISIBLE                                               │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘

choose_card_dialog
│
├─ User selects "Passport"
│
└─ showPassportSourceDialog
   │
   ├─ User chooses "Open Camera" or "Upload"
   │
   └─ Check AppScanByMRZ setting
      │
      └─ If MRZ Enabled (true)
         │
         ├─ Camera Flow:
         │  └─ MrzScannerPage (visaMode: false)
         │     └─ Scan passport MRZ from camera
         │
         └─ Gallery Flow:
            └─ MrzScannerPage (visaMode: false)
               └─ Scan passport MRZ from gallery image
               
         │
         └─ MRZ Extraction
            │
            ├─ ✅ Success
            │  └─ PassportFormPageLanding (scannedResult: result)
            │
            └─ ❌ Failure
               └─ PassportFormPageLanding (scannedResult: null)
                  └─ User fills form manually
                  
         │
         └─ ✅ PassportFormPageLanding
            │
            ├─ Pre-fill from MRZ (if successful)
            │  ├─ Surname
            │  ├─ Given Names
            │  ├─ Document Number
            │  ├─ Nationality
            │  ├─ Date of Birth
            │  ├─ Gender
            │  ├─ Issuing Date
            │  ├─ Expiry Date
            │  └─ Portrait (from MRZ)
            │
            ├─ Fill remaining passport details
            │  ├─ Address
            │  ├─ Email
            │  ├─ Phone
            │  ├─ Arrival in India
            │  ├─ Duration of Stay
            │  ├─ Checkout Date
            │  └─ Purpose of Visit
            │
            ├─ ✅ ADD VISA SECTION
            │  ├─ Select Visa Type
            │  │  ├─ MRZ Enable Visa
            │  │  ├─ e-Visa
            │  │  ├─ OCI
            │  │  ├─ Diplomat
            │  │  └─ No Visa
            │  │
            │  ├─ Visa Details
            │  │  ├─ Visa Number
            │  │  ├─ Visa Issuing Country
            │  │  ├─ Visa POI City
            │  │  ├─ Visa Issuing Date
            │  │  ├─ Visa Expiry Date
            │  │  └─ Visa Images (if applicable)
            │  │
            │  └─ Visa Validation
            │     ├─ Visa type required
            │     ├─ Visa images required (for e-Visa, OCI, Diplomat)
            │     ├─ Visa dates validation
            │     └─ Visa expiry check
            │
            ├─ Capture signature
            │
            └─ Submit
               └─ API: savePassport (WITH visa fields)
```

---

### FLOW 3: Landing → Passport → OCR

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    LANDING → PASSPORT → OCR                             │
│                                                                          │
│  Status: ✅ FULLY SUPPORTED                                             │
│  Page: PassportCardScanPageLanding                                      │
│  Visa Section: ✅ VISIBLE                                               │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘

choose_card_dialog
│
├─ User selects "Passport"
│
└─ showPassportSourceDialog
   │
   ├─ User chooses "Open Camera" or "Upload"
   │
   └─ Check AppScanByMRZ setting
      │
      └─ If OCR Enabled (false)
         │
         ├─ Camera Flow:
         │  └─ PassportCardScanPageLanding (autoOpenCamera: true)
         │     └─ Camera opens automatically
         │
         └─ Gallery Flow:
            └─ User picks image from gallery
               └─ PassportCardScanPageLanding (initialFrontImagePath: picked.path)
               
         │
         └─ ✅ PassportCardScanPageLanding
            │
            ├─ Capture/Upload passport front image
            ├─ Capture/Upload passport back image (optional)
            ├─ Capture/Upload profile photo
            │
            ├─ Extract passport details (OCR)
            │
            ├─ Fill passport form
            │  ├─ Surname
            │  ├─ Given Names
            │  ├─ Document Number
            │  ├─ Nationality
            │  ├─ Date of Birth
            │  ├─ Gender
            │  ├─ Issuing Date
            │  ├─ Expiry Date
            │  ├─ Address
            │  ├─ Email
            │  ├─ Phone
            │  ├─ Arrival in India
            │  ├─ Duration of Stay
            │  ├─ Checkout Date
            │  └─ Purpose of Visit
            │
            ├─ ✅ ADD VISA SECTION
            │  ├─ Select Visa Type
            │  │  ├─ MRZ Enable Visa
            │  │  ├─ e-Visa
            │  │  ├─ OCI
            │  │  ├─ Diplomat
            │  │  └─ No Visa
            │  │
            │  ├─ Visa Details
            │  │  ├─ Visa Number
            │  │  ├─ Visa Issuing Country
            │  │  ├─ Visa POI City
            │  │  ├─ Visa Issuing Date
            │  │  ├─ Visa Expiry Date
            │  │  └─ Visa Images (if applicable)
            │  │
            │  └─ Visa Validation
            │     ├─ Visa type required
            │     ├─ Visa images required (for e-Visa, OCI, Diplomat)
            │     ├─ Visa dates validation
            │     └─ Visa expiry check
            │
            ├─ Capture signature
            │
            └─ Submit
               └─ API: savePassport (WITH visa fields)
```

---

## Flow Comparison Matrix

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         FLOW COMPARISON                                  │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  FLOW 1: Domestic → Passport → OCR                                       │
│  ├─ Entry: CardScanPage (after domestic card)                           │
│  ├─ Page: PassportCardScanPageDomestic                                  │
│  ├─ Scan Method: OCR only                                               │
│  ├─ Visa Section: ❌ HIDDEN                                              │
│  ├─ Visa Submission: ❌ NO                                               │
│  └─ Use Case: Indian residents                                          │
│                                                                            │
│  FLOW 2: Landing → Passport → MRZ                                        │
│  ├─ Entry: choose_card_dialog (Passport)                                │
│  ├─ Page: PassportFormPageLanding                                       │
│  ├─ Scan Method: MRZ (Camera or Gallery)                                │
│  ├─ Visa Section: ✅ VISIBLE                                             │
│  ├─ Visa Submission: ✅ YES                                              │
│  └─ Use Case: Foreign visitors                                          │
│                                                                            │
│  FLOW 3: Landing → Passport → OCR                                        │
│  ├─ Entry: choose_card_dialog (Passport)                                │
│  ├─ Page: PassportCardScanPageLanding                                   │
│  ├─ Scan Method: OCR (Camera or Gallery)                                │
│  ├─ Visa Section: ✅ VISIBLE                                             │
│  ├─ Visa Submission: ✅ YES                                              │
│  └─ Use Case: Foreign visitors                                          │
│                                                                            │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## Key Insights

### 1. Domestic Card Flow
- **Only supports OCR** (no MRZ option)
- **No visa section** (for Indian residents)
- **Single page:** PassportCardScanPageDomestic
- **Entry point:** CardScanPage (after domestic card submission)

### 2. Landing Screen Flow
- **Supports both MRZ and OCR** (depends on AppScanByMRZ setting)
- **Always shows visa section** (for foreign visitors)
- **Two pages:** PassportFormPageLanding (MRZ) or PassportCardScanPageLanding (OCR)
- **Entry point:** choose_card_dialog (Passport option)

### 3. MRZ vs OCR
- **MRZ:** Scans passport MRZ zone, extracts data automatically
- **OCR:** Captures/uploads passport images, extracts data from images
- **Both:** Can be used in landing screen flow
- **Domestic:** Only OCR available

### 4. Visa Handling
- **Domestic flow:** Visa section hidden, no visa fields submitted
- **Landing flow:** Visa section visible, visa fields required and submitted
- **Validation:** Only runs when visa section is visible

---

## Summary Table

| Aspect | Flow 1 | Flow 2 | Flow 3 |
|--------|--------|--------|--------|
| **Name** | Domestic → OCR | Landing → MRZ | Landing → OCR |
| **Page** | PassportCardScanPageDomestic | PassportFormPageLanding | PassportCardScanPageLanding |
| **Entry** | CardScanPage | choose_card_dialog | choose_card_dialog |
| **Scan** | OCR | MRZ | OCR |
| **Visa** | ❌ Hidden | ✅ Visible | ✅ Visible |
| **Status** | ✅ Supported | ✅ Supported | ✅ Supported |
| **Users** | Indian residents | Foreign visitors | Foreign visitors |

**Note:** Flow 1 (Domestic → MRZ) is NOT currently supported.
