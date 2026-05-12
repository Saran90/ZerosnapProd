# Passport Pages Architecture

## Class Hierarchy

```
┌─────────────────────────────────────────────────────────────────┐
│                    Base Classes (Original)                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  PassportFormPage                  PassportCardScanPage          │
│  ├─ scannedResult: MrzResult?       ├─ initialFrontImagePath     │
│  ├─ showVisaSection: bool           ├─ autoOpenCamera: bool      │
│  └─ (default: true)                 ├─ showVisaSection: bool     │
│                                      └─ (default: true)           │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
                              ▲                    ▲
                              │                    │
                    ┌─────────┴────────┐  ┌────────┴─────────┐
                    │                  │  │                  │
        ┌───────────▼──────────┐  ┌────▼──▼────────────┐  ┌─▼──────────────────┐
        │ PassportFormPage     │  │ PassportCardScan   │  │ PassportCardScan   │
        │ Domestic             │  │ PageDomestic       │  │ PageLanding        │
        │                      │  │                    │  │                    │
        │ showVisaSection:     │  │ showVisaSection:   │  │ showVisaSection:   │
        │ false                │  │ false              │  │ true               │
        │                      │  │                    │  │                    │
        │ Use: Domestic card   │  │ Use: Domestic card │  │ Use: Landing       │
        │ MRZ flow             │  │ OCR flow           │  │ screen OCR flow    │
        └──────────────────────┘  └────────────────────┘  └────────────────────┘

        ┌──────────────────────┐  ┌────────────────────┐
        │ PassportFormPage     │  │ PassportFormPage   │
        │ Landing              │  │ Landing            │
        │                      │  │                    │
        │ showVisaSection:     │  │ showVisaSection:   │
        │ true                 │  │ true               │
        │                      │  │                    │
        │ Use: Landing screen  │  │ Use: Landing       │
        │ MRZ flow             │  │ screen MRZ flow    │
        └──────────────────────┘  └────────────────────┘
```

## Navigation Flow Diagram

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         DOMESTIC CARD FLOW                               │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  CardScanPage                                                             │
│  (Driving License, Aadhar, Voters ID, PAN Card, Other ID)               │
│         │                                                                 │
│         │ After successful card submission                               │
│         ▼                                                                 │
│  PassportCardScanPageDomestic ◄─── showVisaSection: false               │
│  (Capture/Upload passport images)                                        │
│         │                                                                 │
│         │ Extract passport details                                       │
│         ▼                                                                 │
│  Fill Passport Form (NO VISA SECTION)                                   │
│         │                                                                 │
│         │ Sign                                                            │
│         ▼                                                                 │
│  Submit ─────────────────────────────────────────────────────────────►  │
│                                                                            │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│                    LANDING SCREEN - OCR FLOW                             │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  choose_card_dialog                                                       │
│  (User selects "Passport")                                               │
│         │                                                                 │
│         ├─ Camera ──────────────────────────────────────────────┐        │
│         │                                                        │        │
│         │                                                        ▼        │
│         │                                    PassportCardScanPageLanding │
│         │                                    (autoOpenCamera: true)      │
│         │                                    ◄─── showVisaSection: true  │
│         │                                            │                   │
│         │                                            ▼                   │
│         │                                    Capture passport images     │
│         │                                            │                   │
│         │                                            ▼                   │
│         │                                    Extract details (OCR)       │
│         │                                            │                   │
│         │                                            ▼                   │
│         │                                    Fill Passport Form          │
│         │                                    (WITH VISA SECTION)         │
│         │                                            │                   │
│         │                                            ▼                   │
│         │                                    Add Visa Details            │
│         │                                            │                   │
│         │                                            ▼                   │
│         │                                    Sign                        │
│         │                                            │                   │
│         │                                            ▼                   │
│         │                                    Submit ──────────────────┐  │
│         │                                                             │  │
│         └─ Gallery ─────────────────────────────────────────────────┘  │
│                                                                            │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│                    LANDING SCREEN - MRZ FLOW                             │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  choose_card_dialog                                                       │
│  (User selects "Passport")                                               │
│         │                                                                 │
│         ├─ Camera ──────────────────────────────────────────────┐        │
│         │                                                        │        │
│         │                                                        ▼        │
│         │                                    MrzScannerPage              │
│         │                                    (visaMode: false)           │
│         │                                            │                   │
│         │                                            ▼                   │
│         │                                    Scan passport MRZ           │
│         │                                            │                   │
│         │                                            ▼                   │
│         │                                    PassportFormPageLanding     │
│         │                                    ◄─── showVisaSection: true  │
│         │                                            │                   │
│         │                                            ▼                   │
│         │                                    Fill Passport Form          │
│         │                                    (WITH VISA SECTION)         │
│         │                                            │                   │
│         │                                            ▼                   │
│         │                                    Add Visa Details            │
│         │                                            │                   │
│         │                                            ▼                   │
│         │                                    Sign                        │
│         │                                            │                   │
│         │                                            ▼                   │
│         │                                    Submit ──────────────────┐  │
│         │                                                             │  │
│         └─ Gallery ─────────────────────────────────────────────────┘  │
│                                                                            │
└──────────────────────────────────────────────────────────────────────────┘
```

## Data Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         SUBMISSION DATA                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  Domestic Card Flow (PassportCardScanPageDomestic)                      │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ {                                                               │   │
│  │   guest_Firstname: "...",                                       │   │
│  │   guest_Lastname: "...",                                        │   │
│  │   guest_DocumentNo: "...",                                      │   │
│  │   guest_DOB: "...",                                             │   │
│  │   guest_Gender: "...",                                          │   │
│  │   guest_DateOfIssue: "...",                                     │   │
│  │   guest_ExpiryDate: "...",                                      │   │
│  │   DateOfArrivalInIndia: "...",                                  │   │
│  │   IntendedDurationStayIndividualHouse: "...",                   │   │
│  │   Guest_HotelCheckOutDate: "...",                               │   │
│  │   passportFile: "...",                                          │   │
│  │   profileImageFile: "...",                                      │   │
│  │   GuestSignatureFile: "...",                                    │   │
│  │   // NO VISA FIELDS                                             │   │
│  │ }                                                               │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                           │
│  Landing Screen Flow (PassportCardScanPageLanding)                      │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ {                                                               │   │
│  │   guest_Firstname: "...",                                       │   │
│  │   guest_Lastname: "...",                                        │   │
│  │   guest_DocumentNo: "...",                                      │   │
│  │   guest_DOB: "...",                                             │   │
│  │   guest_Gender: "...",                                          │   │
│  │   guest_DateOfIssue: "...",                                     │   │
│  │   guest_ExpiryDate: "...",                                      │   │
│  │   DateOfArrivalInIndia: "...",                                  │   │
│  │   IntendedDurationStayIndividualHouse: "...",                   │   │
│  │   Guest_HotelCheckOutDate: "...",                               │   │
│  │   passportFile: "...",                                          │   │
│  │   profileImageFile: "...",                                      │   │
│  │   GuestSignatureFile: "...",                                    │   │
│  │   // VISA FIELDS INCLUDED                                       │   │
│  │   guest_VisaNo: "...",                                          │   │
│  │   guest_VisaPOICountry: "...",                                  │   │
│  │   Guest_VisaPOICity: "...",                                     │   │
│  │   guest_VisaDateofIssue: "...",                                 │   │
│  │   guest_VisaValidTill: "...",                                   │   │
│  │   guest_VisaType: "...",                                        │   │
│  │   VisaIDCardType: ...,                                          │   │
│  │   visaFile: "...",  // if e-Visa or Diplomat                    │   │
│  │ }                                                               │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                           │
└─────────────────────────────────────────────────────────────────────────┘
```

