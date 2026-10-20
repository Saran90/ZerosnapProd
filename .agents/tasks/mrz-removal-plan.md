# MRZ Scanner Removal Plan

## Overview
This plan removes all MRZ scanner code and dependencies from the Flutter project. The MRZ scanner was previously used for passport and visa scanning but is no longer needed. The app will rely entirely on the OCR-based scanning flow.

## Context
- **Build System**: Flutter with standard `flutter build` and `flutter test` commands
- **Dependency Manager**: Flutter pub (pubspec.yaml)
- **Test Framework**: flutter_test (standard Flutter testing)
- **MRZ Dependency**: `mrzscanner_flutter: ^1.0.0` (to be removed)
- **Verification**: `flutter pub get`, `flutter analyze`, and `flutter test` will be used to verify changes

---

## Implementation Steps

### 1. Remove MRZ scanner dependency from pubspec.yaml
**What**: Remove the `mrzscanner_flutter` package dependency.

**Files**: 
- `pubspec.yaml` (line 29)

**Changes**:
- Delete line 29: `  mrzscanner_flutter: ^1.0.0`
- Delete the comment on line 28: `  # MRZ Scanner`

**Verify**: 
```bash
flutter pub get
```
Expected: Command completes successfully without errors about missing packages.

---

### 2. Remove MRZ initialization from main.dart
**What**: Remove the import and initialization call for the MRZ scanner plugin.

**Files**:
- `lib/main.dart` (lines 6 and 31-33)

**Changes**:
- Delete line 6: `import 'package:mrzscanner_flutter/mrzscanner_flutter.dart';`
- Delete lines 31-33:
  ```dart
  Mrzflutterplugin.registerWithLicenceKey(
    '328833D4810B7B5E68109F90F66321CF4E7D4AB588DB3E3331CAE99326E0852B013A7A2E837A9B494D4295783E1804B3',
  );
  ```

**Verify**: 
```bash
flutter analyze lib/main.dart
```
Expected: No errors about unused imports or missing symbols.

---

### 3. Delete MRZ-specific entity file
**What**: Remove the MrzResult entity class since it's no longer needed.

**Files**:
- `lib/features/scan/domain/entities/mrz_result.dart` (delete entire file)

**Changes**:
- Delete the entire file

**Verify**:
```bash
flutter analyze
```
Expected: Analyzer will report errors about missing MrzResult class in files that still reference it (to be fixed in subsequent steps).

---

### 4. Update choose_card_dialog.dart to remove MRZ scanner logic
**What**: Remove all MRZ scanner imports, helper functions, and logic. Always use the OCR flow for passport scanning.

**Files**:
- `lib/features/dashboard/presentation/widgets/choose_card_dialog.dart`

**Changes**:
- Delete line 4: `import 'package:mrzscanner_flutter/mrzscanner_flutter.dart';`
- Delete line 13: `import '../../../scan/presentation/pages/mrz_scanner_page.dart';`
- Delete the entire `_runMrzPassportScanner` function (lines 44-87)
- Delete the entire `_runMrzGalleryScan` function (lines 95-165)
- In the `showPassportSourceDialog` function, remove the MRZ scanner logic:
  - In the "Open Camera" button's `onTap` handler (around line 220-232), replace the entire block with:
    ```dart
    onTap: () async {
      Navigator.of(dialogCtx).pop();
      if (!nav.context.mounted) return;
      // OCR flow — open appropriate page with camera auto-launch
      final targetPage = isDomesticCardFlow
          ? const PassportCardScanPageDomestic(autoOpenCamera: true)
          : const PassportCardScanPageLanding(autoOpenCamera: true);
      nav.push(MaterialPageRoute(builder: (_) => targetPage));
    },
    ```
  - In the "Upload" button's `onTap` handler (around line 242-263), replace the entire block with:
    ```dart
    onTap: () async {
      Navigator.of(dialogCtx).pop();
      if (!nav.context.mounted) return;
      // OCR flow — pick image then open appropriate page
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      if (picked == null || !nav.context.mounted) return;
      final targetPage = isDomesticCardFlow
          ? PassportCardScanPageDomestic(
              initialFrontImagePath: picked.path,
            )
          : PassportCardScanPageLanding(
              initialFrontImagePath: picked.path,
            );
      nav.push(MaterialPageRoute(builder: (_) => targetPage));
    },
    ```
- Update the doc comment for `showPassportSourceDialog` (lines 182-184) to remove MRZ references:
  ```dart
  /// Entry point for passport scanning.
  /// Always shows Camera / Gallery chooser using OCR-based flow.
  ///
  ```

