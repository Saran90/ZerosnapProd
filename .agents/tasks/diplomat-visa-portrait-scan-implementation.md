# Diplomat Visa Portrait Scan Implementation

## Summary

Successfully implemented a dedicated diplomat visa scanning step with portrait orientation scan area, exactly matching the provided screenshot requirements.

## What Was Implemented

### 1. New Diplomat Visa Step

Created a separate `_ScanStep.diplomatVisa` to distinguish from regular e-Visa scanning:

```dart
enum _ScanStep {
  passportFront,    // Step 1 of 3 or 5
  passportBack,     // Step 2 of 3 or 5 (skippable)
  visa,             // Step 3 of 3 (for e-Visa flow)
  diplomatVisa,     // Step 3 of 3 (for diplomat flow, skippable) ✨ NEW
  ociCardFront,     // Step 3 of 5 (for OCI flow)
  ociCardBack,      // Step 4 of 5 (for OCI flow, skippable)
  ociStampPage,     // Step 5 of 5 (for OCI flow, skippable)
}
```

### 2. Portrait Orientation Scan Area

**Key Difference from Screenshot**: Changed from landscape to portrait orientation as requested.

#### Original Screenshot
- Showed landscape scan area (wider than tall)

#### Implemented
- **Portrait scan area** (taller than wide)
- **Width**: 70% of screen width (narrower than landscape)
- **Height**: Width × 1.5 (2:3 aspect ratio)
- **Result**: Vertical rectangle perfect for diplomat visa documents

#### Comparison with Other Steps
| Step Type | Width | Height | Ratio | Orientation |
|-----------|-------|--------|-------|-------------|
| Passport Front | 88% | Width × 0.66 | 3:2 | Landscape |
| Passport Back | 88% | Width × 0.66 | 3:2 | Landscape |
| Regular Visa | 88% | Width × 0.66 | 3:2 | Landscape |
| **Diplomat Visa** | **70%** | **Width × 1.5** | **2:3** | **Portrait** ✨ |
| OCI Cards | 88% | Width × 0.66 | 3:2 | Landscape |

### 3. UI Elements

#### Step Title
```
"Step 3 of 3 · Diplomat Visa (Optional)"
```

#### Instruction Label
```
"SCAN DIPLOMAT VISA – FRONT"
```

#### Skip Button
- **Primary text**: "Skip this step"
- **Secondary text**: "Diplomatic passport holders are not always required to hold a visa"
- Positioned at bottom of screen
- Only visible in full flow mode (not retake mode)

#### Visual Style
- **Golden brackets** (AppColors.accent)
- Same styling as passport front and regular visa
- Portrait orientation scan rectangle

### 4. Technical Implementation

#### Extension Method
```dart
extension _ScanStepExt on _ScanStep {
  /// Whether this step should use portrait scan area instead of landscape
  bool get usesPortraitScanArea {
    return this == _ScanStep.diplomatVisa;
  }
}
```

#### Dynamic Scan Rectangle (_ScanOverlay)
```dart
if (step.usesPortraitScanArea) {
  // Portrait orientation for diplomat visa (2:3 ratio)
  rectW = size.width * 0.70;
  rectH = rectW * 1.5;
} else {
  // Landscape orientation for all other steps (3:2 ratio)
  rectW = size.width * 0.88;
  rectH = rectW * 0.66;
}
```

#### Auto-Crop to Scan Area (_cropToScanRect)
```dart
// Use portrait or landscape based on current step
if (_currentStep.usesPortraitScanArea) {
  rectW = screenW * 0.70;
  rectH = rectW * 1.5;
} else {
  rectW = screenW * 0.88;
  rectH = rectW * 0.66;
}
```

### 5. OCR Integration

#### Method: `_runDiplomatVisaOcr(String path)`
- Uses existing `PassportRepository.extractVisa()` API
- Sets analysis label: "Extracting diplomat visa details..."
- On success: Stores data in `_visaOcrData` and navigates to form
- On failure: Shows error dialog with retry/skip options

