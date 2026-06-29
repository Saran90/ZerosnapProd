# Zerosnap Release APK Build Information

## Build Details

**Build Date:** May 19, 2026  
**Build Time:** 22:26:44  
**Build Type:** Release APK

## APK Information

- **File Name:** `app-release.apk`
- **File Path:** `build/app/outputs/flutter-apk/app-release.apk`
- **File Size:** 125.82 MB
- **Build Status:** ✅ Successfully Built

## Environment Information

- **Flutter Version:** 3.41.4 (stable channel)
- **Dart Version:** 3.11.1
- **Framework Revision:** ff37bef603
- **Engine Hash:** 99578ad0355da00edb26301c874a3c250a5716f5

## Latest Commit

- **Commit Hash:** f4ed807
- **Commit Message:** feat: Add automatic OCR extraction with loader for card pages and fix navigation
- **Branch:** master

## Features Included in This Release

### 1. Automatic OCR Extraction for Card Pages
- Automatic OCR extraction for all domestic card pages (Driving License, Aadhar, PAN, Voters ID, Other ID)
- Extraction is triggered automatically after profile image selection
- Removed manual "Extract Details" button

### 2. Loading Overlay During OCR Processing
- Semi-transparent overlay with spinner while OCR API is processing
- Displays "Extracting details..." message
- Matches the design pattern used in the passport page

### 3. Navigation Fix
- Fixed navigation after card/passport submission
- Uses `Navigator.pop()` instead of GoRouter for proper stack handling
- Applied to CardScanPage, PassportFormPage, and PassportCardScanPage

### 4. Page Title Updates
- Foreign Passport (MRZ & OCR): "Passport & VISA"
- Domestic Passport (MRZ & OCR): "Passport"

### 5. Button Label Updates
- Changed "Scan Passport" to "Scan Foreign Passport" in scan dialog

### 6. Duplicate Check Integration
- Duplicate check API is automatically called after OCR extraction
- Prevents duplicate guest registration
- Works for all card types and passport flows

## Build Warnings (Non-Critical)

- Java compiler warnings about obsolete source/target values (Java 8)
- Deprecated API usage in mrzscanner_flutter plugin
- These warnings do not affect the functionality of the app

## Installation Instructions

1. Connect your Android device or emulator
2. Run the following command:
   ```bash
   flutter install build/app/outputs/flutter-apk/app-release.apk
   ```

Or manually:
1. Transfer the APK file to your device
2. Open the file manager and tap the APK file
3. Follow the installation prompts

## Testing Recommendations

- Test automatic OCR extraction for all card types
- Verify loading overlay appears during extraction
- Test navigation back to dashboard after submission
- Verify duplicate check prevents duplicate registration
- Test all passport flows (MRZ and OCR)
- Test Terms and Conditions acceptance flow
- Test signature capture and submission

## Known Issues

None at this time.

## Next Steps

- Deploy to testing environment
- Conduct QA testing
- Prepare for production release
