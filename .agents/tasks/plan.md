# Implementation Plan: Automatic Profile Image Cropping from Passport

## Overview
Automatically extract the passport portrait photo from the captured passport front page and display it in the profile image section of the form page. The manual crop functionality remains available as a fallback.

## Context from Codebase Exploration

### Current Flow
1. **Foreign passport flow** (`foreign_passport_scan_page.dart`):
   - Step 1: Capture passport front → OCR extraction
   - Step 2: Capture passport back (skippable) → OCR extraction
   - Step 3: Visa selection dialog → capture visa/OCI/diplomat documents
   - Navigate to `PassportCardScanPage` with `skipExtraction: true` and all image paths + OCR data

2. **Domestic passport flow** (`domestic_passport_scan_page.dart`):
   - Step 1: Capture passport front → OCR extraction
   - Step 2: Capture passport back (skippable) → OCR extraction
   - Navigate to `PassportCardScanPage` with `showVisaSection: false` and image paths + OCR data

3. **PassportCardScanPage** (`passport_card_scan_page.dart`):
   - Receives `initialFrontImagePath`, `initialBackImagePath`, `initialPassportOcrData`, etc.
   - Has `_profileImagePath` state variable
   - `_pickProfileImage()` method shows options: "Crop from Passport" or "Pick New Photo"
   - `_offerProfileCrop()` shows dialog asking if user wants to crop profile from passport

### Image Handling
- **Image package**: Already imported as `img` in scan pages for `img.decodeImage()`, `img.copyCrop()`, `img.encodeJpg()`
- **Temp directory**: Cropped images are saved in the same directory as the source image using pattern `${dir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg`
- **Existing crop function**: `cropProfileFromCard()` in `profile_crop_page.dart` opens `ImageCropper` UI for manual selection

### Passport Photo Location
Standard passport bio-data pages (ICAO 9303) have the portrait photo on the left side:
- **Horizontal position**: approximately 5-25% from left edge
- **Vertical position**: approximately 25-75% from top
- **Aspect ratio**: Photo is roughly 35mm × 45mm (roughly 3:4 portrait aspect)

## Implementation Plan

- [ ] 1. **Create passport portrait extraction utility**
      Create `lib/core/utils/passport_portrait_extractor.dart` with function `Future<String?> extractPassportPortrait(String passportFrontImagePath)`.
      
      **Logic**:
      - Decode the passport front image using `img.decodeImage()`
      - Calculate crop region based on image dimensions:
        - x: `(imageWidth * 0.05).round()` (5% from left)
        - y: `(imageHeight * 0.25).round()` (25% from top)
        - width: `(imageWidth * 0.20).round()` (20% of image width, spanning 5-25%)
        - height: `(imageHeight * 0.50).round()` (50% of image height, spanning 25-75%)
      - Clamp values to ensure they stay within image bounds
      - Use `img.copyCrop(image, x: x, y: y, width: w, height: h)` to extract the portrait region
      - Encode to JPEG with quality 90 using `img.encodeJpg(croppedImage, quality: 90)`
      - Save to same directory as source: `${File(passportFrontImagePath).parent.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg`
      - Wrap in try-catch; return null on any error (decode failure, file I/O error, etc.)
      - Add doc comments explaining the heuristic and return value
      
      **Files**: `lib/core/utils/passport_portrait_extractor.dart` (new file)
      
      **Verify**: Run `flutter analyze` in the project root and confirm no errors in the new file.

- [ ] 2. **Integrate auto-extraction into foreign_passport_scan_page.dart**
      After passport front capture and OCR in `_runPassportFrontOcr()`, automatically extract the portrait.
      
      **Exact changes**:
      - Import the new utility: `import '../../../../core/utils/passport_portrait_extractor.dart';`
      - Add a new state variable: `String? _profileImagePath;` (at line ~60, after `_visaImagePath` declaration)
      - In `_runPassportFrontOcr()`, after storing `_passportOcrData` (around line 560-565), add:
        ```dart
        // Auto-extract profile portrait from passport front
        final profilePath = await extractPassportPortrait(path);
        if (profilePath != null) {
          _profileImagePath = profilePath;
        }
        ```
      - In `_navigateToForm()` (around line 1042), add `_profileImagePath` to the navigation arguments:
        ```dart
        initialProfileImagePath: _profileImagePath,
        ```
        (This requires adding a new optional parameter to `PassportCardScanPage` constructor in step 4)
      
      **Files**: `lib/features/scan/presentation/pages/foreign_passport_scan_page.dart`
      
      **Verify**: Run `flutter analyze` and confirm no errors. Check that the navigation to `PassportCardScanPage` includes the new parameter.

