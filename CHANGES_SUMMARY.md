# Image Capture Flow Enhancement - Changes Summary

## Overview
Modified the image capture flow for all card and passport pages to include an optional back image capture with user confirmation, and automatic OCR re-extraction when images are updated.

## Changes Made

### 1. Card Scan Page (`card_scan_page.dart`)
**File:** `lib/features/scan/presentation/pages/card_scan_page.dart`

#### New Flow:
1. User captures front image → crops card → crops profile from card
2. **NEW:** System asks "Do you want to capture the back image?"
3. If YES: Capture back image → Automatically call OCR with front + back
4. If NO: Automatically call OCR with only front image
5. **NEW:** When user clicks on front or back image box to update, automatically re-call OCR with both images

#### Methods Added/Modified:

- **`_offerBackImageCapture()`** - New method
  - Shows dialog asking user if they want to capture back image
  - If yes, calls `_captureBackImageAndExtract()`
  - If no, calls `_extract()` with only front image

- **`_captureBackImageAndExtract()`** - New method
  - Opens image source dialog for back image
  - After back image is captured and cropped, automatically calls `_extract()`
  - Handles cancellation gracefully by calling OCR with only front image

- **`_showFrontImageSheet()`** - Modified
  - After profile crop, now calls `_offerBackImageCapture()` instead of immediately calling `_extract()`

- **`_onFrontImageTap()`** - New method
  - Handles tapping on front image box
  - If empty, opens normal capture flow
  - If image exists, allows updating and automatically re-extracts OCR

- **`_showBackImageSheet()`** - Modified
  - Now automatically re-calls `_extract()` after back image is updated
  - Ensures both front and back images are sent to OCR

#### Dialog UI:
```
Title: "Capture Back Image?"
Message: "Do you want to capture the back image of the card? This can improve extraction accuracy."
Buttons: [No] [Yes]
```

---

### 2. Passport Card Scan Page (`passport_card_scan_page.dart`)
**File:** `lib/features/scan/presentation/pages/passport_card_scan_page.dart`

#### New Flow:
Same as card scan page:
1. User captures passport front → crops → crops profile
2. **NEW:** System asks "Do you want to capture the back image?"
3. If YES: Capture back → Automatically call OCR with front + back
4. If NO: Automatically call OCR with only front
5. **NEW:** When user updates front or back image, automatically re-call OCR

#### Methods Added/Modified:

- **`_offerBackImageCapture()`** - New method
  - Shows dialog asking user if they want to capture passport back image
  - Handles yes/no responses appropriately

- **`_captureBackImageAndExtract()`** - New method
  - Opens image source dialog for passport back/last page
  - After capture and preview confirmation, automatically calls `_extractPassportWithBackImage()`
  - Gracefully handles cancellation

- **`_extractPassportWithBackImage()`** - New method
  - Enhanced OCR extraction that prepares back image (base64 encoded)
  - Note: Currently backend API only accepts front image, but structure is ready for future enhancement
  - Includes comment: `// backBase64: backBase64, // Uncomment when API supports back image`

- **`_autoCaptureFront()`** - Modified
  - After profile crop, now calls `_offerBackImageCapture()` instead of immediately calling `_extractFromImage()`

- **`_pickFrontImage()`** - Modified
  - After profile crop, now calls `_offerBackImageCapture()`

- **`_onFrontImageTap()`** - New method
  - Handles tapping on front image to update
  - Automatically re-extracts OCR with updated front (and existing back if available)

- **`_pickBackImage()`** - Modified
  - Now automatically re-calls `_extractPassportWithBackImage()` after back image is updated

- **Widget initializer** - Modified
  - When `initialFrontImagePath` is provided (gallery flow), after profile crop, now calls `_offerBackImageCapture()`

---

## Technical Details

### OCR Re-extraction Logic

**Indian Cards (DL, Aadhar, PAN, Voter ID, Other ID):**
- `_extract()` method already supports both front and back images
- Backend endpoint: `ApiConstants.extractDL`, `extractAadhaar`, `extractVoterId`, `extractPan`
- Request includes: `idfrontbase64` (required) and `idbackbase64` (optional)

