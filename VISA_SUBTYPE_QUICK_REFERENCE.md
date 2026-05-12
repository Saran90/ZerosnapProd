# Visa Sub Type - Quick Reference

## What Was Done
Added a Visa Sub Type dropdown that appears when users select "e-Visa" as their visa type. The dropdown is populated from the GetVisaSubTypeList API.

## Key Changes

### State Variables
```dart
List<VisaSubType> _visaSubTypes = [];
VisaSubType? _selectedVisaSubType;
```

### New Method
```dart
_loadVisaSubTypes(String visaTypeId)  // Fetches sub types for a visa type
```

### UI
- Visa Sub Type dropdown appears only when "e-Visa" is selected
- Displays short names (e.g., "e-TV", "e-Med V")
- Uses searchable dropdown for easy selection

### API Submission
```dart
'guest_VisaSubType': _selectedVisaSubType?.visaSubTypeId ?? '',
```

## How It Works

1. **e-Visa Selected**: User selects "e-Visa" from visa type dropdown
2. **Sub Types Loaded**: `_loadVisaSubTypes('EV')` is called
3. **API Call**: GetVisaSubTypeList API is called with visa type ID "EV"
4. **Dropdown Populated**: Visa Sub Type dropdown appears with options
5. **User Selects**: User selects a sub type (e.g., e-Tourist Visa)
6. **API Submission**: Sub type ID is sent to API

## Available Visa Sub Types (for e-Visa)
- e-Tourist Visa (e-TV)
- e-Medical Visa (e-Med V)
- e-Medical Attendant Visa (e-Med X V)
- e-Business Visa (e-BV)
- e-Conference Visa (e-CV)
- e-Ayush Visa (e-AY V)
- e-Ayush Attendant Visa (e-AY X V)

## Files Modified
- `lib/core/config/api_constants.dart` - Added endpoint
- `lib/features/scan/domain/entities/lookup_models.dart` - Added model
- `lib/features/scan/data/repositories/passport_repository.dart` - Added method
- `lib/features/scan/presentation/pages/passport_card_scan_page.dart` - Added UI and logic

## Testing
All files compile without errors. No diagnostics found.

## Commit
Hash: 75ba88f
Message: feat: add visa sub type dropdown for e-Visa