**Verify**:
```bash
flutter analyze lib/features/dashboard/presentation/widgets/choose_card_dialog.dart
```
Expected: No errors. The file should compile successfully without MRZ references.

---

### 5. Delete MRZ scanner page file
**What**: Remove the MRZ scanner page since it's no longer used.

**Files**:
- `lib/features/scan/presentation/pages/mrz_scanner_page.dart` (delete entire file)

**Changes**:
- Delete the entire file

**Verify**:
```bash
flutter analyze
```
Expected: Analyzer will report errors in passport_form_page.dart and passport_card_scan_page.dart about missing MrzScannerPage (to be fixed in next step).

---

### 6. Update passport form and scan pages to remove MRZ visa scanner
**What**: Remove the MRZ visa scanner option and always use OCR extraction for visa data.

**Files**:
- `lib/features/scan/presentation/pages/passport_form_page.dart` (lines 22, 532-542, 558-562)
- `lib/features/scan/presentation/pages/passport_card_scan_page.dart` (lines 1127-1135, 1143-1147)

**Changes for passport_form_page.dart**:
- Delete line 22: `import 'mrz_scanner_page.dart';`
- Remove the MRZ visa scanning logic in the `_onVisaTypeChanged` method (around line 532-542):
  - Delete the condition `else if (type == 'MRZ Enable Visa') { Future.microtask(_scanVisa); }`
- Delete the entire `_scanVisa` method (lines 544-567)
- In the method that handles visa type changes, ensure it only handles 'e-Visa', 'Diplomatic/Official/Identity Certificate', and 'OCI' types

**Changes for passport_card_scan_page.dart**:
- Apply the same changes as passport_form_page.dart (remove MRZ visa scanner references)

**Note**: The passport form pages import `mrz_result.dart` at line 2 in passport_form_page_landing.dart and passport_form_page_domestic.dart. These imports will need to be removed since they reference the deleted entity.

**Changes for passport_form_page_landing.dart**:
- Delete line 2: `import '../../domain/entities/mrz_result.dart';`
- Remove the optional `scannedResult` parameter from the constructor if it exists
- Remove any code that uses the `scannedResult` parameter

**Changes for passport_form_page_domestic.dart**:
- Delete line 2: `import '../../domain/entities/mrz_result.dart';`
- Remove the optional `scannedResult` parameter from the constructor if it exists
- Remove any code that uses the `scannedResult` parameter

**Verify**:
```bash
flutter analyze lib/features/scan/presentation/pages/
```
Expected: No errors about missing MrzScannerPage or MrzResult. All scan pages compile successfully.

---

### 7. Delete MRZ result sheet widget
**What**: Remove the MRZ result display widget since it's no longer needed.

**Files**:
- `lib/features/scan/presentation/widgets/mrz_result_sheet.dart` (delete entire file)

**Changes**:
- Delete the entire file

**Verify**:
```bash
flutter analyze
```
Expected: No errors. No other files should be importing this widget.

---

### 8. Remove scanByMrz field from shared_preferences_provider.dart
**What**: Remove the `scanByMrz` flag from all session and settings classes.

**Files**:
- `lib/core/network/shared_preferences_provider.dart`

**Changes**:
- Delete line 32: `  static const _keyScanByMrz = 'scanByMrz';`
- In `saveLoginSession` method (around line 110), delete: `prefs.setBool(_keyScanByMrz, session.scanByMrz),`
- In `getLoginSession` method (around line 141), delete: `scanByMrz: prefs.getBool(_keyScanByMrz) ?? false,`
- In `saveMobileSettings` method (around line 200), delete: `prefs.setBool(_keyScanByMrz, settings.scanByMrz),`
- In the `LoginSession` class (around line 239), delete the field: `final bool scanByMrz;`
- In the `LoginSession` class doc comment (line 239), delete: `// true = MRZ scanner, false = OCR API`
- In the `LoginSession` constructor (around line 264), delete: `this.scanByMrz = false,`
- In the `LoginSession` constructor comment (line 264), delete: `// default to OCR flow`
- In the `MobileSettings` class (around line 284), delete the field: `final bool scanByMrz;`
- In the `MobileSettings` constructor (around line 299), delete: `this.scanByMrz = false,`
- In the `MobileSettings.fromJson` factory (around line 336), delete: `scanByMrz: asBool(json['AppScanByMRZ']),`

**Verify**:
```bash
flutter analyze lib/core/network/shared_preferences_provider.dart
```
Expected: Analyzer will report errors in files that still use `session.scanByMrz` (to be fixed in next step).

---

### 9. Update auth_repository.dart to remove scanByMrz parsing
**What**: Remove the parsing of the `AppScanByMRZ` field from the login API response.