#### Error Handling
- Custom dialog: `_showDiplomatVisaErrorDialog`
- Title: "Diplomat Visa Scan Failed"
- Two options:
  - **Retake Visa Photo** (primary action, golden button)
  - **Continue without Visa** (secondary action, outlined button)

### 6. Flow Integration

#### From Dialog Selection
```dart
case VisaDocumentType.diplomatPassport:
  // Advance to diplomat visa scanning step (skippable, portrait orientation)
  setState(() => _currentStep = _ScanStep.diplomatVisa);
  break;
```

#### Skip Functionality
```dart
case _ScanStep.diplomatVisa:
  // Skip diplomat visa → navigate to form without visa
  _navigateToForm();
  break;
```

#### After Passport Back Skip
```dart
else if (_selectedVisaDocType == VisaDocumentType.diplomatPassport) {
  setState(() => _currentStep = _ScanStep.diplomatVisa);
}
```

### 7. User Flow

**Complete Diplomat Passport Flow:**

1. User scans passport front (Step 1 of 3)
2. User scans passport back (Step 2 of 3, skippable)
3. Dialog appears with 4 visa options
4. **User selects "Diplomat Passport"**
5. Camera shows diplomat visa scan screen (Step 3 of 3)
   - Title: "Diplomat Visa (Optional)"
   - Portrait scan area (tall rectangle)
   - Golden brackets
   - Instruction: "SCAN DIPLOMAT VISA – FRONT"
   - Skip button visible with diplomat-specific text
6. User can:
   - **Option A**: Capture diplomat visa → OCR extraction → Navigate to form with visa data
   - **Option B**: Press skip button → Navigate to form without visa data
   - **Option C (if OCR fails)**: Retry or continue without visa

## Code Changes

### Files Modified
- `lib/features/scan/presentation/pages/foreign_passport_scan_page.dart`
  - Added 226 lines
  - Modified 10 lines

### Key Additions
1. `_ScanStep.diplomatVisa` enum value
2. `usesPortraitScanArea` extension getter
3. `_runDiplomatVisaOcr()` method (38 lines)
4. `_showDiplomatVisaErrorDialog()` method (152 lines)
5. Portrait rectangle calculation in `_ScanOverlay.build()`
6. Portrait rectangle calculation in `_cropToScanRect()`
7. Updated switch cases in `_processCapture()`, `_skipCurrentStep()`, `_showCropUI()`
8. Updated skip button text logic
9. Updated dialog handler for diplomat option

## Comparison: e-Visa vs Diplomat Visa

| Feature | e-Visa | Diplomat Visa |
|---------|--------|---------------|
| Step Name | "Visa" | "Diplomat Visa (Optional)" |
| Instruction | "SCAN VISA – FRONT" | "SCAN DIPLOMAT VISA – FRONT" |
| Scan Area | Landscape (3:2) | Portrait (2:3) ✨ |
| Width | 88% | 70% |
| Skippable | No | Yes ✨ |
| Skip Text | N/A | "Diplomatic passport holders..." |
| Bracket Color | Golden | Golden |
| OCR Method | `_runVisaOcr` | `_runDiplomatVisaOcr` |
| Error Dialog | `_showVisaErrorDialog` | `_showDiplomatVisaErrorDialog` |

## Testing Checklist

### Visual Verification
- [ ] Portrait scan area is taller than wide
- [ ] Scan area is centered horizontally
- [ ] Golden brackets appear on all four corners
- [ ] Skip button appears at bottom
- [ ] Title shows "Diplomat Visa (Optional)"
- [ ] Instruction shows "SCAN DIPLOMAT VISA – FRONT"

### Functional Testing
- [ ] Selecting "Diplomat Passport" from dialog advances to diplomat visa step
- [ ] Portrait scan area is visible and properly sized
- [ ] Shutter button works and captures image
- [ ] Gallery button works and allows image selection
- [ ] OCR runs after capture ("Extracting diplomat visa details...")
- [ ] Successful OCR navigates to form with visa data
- [ ] Failed OCR shows error dialog with retry/skip options
- [ ] Skip button navigates to form without visa data
- [ ] Skip button text matches requirement
- [ ] Retake from error dialog works

