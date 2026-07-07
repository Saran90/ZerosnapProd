# Code Refactoring Recommendations

## Current Status

### File Sizes
- **passport_card_scan_page.dart**: 2574 lines ⚠️ (target: <800 lines)
- **passport_form_page.dart**: 2167 lines ⚠️ (target: <800 lines)
- **card_scan_page.dart**: 1306 lines ⚠️ (target: <600 lines)

## Completed Refactoring (Phase 1)

### ✅ Utility Classes Created

1. **RequestBodyLogger** (`lib/features/scan/presentation/utils/request_body_logger.dart`)
   - Centralizes API request body logging
   - Handles base64 image placeholder replacement
   - Methods: `logSavePassportBody()`, `logSaveIndianCardBody()`

2. **DateValidator** (`lib/features/scan/presentation/utils/date_validator.dart`)
   - Centralizes all date validation logic
   - Methods:
     - `validateIssuingDate()`
     - `validatePassportExpiryDate()`
     - `validateVisaIssuingDate()`
     - `validateVisaExpiryDate()`
     - `validateDocumentExpiryDate()`

3. **ImageConverter** (`lib/features/scan/presentation/utils/image_converter.dart`)
   - Centralizes image-to-base64 conversion
   - Methods: `toBase64FromPath()`, `toBase64FromPathAsync()`

### ✅ Initial Integration
- `passport_form_page.dart` now uses `DateValidator` and `ImageConverter`

---

## Recommended Refactoring (Phase 2)

### 1. Extract Form Field Widgets

**Current Issue**: Duplicate form field code across all pages

**Recommendation**: Create reusable form field components

```
lib/features/scan/presentation/widgets/form_fields/
├── text_form_field_widget.dart
├── date_picker_field_widget.dart
├── dropdown_field_widget.dart
├── searchable_dropdown_widget.dart
└── radio_group_widget.dart
```

**Benefits**:
- Reduce 300-400 lines per page
- Consistent styling and behavior
- Single source of truth for validation

---

### 2. Extract API Body Builders

**Current Issue**: Large body-building code blocks in `_submit()` methods

**Recommendation**: Create dedicated body builder classes

```
lib/features/scan/presentation/builders/
├── passport_body_builder.dart
├── visa_body_builder.dart
└── indian_card_body_builder.dart
```

**Example**:
```dart
class PassportBodyBuilder {
  static Map<String, dynamic> build({
    required PassportFormData data,
    required List<String> imagePaths,
  }) {
    return {
      'guest_Firstname': data.firstName,
      'guest_Lastname': data.lastName,
      // ... rest of fields
    };
  }
}
```

**Benefits**:
- Reduce 100-150 lines per page
- Testable body-building logic
- Easy to maintain API contract

---

### 3. Extract Image Handling Logic

**Current Issue**: Duplicate image capture, preview, and selection code

**Recommendation**: Create image handling service

```
lib/features/scan/presentation/services/
└── image_capture_service.dart
```

**Methods**:
- `captureImage(ImageSource source)`
- `showImagePreview(Uint8List bytes, String title)`
- `offerProfileCrop(String imagePath)`
- `showImageSourceDialog()`

**Benefits**:
- Reduce 200-250 lines per page
- Consistent image handling flow
- Single place to fix image-related bugs

---

### 4. Extract OCR/MRZ Extraction Logic

**Current Issue**: Duplicate extraction and error handling code

**Recommendation**: Create extraction service

```
lib/features/scan/presentation/services/
├── passport_ocr_service.dart
└── card_ocr_service.dart
```

**Benefits**:
- Reduce 150-200 lines per page
- Centralized error handling
- Testable extraction logic

---

### 5. Extract Validation Logic (Complete)

**Current Issue**: Inline validation in `_validate()` methods

**Recommendation**: Expand `DateValidator` and create field validators

```
lib/features/scan/presentation/utils/
├── date_validator.dart (✅ Done)
├── field_validator.dart (email, phone, document number)
└── form_validator.dart (complete form validation)
```

**Benefits**:
- Reduce 50-80 lines per page
- Reusable validation across forms
- Testable validation logic

---

### 6. Extract State Management

**Current Issue**: Too many state variables in single class (30+)

**Recommendation**: Create state classes and use state management pattern

```
lib/features/scan/presentation/state/
├── passport_form_state.dart
├── visa_form_state.dart
└── travel_info_state.dart
```

**Benefits**:
- Better organization
- Easier to track state changes
- Potential for BLoC/Provider pattern

---

## Expected Results After Phase 2

### File Size Reduction

| File | Current | Target | Reduction |
|------|---------|--------|-----------|
| passport_card_scan_page.dart | 2574 | ~800 | -1774 lines (69%) |
| passport_form_page.dart | 2167 | ~800 | -1367 lines (63%) |
| card_scan_page.dart | 1306 | ~600 | -706 lines (54%) |

### Code Quality Improvements

✅ **Single Responsibility**: Each file does one thing
✅ **DRY**: No duplicate code across pages  
✅ **Testability**: Business logic extracted and testable  
✅ **Maintainability**: Changes in one place, not three  
✅ **Readability**: Smaller files easier to understand  

---

## Implementation Priority

1. **High Priority** (Do First)
   - ✅ Date validation (Done)
   - ✅ Image conversion (Done)
   - ✅ Request logging (Done)
   - 🔲 API body builders
   - 🔲 Form field widgets

2. **Medium Priority**
   - 🔲 Image handling service
   - 🔲 OCR/MRZ extraction service
   - 🔲 Field validators

3. **Low Priority** (Nice to Have)
   - 🔲 State management refactor
   - 🔲 Navigation service
   - 🔲 Snackbar service

---

## Migration Strategy

### Step 1: Create Utilities (✅ Phase 1 - Done)
- Extract validators, converters, loggers
- No breaking changes

### Step 2: Create Reusable Widgets
- Build new widgets alongside old code
- Test new widgets
- Gradually replace old code

### Step 3: Extract Services
- Move business logic to services
- Keep pages as thin controllers
- Test services independently

### Step 4: Optimize State Management
- Consider BLoC or Provider if needed
- Reduce state complexity

---

## Testing Strategy

After each refactoring step:

1. **Manual Testing**: Test all flows end-to-end
2. **Unit Tests**: Test extracted utilities and services
3. **Regression Testing**: Ensure no functionality broken
4. **Performance**: Verify no performance degradation

---

## Notes

- Refactoring should be done incrementally
- Each step should be a separate commit
- Always test before moving to next step
- Keep original functionality intact
- Document any behavior changes

---

## Current Progress

**Phase 1**: ✅ Complete (Utilities created)  
**Phase 2**: 🔲 Pending (Widgets and services)

**Lines Reduced So Far**: 243 insertions, 47 deletions (net +196 for new utilities)  
**Expected Final Reduction**: ~3800 lines across 3 files  
**Estimated Time for Phase 2**: 8-12 hours