**Files**:
- `lib/features/auth/data/auth_repository.dart`

**Changes**:
- In the `LoginResult.fromJson` factory (around lines 143-149), delete the entire `scanByMrz` field assignment:
  ```dart
  scanByMrz:
      (json['AppScanByMRZ'] as int? ??
          json['appScanByMRZ'] as int? ??
          json['AppScanByMrz'] as int? ??
          0) ==
      1,
  ```

**Verify**:
```bash
flutter analyze lib/features/auth/data/auth_repository.dart
```
Expected: No errors. The LoginSession will use the default value for any removed fields.

---

### 10. Update frro_credentials_page.dart to remove scanByMrz from session update
**What**: Remove the `scanByMrz` field from the session update when saving FRRO credentials.

**Files**:
- `lib/features/settings/presentation/pages/frro_credentials_page.dart`

**Changes**:
- In the `_saveCredentials` method (around line 94), delete: `scanByMrz: session.scanByMrz,`

**Verify**:
```bash
flutter analyze lib/features/settings/presentation/pages/frro_credentials_page.dart
```
Expected: No errors. The file compiles successfully.

---

### 11. Update API login endpoint
**What**: Change the login endpoint from MRZ-specific to generic authenticate endpoint.

**Files**:
- `lib/core/config/api_constants.dart`

**Changes**:
- Change line 6 from:
  ```dart
  static const String login = '/api/MRZauthenticate';
  ```
  to:
  ```dart
  static const String login = '/api/authenticate';
  ```

**Verify**:
```bash
flutter analyze lib/core/config/api_constants.dart
```
Expected: No errors. The constant is updated correctly.

---

### 12. Remove MRZ scanner namespace patch from GitHub Actions workflow
**What**: Remove the build step that patches the MRZ scanner plugin's namespace since the plugin is removed.

**Files**:
- `.github/workflows/build-android.yml`

**Changes**:
- Delete the entire "Patch mrzscanner_flutter namespace" step (lines 35-48):
  ```yaml
  - name: Patch mrzscanner_flutter namespace
    run: |
      MRZ_BUILD_GRADLE="$HOME/.pub-cache/hosted/pub.dev/mrzscanner_flutter-1.0.17/android/build.gradle"
      if [ -f "$MRZ_BUILD_GRADLE" ]; then
        # Check if namespace is already defined
        if ! grep -q "namespace" "$MRZ_BUILD_GRADLE"; then
          # Add namespace after 'android {' line
          sed -i '/^android {/a\    namespace "com.example.mrzscanner_flutter"' "$MRZ_BUILD_GRADLE"
          echo "✅ Added namespace to mrzscanner_flutter build.gradle"
        else
          echo "✅ Namespace already exists in mrzscanner_flutter"
        fi
      else
        echo "⚠️  mrzscanner_flutter build.gradle not found at expected path"
      fi
  ```

**Verify**:
```bash
cat .github/workflows/build-android.yml
```
Expected: The workflow file should have the MRZ patching step removed. The build should proceed directly from "Get Flutter dependencies" to "Run code generation".

---

### 13. Run full project verification
**What**: Ensure all changes compile and there are no lingering MRZ references.

**Commands**:
```bash
# Clean and get dependencies
flutter clean
flutter pub get

# Run static analysis
flutter analyze

# Run tests
flutter test

# Verify no MRZ references remain (should return no results)
grep -r "mrzscanner" lib/ --exclude-dir=build
grep -r "scanByMrz" lib/ --exclude-dir=build
grep -r "MrzResult" lib/ --exclude-dir=build
grep -r "MrzScannerPage" lib/ --exclude-dir=build
```

**Expected Results**:
- `flutter pub get`: Completes without errors
- `flutter analyze`: Reports no errors or warnings related to MRZ
- `flutter test`: All existing tests pass
- `grep` commands: Return no results (all MRZ references removed)

---

## Summary

This plan removes:
1. ✅ The `mrzscanner_flutter` dependency from pubspec.yaml
2. ✅ MRZ plugin initialization from main.dart
3. ✅ Three MRZ-specific files (mrz_result.dart, mrz_scanner_page.dart, mrz_result_sheet.dart)
4. ✅ MRZ scanner helper functions from choose_card_dialog.dart
5. ✅ `scanByMrz` field from shared preferences, login session, and settings classes
6. ✅ MRZ visa scanner from passport form pages
7. ✅ MRZ-specific login endpoint
8. ✅ GitHub Actions MRZ namespace patch step

After completion:
- The app will use only OCR-based scanning for all document types
- No MRZ-related code or dependencies will remain
- All passport and visa scanning will go through the existing OCR flow
- The build pipeline will be simplified without the MRZ plugin patch
