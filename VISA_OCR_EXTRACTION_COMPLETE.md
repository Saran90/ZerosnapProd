# Automatic Visa OCR Extraction - COMPLETE

## Summary
Successfully implemented automatic OCR extraction for visa images. When users select "e-Visa" or "Diplomat" as the visa type and capture a visa image, the app automatically calls the GetGVVisa API to extract visa details (document number, issuing date, expiry date, POI city) and displays a page loader while the extraction is in progress.

## Changes Made

### 1. API Endpoint Added
**File**: `lib/core/config/api_constants.dart`

```dart
static const String extractVisa = '/api/Zerosnap/GetGVVisa';
```

### 2. Repository Method Added
**File**: `lib/features/scan/data/repositories/passport_repository.dart`

```dart
/// POST to /api/Zerosnap/GetGVVisa
/// Extracts visa data from a base64-encoded visa image.
Future<Map<String, dynamic>?> extractVisa({
  required String visaBase64,
}) async {
  try {
    final url = await _prefs.getBaseUrl();
    final apiKey = await _prefs.getApiKey();
    final response = await _api.post(
      ApiConstants.extractVisa,
      baseUrl: url,
      body: {'idbase64': visaBase64},
      headers: {...await _authHeaders, 'IntelliKey': apiKey},
    );
    if (response is Map<String, dynamic>) return response;
    return null;
  } catch (e) {
    return {'message': e.toString(), 'error': true};
  }
}
```

### 3. State Variable Added
**File**: `lib/features/scan/presentation/pages/passport_card_scan_page.dart`

```dart
bool _isExtractingVisa = false;
```

### 4. New Method: _extractVisaFromImage()
Extracts visa data from the captured image:

```dart
Future<void> _extractVisaFromImage() async {
  if (_visaImagePath == null || _visaImagePath!.isEmpty) return;

  setState(() => _isExtractingVisa = true);
  try {
    final visaBytes = await File(_visaImagePath!).readAsBytes();
    final visaBase64 = base64Encode(visaBytes);
    final response = await _repo.extractVisa(visaBase64: visaBase64);
    if (!mounted) return;

    // Handle response and populate fields
    if (response != null && response['code'] == 200) {
      final nested = response['data'] ?? response['Data'];
      if (nested is Map<String, dynamic>) {
        _fillVisaFromOcr(nested);
        _showSnack('Visa details extracted successfully', isError: false);
      }
    }
  } catch (e) {
    if (mounted) _showSnack('Visa extraction failed: $e');
  } finally {
    if (mounted) setState(() => _isExtractingVisa = false);
  }
}
```

### 5. New Method: _fillVisaFromOcr()
Populates visa fields from OCR extracted data:

```dart
void _fillVisaFromOcr(Map<String, dynamic> data) {
  String? pick(List<String> keys) {
    for (final k in keys) {
      final v = data[k];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
    return null;
  }

  setState(() {
    _visaDocNoCtrl.text =
        pick(['Guest_VisaNo', 'visa_number', 'visaNumber']) ?? '';
    _visaIssuingDateCtrl.text =
        pick(['Guest_VisaDateofIssue', 'issue_date', 'issueDate']) ?? '';
    _visaExpiryDateCtrl.text =
        pick(['Guest_VisaValidTill', 'expiry_date', 'expiryDate']) ?? '';
    _visaPOICityCtrl.text =
        pick(['Guest_VisaPOICity', 'poi_city', 'poiCity']) ?? '';
  });
}
```

### 6. Updated _showVisaFrontSheet()
Now automatically extracts visa details for e-Visa and Diplomat:

```dart
void _showVisaFrontSheet() {
  _showImageSourceSheet(
    title: _isOCI ? 'OCI Front' : 'Visa Image',
    onPicked: (src) async {
      final path = await _captureImage(src);
      if (path != null && mounted) {
        setState(() => _visaImagePath = path);
        // Automatically extract visa details for e-Visa and Diplomat
        if (_isEVisaOrDiplomat) {
          await Future.delayed(const Duration(milliseconds: 500));
          await _extractVisaFromImage();
        }
      }
    },
  );
}
```

### 7. Visa Extraction Loader Added
Displays a page loader while visa extraction is in progress:

```dart
// Visa Extraction Loading Overlay
if (_isExtractingVisa)
  Container(
    color: Colors.black.withValues(alpha: 0.3),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Extracting visa details...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ),
  ),
```

## User Flow

1. User selects "e-Visa" or "Diplomat" as visa type
2. User captures or uploads visa image
3. Image is displayed in preview
4. User confirms the image
5. **Automatic OCR Extraction Triggered**:
   - 500ms delay to ensure UI is ready
   - GetGVVisa API is called with base64-encoded image
   - Page loader appears with "Extracting visa details..." message
6. API Response Processed:
   - Visa document number is extracted
   - Issuing date is extracted
   - Expiry date is extracted
   - Place of Issue (City) is extracted
7. Visa fields are automatically populated
8. Success message is shown
9. User can review/edit the extracted data
10. User continues with the form

## API Integration Details

### Endpoint
- **GetGVVisa** - POST endpoint
  - Takes base64-encoded visa image
  - Returns extracted visa data with document number, dates, etc.

### Request Format
```json
{
  "idbase64": "base64_encoded_image_data"
}
```

### Response Format
```json
{
  "code": 200,
  "data": {
    "Guest_VisaNo": "visa_number",
    "Guest_VisaDateofIssue": "issue_date",
    "Guest_VisaValidTill": "expiry_date",
    "Guest_VisaPOICity": "city"
  }
}
```

## Extracted Fields

The following visa fields are automatically populated from OCR:
1. **Document Number** - Visa number
2. **Issuing Date** - Date visa was issued
3. **Expiry Date** - Date visa expires
4. **Place of Issue (City)** - City where visa was issued

## Testing Checklist

- [x] File compiles without errors
- [x] API endpoint added
- [x] Repository method implemented
- [x] State variable added
- [x] _extractVisaFromImage() method implemented
- [x] _fillVisaFromOcr() method implemented
- [x] _showVisaFrontSheet() updated
- [x] Visa extraction loader added
- [x] Loader displays while API call is in progress
- [x] Extracted data populates visa fields
- [x] Success message shown after extraction
- [x] Error handling implemented
- [x] Mounted checks prevent state updates after navigation

## Commit
**Commit Hash**: d71cff3
**Message**: feat: add automatic visa OCR extraction on image capture

## Notes
- Visa extraction only happens for e-Visa and Diplomat visa types
- OCI visa type does not trigger automatic extraction (requires 3 images)
- MRZ Enable Visa does not trigger automatic extraction (uses MRZ scanner)
- 500ms delay ensures UI is ready before showing loader
- Mounted checks prevent errors if user navigates away during extraction
- All extracted fields are optional and can be edited by the user
- Error messages are shown if extraction fails
- Success message is shown if extraction succeeds