## Component Interaction

```
┌────────────────────────────────────────────────────────────────────────┐
│                      COMPONENT INTERACTION                              │
├────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  choose_card_dialog.dart                                               │
│  ├─ Imports: PassportCardScanPageLanding                              │
│  ├─ Imports: PassportFormPageLanding                                  │
│  └─ Navigates to: Landing pages only                                  │
│                                                                          │
│  card_scan_page.dart                                                   │
│  ├─ Imports: PassportCardScanPageDomestic                             │
│  └─ Navigates to: Domestic page only                                  │
│                                                                          │
│  mrz_scanner_page.dart                                                 │
│  ├─ Imports: PassportFormPageLanding                                  │
│  └─ Navigates to: Landing page only                                   │
│                                                                          │
│  PassportCardScanPageDomestic                                          │
│  ├─ Wraps: PassportCardScanPage(showVisaSection: false)              │
│  └─ Used by: card_scan_page.dart                                      │
│                                                                          │
│  PassportCardScanPageLanding                                           │
│  ├─ Wraps: PassportCardScanPage(showVisaSection: true)               │
│  └─ Used by: choose_card_dialog.dart                                  │
│                                                                          │
│  PassportFormPageDomestic                                              │
│  ├─ Wraps: PassportFormPage(showVisaSection: false)                  │
│  └─ Used by: (reserved for future domestic MRZ flows)                │
│                                                                          │
│  PassportFormPageLanding                                               │
│  ├─ Wraps: PassportFormPage(showVisaSection: true)                   │
│  └─ Used by: choose_card_dialog.dart, mrz_scanner_page.dart          │
│                                                                          │
└────────────────────────────────────────────────────────────────────────┘
```

## Key Design Principles

1. **Separation of Concerns**
   - Domestic flow pages handle domestic card flow only
   - Landing flow pages handle landing screen flow only
   - No mixing of concerns

2. **Type Safety**
   - No boolean flags that can be misused
   - Class names clearly indicate the flow
   - Compiler catches wrong page usage

3. **Wrapper Pattern**
   - Reuses existing logic from base classes
   - No code duplication
   - Easy to maintain

4. **Clear Navigation**
   - Each navigation source knows exactly which page to use
   - No conditional logic needed
   - Self-documenting code

5. **Extensibility**
   - Easy to add flow-specific logic in the future
   - Can override methods in wrapper classes if needed
   - Backward compatible with existing code
