# Automatic Visa OCR Extraction - Quick Reference

## What Was Done
Added automatic OCR extraction for visa images. When users select "e-Visa" or "Diplomat" and capture a visa image, the app automatically extracts visa details using the GetGVVisa API and displays a page loader.

## Key Changes

### State Variable
```dart
bool _isExtractingVisa = false;
```

### New Methods
```dart
_extractVisaFromImage()  // Extracts visa data using OCR
_fillVisaFromOcr()       // Populates visa fields from OCR response
```

### Updated Method
```dart
_showVisaFrontSheet()    // Now triggers automatic extraction for e-Visa/Diplomat
```

### UI
- Page loader appears while extraction is in progress
- Shows "Extracting visa details..." message
- Semi-transparent dark overlay (30% opacity)

## How It Works

1. **Visa Type Selected**: User selects "e-Visa" or "Diplomat"
2. **Image Captured**: User captures or uploads visa image
3. **Image Confirmed**: User confirms the image in preview
4. **Extraction Triggered**: 500ms delay, then GetGVVisa API is called
5. **Loader Displayed**: Page loader shows while API processes
6. **Data Extracted**: Visa document number, dates, and POI city are extracted
7. **Fields Populated**: Visa form fields are automatically filled
8. **Success Message**: User sees "Visa details extracted successfully"

## Extracted Fields
- Visa Document Number
- Issuing Date
- Expiry Date
- Place of Issue (City)

## Visa Types That Trigger Extraction
- ✅ e-Visa
- ✅ Diplomat
- ❌ OCI (requires 3 images, no auto-extraction)
- ❌ MRZ Enable Visa (uses MRZ scanner)
- ❌ No Visa (no extraction needed)

## Files Modified
- `lib/core/config/api_constants.dart` - Added endpoint
- `lib/features/scan/data/repositories/passport_repository.dart` - Added method
- `lib/features/scan/presentation/pages/passport_card_scan_page.dart` - Added UI and logic

## Testing
All files compile without errors. No diagnostics found.

## Commit
Hash: d71cff3
Message: feat: add automatic visa OCR extraction on image capture
