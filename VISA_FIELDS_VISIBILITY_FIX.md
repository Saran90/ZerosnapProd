# Visa Fields Visibility Fix - COMPLETE

## Summary
Updated the visa section to show all visa fields immediately when any visa option (except "No Visa") is selected, instead of waiting for image capture.

## What Changed

### Before
Visa fields were only shown after:
- e-Visa/Diplomat: Image was captured
- OCI: Image was captured
- MRZ Enable Visa: Visa was scanned

### After
Visa fields are shown immediately when:
- Any visa type is selected (except "No Visa")
- User can fill in visa details before capturing images
- User can fill in visa details after capturing images

## Implementation

### Updated Logic
**File**: `lib/features/scan/presentation/pages/passport_card_scan_page.dart`

```dart
// OLD
bool get _showVisaFields =>
    (_isEVisaOrDiplomat && _visaImagePath != null) ||
    (_isOCI && _visaImagePath != null) ||
    (_visaType == 'MRZ Enable Visa' && _scannedVisa != null);

// NEW
bool get _showVisaFields => _visaType.isNotEmpty && _visaType != 'No Visa';
```

## Visa Fields Displayed

When any visa option is selected (except "No Visa"), the following fields are shown:
1. **Document Number** - Visa number
2. **Issuing Country** - Country that issued the visa (searchable dropdown)
3. **Visa Type** - Type of visa (searchable dropdown)
4. **Visa Sub Type** - Sub type of visa (only for e-Visa)
5. **Issuing Date** - Date visa was issued
6. **Expiry Date** - Date visa expires
7. **Place of Issue (City)** - City where visa was issued

## Visa Types

When selected, the following visa types show all fields:
- ✅ **MRZ Enable Visa** - All fields shown
- ✅ **e-Visa** - All fields shown + Visa Sub Type dropdown
- ✅ **OCI** - All fields shown
- ✅ **Diplomat** - All fields shown
- ❌ **No Visa** - No fields shown

## User Flow

### Before
```
Select visa type
    ↓
Capture/upload image
    ↓
Visa fields appear
    ↓
Fill in visa details
```

### After
```
Select visa type
    ↓
Visa fields appear immediately
    ↓
Fill in visa details (optional before image capture)
    ↓
Capture/upload image
    ↓
Auto-extract visa details (for e-Visa/Diplomat)
    ↓
Review/edit extracted data
```

## Benefits

1. **Better UX**: Users can see all available fields immediately
2. **Flexibility**: Users can fill in details before or after image capture
3. **Auto-fill**: For e-Visa/Diplomat, fields are auto-populated from OCR
4. **Manual Entry**: Users can manually enter visa details if needed
5. **Consistency**: All visa types show the same fields

## Testing Checklist

- [x] File compiles without errors
- [x] No diagnostics found
- [x] Visa fields show for all visa types except "No Visa"
- [x] Visa fields hide when "No Visa" is selected
- [x] Visa fields hide when no visa type is selected
- [x] Auto-extraction still works for e-Visa/Diplomat
- [x] Manual entry still works for all visa types

## Commit
**Commit Hash**: 8ee93eb
**Message**: fix: show all visa fields when any visa option is selected

## Notes
- Visa fields are now always visible when a visa type is selected
- This allows users to fill in visa details at any time
- Auto-extraction for e-Visa/Diplomat still works as expected
- Users can manually edit auto-extracted data
- "No Visa" option still hides all visa fields
