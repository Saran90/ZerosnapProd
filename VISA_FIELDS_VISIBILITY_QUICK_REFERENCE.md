# Visa Fields Visibility - Quick Reference

## What Changed
Visa fields now show immediately when any visa option (except "No Visa") is selected, instead of waiting for image capture.

## Updated Logic
```dart
// Show visa fields if visa type is selected and not "No Visa"
bool get _showVisaFields => _visaType.isNotEmpty && _visaType != 'No Visa';
```

## Visa Fields Shown
When a visa type is selected:
1. Document Number
2. Issuing Country (dropdown)
3. Visa Type (dropdown)
4. Visa Sub Type (dropdown - only for e-Visa)
5. Issuing Date
6. Expiry Date
7. Place of Issue (City)

## Visa Types
- ✅ MRZ Enable Visa → Show all fields
- ✅ e-Visa → Show all fields + Sub Type
- ✅ OCI → Show all fields
- ✅ Diplomat → Show all fields
- ❌ No Visa → Hide all fields

## User Flow
```
Select visa type
    ↓
Visa fields appear immediately
    ↓
Fill in details (optional)
    ↓
Capture image (for e-Visa/Diplomat)
    ↓
Auto-extract details (if available)
    ↓
Review/edit data
```

## Benefits
- Users see all available fields immediately
- Can fill in details before or after image capture
- Auto-extraction still works for e-Visa/Diplomat
- Manual entry always available

## Files Modified
- `lib/features/scan/presentation/pages/passport_card_scan_page.dart`

## Testing
All files compile without errors. No diagnostics found.

## Commit
Hash: 8ee93eb
Message: fix: show all visa fields when any visa option is selected
