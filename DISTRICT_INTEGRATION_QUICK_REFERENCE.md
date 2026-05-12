# District Integration - Quick Reference

## What Was Done
Integrated the Districts API into the Passport Card Scan Page so that when users select "Inside India" as their next destination, they can:
1. Select a state from a dropdown (populated from GetStatesList API)
2. Select a district from a dropdown (populated from GetDistrictList API based on selected state)
3. Enter a place name

## Key Changes

### State Variables
```dart
IndianState? _nextDestState;           // Selected state
IndianDistrict? _nextDestDistrict;     // Selected district
Map<String, List<IndianDistrict>> _districtsByState = {}; // Cache
```

### New Method
```dart
_loadDistrictsForState(String stateId)  // Fetches districts for a state
```

### New Widgets
- `_StateDropdown` - Dropdown for selecting state
- `_DistrictDropdown` - Dropdown for selecting district (disabled until state selected)

### API Submission
```dart
'NextDestinationState': _nextDestState?.stateId ?? '',
'NextDestinationDistrict': _nextDestDistrict?.districtId ?? '',
```

## How It Works

1. **States Loaded**: In `_loadLookups()`, states are fetched from GetStatesList API
2. **State Selected**: User selects a state from dropdown
3. **Districts Loaded**: `_loadDistrictsForState()` is called with state ID
4. **Districts Cached**: Districts are stored in `_districtsByState` map
5. **District Dropdown Enabled**: User can now select a district
6. **API Submission**: State ID and District ID are sent to API

## Files Modified
- `lib/features/scan/presentation/pages/passport_card_scan_page.dart`

## Files Already Had Required Code
- `lib/features/scan/data/repositories/passport_repository.dart` - `getDistricts()` method
- `lib/features/scan/domain/entities/lookup_models.dart` - `IndianState` and `IndianDistrict` models
- `lib/core/config/api_constants.dart` - `/api/GetDistrictList` endpoint

## Testing
All files compile without errors. No diagnostics found.

## Commit
Hash: 8119e05
Message: feat: add districts API integration for next destination