- [ ] 3. **Integrate auto-extraction into domestic_passport_scan_page.dart**
      After passport front capture and OCR in `_runFrontOcr()`, automatically extract the portrait.
      
      **Exact changes**:
      - Import the new utility: `import '../../../../core/utils/passport_portrait_extractor.dart';`
      - Add a new state variable: `String? _profileImagePath;` (at line ~50, after `_backImagePath` declaration)
      - In `_runFrontOcr()`, after storing `_passportOcrData` (around line 380-385), add:
        ```dart
        // Auto-extract profile portrait from passport front
        final profilePath = await extractPassportPortrait(path);
        if (profilePath != null) {
          _profileImagePath = profilePath;
        }
        ```
      - In `_navigateToForm()` (around line 450), add `_profileImagePath` to the navigation arguments:
        ```dart
        initialProfileImagePath: _profileImagePath,
        ```
        (This requires the new optional parameter added in step 4)
      
      **Files**: `lib/features/scan/presentation/pages/domestic_passport_scan_page.dart`
      
      **Verify**: Run `flutter analyze` and confirm no errors. Check that the navigation to `PassportCardScanPage` includes the new parameter.

- [ ] 4. **Update PassportCardScanPage to accept and use auto-extracted profile**
      Add a new optional constructor parameter `initialProfileImagePath` and pre-populate `_profileImagePath` state with it.
      
      **Exact changes**:
      - In the constructor parameter list (around line 20-30), add:
        ```dart
        /// Pre-filled profile image path (auto-extracted from passport front).
        final String? initialProfileImagePath;
        ```
      - In the constructor initialization list (around line 35-45), add `this.initialProfileImagePath` to the parameter list
      - In `initState()`, after the `skipExtraction` block that sets images (around line 200-205), add:
        ```dart
        // Pre-populate profile image if auto-extracted
        if (widget.initialProfileImagePath != null && widget.initialProfileImagePath!.isNotEmpty) {
          _profileImagePath = widget.initialProfileImagePath!;
        }
        ```
      - Ensure this is added WITHIN the existing `if (widget.skipExtraction || widget.initialPassportOcrData != null)` block so it runs when coming from the scan pages
      
      **Behavior**: 
      - If auto-extraction succeeded, `_profileImagePath` is pre-populated and the profile image displays immediately
      - User can still tap "Crop from Passport" to manually adjust the selection
      - User can still tap "Pick New Photo" to capture a new photo
      - If auto-extraction failed (null), the field remains empty and user follows the existing manual flow
      
      **Files**: `lib/features/scan/presentation/pages/passport_card_scan_page.dart`
      
      **Verify**: Run `flutter analyze` and confirm no errors. The constructor now accepts the new optional parameter and the state is initialized correctly.

## Error Handling Strategy

All error handling uses try-catch with null returns to gracefully fall back to manual flow:

1. **In `extractPassportPortrait()`**: Any exception (file read, decode, crop, encode, write) returns null
2. **In scan pages**: Check `if (profilePath != null)` before assigning, so null result is ignored
3. **In form page**: Check `if (widget.initialProfileImagePath != null && widget.initialProfileImagePath!.isNotEmpty)` before using
4. **User experience**: If auto-extraction fails, the profile image field is empty and user follows existing manual flow (no crash, no error message shown)

## Verification Approach

After implementing all changes:

1. Run `flutter analyze` in `c:\Users\SARAN\Documents\Work\ZerosnapProd` → should report no errors
2. Check that the new utility file is syntactically correct
3. Check that all imports are resolved
4. Check that the navigation calls include the new parameter
5. Manual testing (if device available): Capture a real passport, observe that profile image auto-populates in the form

**Note**: Running the app on a device with a real passport is not possible in this environment, but static analysis with `flutter analyze` will confirm that the code is syntactically correct and all types are properly connected.

## Design Decisions

1. **Crop region heuristic**: Using 5-25% horizontal and 25-75% vertical based on ICAO 9303 standard passport layout where photo is on the left side of the bio-data page. This is a reasonable first approximation that works for most passports.

2. **No new dependencies**: Using the existing `image` package (already in pubspec.yaml) for all image operations. No ML/CV libraries needed for this simple region-based extraction.

3. **Same temp directory convention**: Following the existing pattern of saving cropped images in the same directory as the source image with a timestamp-based filename.

4. **Graceful fallback**: Any failure in auto-extraction results in null return, which is silently ignored, and the user continues with the existing manual flow. No error dialogs or interruptions.

5. **Non-breaking changes**: The new `initialProfileImagePath` parameter is optional, so existing code that doesn't pass it continues to work unchanged.

6. **Preserve manual control**: Users can still manually retake or adjust the profile image even after auto-extraction succeeds, maintaining full control over the final image quality.