**Passport:**
- `_extractFromImage()` - Original method for front-only extraction
- `_extractPassportWithBackImage()` - New method that prepares back image
- Backend endpoint: `ApiConstants.extractPassport`
- Currently only sends front image, but prepared for back image support

### State Management
- All image paths stored in state variables: `_frontImagePath`, `_backImagePath`, `_profileImagePath`
- OCR extraction loading state: `_isExtractingOcr` (passport) / `_isExtracting` (cards)
- UI shows loading overlay during OCR extraction

### User Experience Improvements
1. **Clearer flow**: User explicitly chooses whether to capture back image
2. **Better accuracy**: Back image can improve OCR extraction
3. **Easy updates**: Clicking existing images allows re-capture and automatic re-extraction
4. **Graceful handling**: All cancellations are handled properly

---

## Testing Checklist

### Indian Cards (Aadhar, DL, PAN, Voter ID, Other ID)
- [ ] Capture front → crop → crop profile → dialog appears
- [ ] Choose "Yes" → back capture opens → capture back → OCR runs with both images
- [ ] Choose "No" → OCR runs with only front image
- [ ] Click front image when filled → update front → OCR re-runs
- [ ] Click back image when filled → update back → OCR re-runs with both images
- [ ] Verify OCR results populate form fields correctly

### Passport (Indian Passport)
- [ ] Camera flow: Capture front → crop profile → dialog appears
- [ ] Gallery flow: Select from gallery → crop profile → dialog appears
- [ ] Choose "Yes" → back capture opens → capture back → OCR runs
- [ ] Choose "No" → OCR runs with front only
- [ ] Click front image → update → OCR re-runs
- [ ] Click back image → update → OCR re-runs
- [ ] Verify OCR results populate passport fields correctly

### Edge Cases
- [ ] Cancel during back image capture → OCR runs with front only
- [ ] Cancel during image preview → handles gracefully
- [ ] Network error during OCR → error message displayed
- [ ] Multiple rapid updates → loading state prevents double-calls

---

## Backend API Compatibility

### Cards API (Currently Supported)
The card OCR endpoints already support back images:
```dart
Future<OcrResult> extract({
  required String frontBase64,
  String? backBase64,
  required String cardType,
})
```

**Request body:**
```json
{
  "idfrontbase64": "...",
  "idbackbase64": "..."  // Optional
}
```

### Passport API (Ready for Enhancement)
The passport OCR endpoint currently only accepts front image:
```dart
Future<Map<String, dynamic>?> extractPassport({
  required String frontBase64,
})
```

**To enable back image support**, update `PassportRepository.extractPassport()`:
```dart
Future<Map<String, dynamic>?> extractPassport({
  required String frontBase64,
  String? backBase64,  // Add this parameter
})
```

And update the request body in the implementation:
```dart
body: {
  'idbase64': frontBase64,
  if (backBase64 != null && backBase64.isNotEmpty)
    'idbackbase64': backBase64,
},
```

Then uncomment this line in `_extractPassportWithBackImage()`:
```dart
// backBase64: backBase64, // Uncomment when API supports back image
```

---

## Files Modified

1. `lib/features/scan/presentation/pages/card_scan_page.dart`
   - Added back image capture dialog flow
   - Added front/back image update with OCR re-extraction
   - ~80 lines of code added

2. `lib/features/scan/presentation/pages/passport_card_scan_page.dart`
   - Added back image capture dialog flow
   - Added front/back image update with OCR re-extraction
   - Prepared for future back image API support
   - ~150 lines of code added

**Total changes:** ~230 lines of code added across 2 files

---

## Notes

1. **No breaking changes**: Existing functionality remains intact
2. **Backward compatible**: Works with current API structure
3. **Future ready**: Passport back image encoding prepared for when API is updated
4. **User-friendly**: Clear dialogs and automatic OCR calls improve UX
5. **Consistent**: Same flow applied to all card types (domestic and foreign)

---

## Future Enhancements

1. **Backend API Update**: Enable passport back image processing in OCR API
2. **Image Quality Check**: Add image quality validation before OCR
3. **OCR Confidence Score**: Display confidence level of extracted data
4. **Batch Processing**: Allow multiple cards to be processed in sequence
5. **Offline Mode**: Cache images and process when connection available