### Edge Cases
- [ ] Portrait orientation on different screen sizes
- [ ] Landscape device orientation (if supported)
- [ ] Gallery image cropping maintains portrait aspect
- [ ] Auto-crop from camera uses portrait dimensions
- [ ] Error dialog handles network failures
- [ ] Error dialog handles API errors

### Integration Testing
- [ ] Passport front + back + diplomat visa (captured) → Form receives all images
- [ ] Passport front + back + diplomat visa (skipped) → Form receives only passport
- [ ] Passport front + skip back + diplomat visa → Works correctly
- [ ] Retake mode should not show diplomat visa option

## Dimensions Reference

### Portrait Scan Area (Diplomat Visa)
```dart
screenWidth = Device width (e.g., 360dp)
rectW = screenWidth * 0.70        // 252dp
rectH = rectW * 1.5                // 378dp
rectLeft = (screenWidth - rectW) / 2  // 54dp
rectTop = screenHeight * 0.30      // Variable
```

**Example on 360×640 screen:**
- Width: 252dp
- Height: 378dp
- Left: 54dp
- Top: 192dp

### Landscape Scan Area (All Others)
```dart
rectW = screenWidth * 0.88        // 316.8dp
rectH = rectW * 0.66              // 209dp
```

**Example on 360×640 screen:**
- Width: 316.8dp
- Height: 209dp

## API Integration

### Endpoint Used
```dart
await _repo.extractVisa(visaBase64: base64)
```

Same endpoint as regular visa, but with diplomat-specific:
- Analysis label
- Error messages
- Error dialog title

## Known Limitations

1. **Portrait Orientation Only for Diplomat Visa**
   - All other steps use landscape
   - Crop UI still offers both ratios for manual adjustment

2. **Same OCR Endpoint**
   - Uses generic visa OCR endpoint
   - May need diplomat-specific endpoint for better accuracy

3. **Single Image Only**
   - Captures only front of diplomat visa
   - No back or additional pages

## Next Steps

### Immediate
1. **Test on real device** with diplomat visa document
2. **Verify portrait scan area** fits typical diplomat visa size
3. **Test OCR accuracy** with diplomat visa samples

### Future Enhancements
1. Add diplomat-specific OCR endpoint if needed
2. Support multiple pages for diplomat visa
3. Add diplomat visa preview screen
4. Improve OCR field mapping for diplomat visa format
5. Add analytics for diplomat visa usage

## Commit Information

**Commit**: 33cd397
**Branch**: redesign-card-scan
**Message**: "feat: Add diplomat visa scanning with portrait orientation"

**Changes**:
- 1 file changed
- 226 insertions(+)
- 10 deletions(-)

## Success Criteria

### ✅ Completed
- [x] Separate diplomat visa step created
- [x] Portrait orientation implemented (2:3 ratio)
- [x] 70% width scan area (narrower than landscape)
- [x] Golden brackets displayed
- [x] Skip functionality with custom text
- [x] Title shows "Diplomat Visa (Optional)"
- [x] Instruction shows "SCAN DIPLOMAT VISA – FRONT"
- [x] OCR extraction integrated
- [x] Error handling with retry/skip options
- [x] Code compiles without errors
- [x] Follows existing patterns

### 🔄 Pending
- [ ] Real device testing
- [ ] OCR accuracy verification
- [ ] Form integration testing
- [ ] Multiple screen size testing

## Visual Comparison

### Before
All visa types used landscape orientation (3:2 ratio)

### After
- **e-Visa**: Landscape orientation (3:2 ratio)
- **Diplomat Visa**: Portrait orientation (2:3 ratio) ✨ NEW
- **OCI Card**: Landscape orientation (3:2 ratio)

This change makes the diplomat visa scanning more ergonomic for typical diplomat visa document sizes, which are often taller than regular visa stickers.
