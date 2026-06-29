# Image Capture Flow Diagram

## Before Changes (Old Flow)

```
┌─────────────────────────────────────────────────────────────┐
│                    OLD FLOW                                  │
└─────────────────────────────────────────────────────────────┘

1. Capture Front Image
         ↓
2. Crop Card
         ↓
3. Crop Profile from Card
         ↓
4. ✅ Call OCR API (front only)
         ↓
5. Fill Form Fields
         ↓
6. User manually adds back image (optional)
         ↓
7. User manually submits
```

**Issues with old flow:**
- No prompt to capture back image after front
- Back image not used in OCR
- Updating images doesn't trigger OCR re-extraction
- User must remember to capture back image


## After Changes (New Flow)

```
┌─────────────────────────────────────────────────────────────┐
│                    NEW FLOW                                  │
└─────────────────────────────────────────────────────────────┘

1. Capture Front Image
         ↓
2. Crop Card
         ↓
3. Crop Profile from Card
         ↓
4. ❓ Dialog: "Capture Back Image?"
         ├─── YES ────┐
         │            ↓
         │    5a. Capture Back Image
         │            ↓
         │    5b. Crop Back Image
         │            ↓
         │    6a. ✅ Call OCR API (front + back)
         │            │
         └─── NO ─────┤
                      ↓
              6b. ✅ Call OCR API (front only)
                      ↓
              7. Fill Form Fields
                      ↓
              8. User reviews and can update images
                      ↓
       ┌──────────────┴──────────────┐
       │                             │
  Click Front Image            Click Back Image
       │                             │
       ↓                             ↓
  Update Front                  Update Back
       │                             │
       └──────────┬──────────────────┘
                  ↓
         ✅ Auto Re-call OCR API
           (with both images if available)
                  ↓
         Update Form Fields
                  ↓
         User submits
```

**Benefits of new flow:**
- ✅ Proactive prompt to capture back image
- ✅ Back image used in OCR for better accuracy
- ✅ Automatic OCR re-extraction when images updated
- ✅ Smoother user experience
- ✅ Better data extraction accuracy


## Detailed Flow for Different Scenarios

### Scenario 1: User Captures Back Image

```
Start
  │
  ├─→ Capture Front → Crop → Crop Profile
  │                              ↓
  │                        [Dialog Appears]
  │                    "Capture Back Image?"
  │                              ↓
  │                          [User: YES]
  │                              ↓
  │                    Open Camera/Gallery
  │                              ↓
  │                      Capture Back Image
  │                              ↓
  │                        Crop Back Image
  │                              ↓
  │                    ✅ OCR API Called
  │                    (front + back sent)
  │                              ↓
  │                      Form Fields Filled
  │                              ↓
  └────────────────────────→ [END]
```

### Scenario 2: User Skips Back Image

```
Start
  │
  ├─→ Capture Front → Crop → Crop Profile
  │                              ↓
  │                        [Dialog Appears]
  │                    "Capture Back Image?"
  │                              ↓
  │                          [User: NO]
  │                              ↓
  │                    ✅ OCR API Called
  │                    (front only sent)
  │                              ↓
  │                      Form Fields Filled
  │                              ↓
  └────────────────────────→ [END]
```

### Scenario 3: User Updates Front Image Later

```
Form Displayed with Extracted Data
            ↓
    [User Clicks Front Image Box]
            ↓
      "Update Front Image"
            ↓
   Camera/Gallery Opens
            ↓
    New Front Image Captured
            ↓
    ✅ OCR API Re-called
    (with front + back if back exists)
            ↓
    Form Fields Updated
            ↓
         [END]
```

### Scenario 4: User Updates Back Image Later

```
Form Displayed with Extracted Data
            ↓
    [User Clicks Back Image Box]
            ↓
   "Back Image (optional)" or 
   "Update Back Image"
            ↓
   Camera/Gallery Opens
            ↓
    New Back Image Captured
            ↓
    ✅ OCR API Re-called
    (with front + back)
            ↓
    Form Fields Updated
            ↓
         [END]
```


## UI Dialogs

### Back Image Capture Dialog

```
╔═══════════════════════════════════════════╗
║                                           ║
║       Capture Back Image?                 ║
║                                           ║
║  Do you want to capture the back image    ║
║  of the card? This can improve            ║
║  extraction accuracy.                     ║
║                                           ║
║   ┌─────────┐        ┌─────────┐         ║
║   │   No    │        │   Yes   │         ║
║   └─────────┘        └─────────┘         ║
║                                           ║
╚═══════════════════════════════════════════╝
```

### OCR Loading Overlay

```
╔═══════════════════════════════════════════╗
║                                           ║
║              ⌛ Loading...                ║
║                                           ║
║       Extracting details...               ║
║                                           ║
║  [Circular Progress Indicator]            ║
║                                           ║
╚═══════════════════════════════════════════╝
```


## Image Tiles UI Layout

### Card Scan Page

```
┌──────────────────────────────────────────────────────┐
│  DOCUMENT IMAGES                                     │
├──────────────────────────────────────────────────────┤
│                                                      │
│  ┌──────────────┐       ┌──────────────┐           │
│  │              │       │              │           │
│  │    Front     │       │   Profile    │           │
│  │    Image     │       │    Photo     │           │
│  │              │       │              │           │
│  │  [+ or 📷]   │       │  [+ or 👤]   │           │
│  └──────────────┘       └──────────────┘           │
│                                                      │
│  ┌─────────────────────────────────────┐            │
│  │                                     │            │
│  │      Back Image (optional)          │            │
│  │                                     │            │
│  │         [+ or 📷]                   │            │
│  └─────────────────────────────────────┘            │
│                                                      │
└──────────────────────────────────────────────────────┘
```

### Passport Scan Page

```
┌──────────────────────────────────────────────────────┐
│  Passport Images                                     │
├──────────────────────────────────────────────────────┤
│                                                      │
│  ┌──────────────┐       ┌──────────────┐           │
│  │              │       │              │           │
│  │  Front Page  │       │   Profile    │           │
│  │              │       │    Photo     │           │
│  │              │       │              │           │
│  │  [+ or 📄]   │       │  [+ or 👤]   │           │
│  └──────────────┘       └──────────────┘           │
│                                                      │
│  ┌─────────────────────────────────────┐            │
│  │                                     │            │
│  │  Back / Last Page (optional)        │            │
│  │                                     │            │
│  │         [+ or 📷]                   │            │
│  └─────────────────────────────────────┘            │
│                                                      │
└──────────────────────────────────────────────────────┘
```


## API Call Comparison

### Before Changes

**Cards:**
```dart
// Only when user manually triggers OCR
_repo.extract(
  frontBase64: frontBase64,
  backBase64: null,  // Back image never included
  cardType: cardType,
)
```

**Passport:**
```dart
// Only when user manually triggers OCR
_repo.extractPassport(
  frontBase64: frontBase64,
  // No back image parameter
)
```

### After Changes

**Cards:**
```dart
// Automatically called after image capture or update
_repo.extract(
  frontBase64: frontBase64,
  backBase64: backImagePath.isNotEmpty ? backBase64 : null,
  cardType: cardType,
)
```

**Passport:**
```dart
// Automatically called after image capture or update
_repo.extractPassport(
  frontBase64: frontBase64,
  // backBase64: backBase64,  // Ready for backend support
)
```


## Code Flow Summary

### Main Methods Added

1. **`_offerBackImageCapture()`**
   - Shows confirmation dialog
   - Branches to capture or skip

2. **`_captureBackImageAndExtract()`**
   - Opens image picker for back
   - Calls OCR after capture

3. **`_onFrontImageTap()`**
   - Handles front image updates
   - Triggers OCR re-extraction

4. **`_extractPassportWithBackImage()`** (Passport only)
   - Enhanced extraction with back image support
   - Prepared for future API update


## State Management

```
State Variables:
├─ _frontImagePath: String
├─ _backImagePath: String  
├─ _profileImagePath: String
├─ _isExtracting: bool (cards)
└─ _isExtractingOcr: bool (passport)

OCR Trigger Points:
1. After profile crop + back image decision
2. When front image updated (tap on filled box)
3. When back image updated (tap on filled box)
```


## Summary

The new flow ensures:
- 📸 Users are prompted to capture back image at the right time
- 🔄 OCR automatically re-runs when images are updated
- 📊 Better data extraction accuracy with both images
- ✨ Smoother, more intuitive user experience
- 🔧 Easy to maintain and extend
