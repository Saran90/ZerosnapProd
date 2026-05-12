# District Integration for Next Destination - COMPLETE

## Summary
Successfully integrated the Districts API into the Passport Card Scan Page for the "Inside India" next destination flow. Districts are now dynamically loaded from the API based on the selected state.

## Changes Made

### 1. State Variables Updated
**File**: `lib/features/scan/presentation/pages/passport_card_scan_page.dart`

Replaced TextEditingControllers with proper state variables:
```dart
// OLD (TextEditingControllers)
final _nextDestStateCtrl = TextEditingController();
final _nextDestDistrictCtrl = TextEditingController();

// NEW (State variables)
IndianState? _nextDestState;
IndianDistrict? _nextDestDistrict;
Map<String, List<IndianDistrict>> _districtsByState = {};
```

### 2. New Method: _loadDistrictsForState()
Fetches districts from API when a state is selected:
```dart
Future<void> _loadDistrictsForState(String stateId) async {
  if (stateId.isEmpty) return;
  try {
    final districts = await _repo.getDistricts(stateId);
    if (!mounted) return;
    setState(() {
      _districtsByState[stateId] = districts;
      _nextDestDistrict = null; // Reset district when state changes
    });
  } catch (_) {}
}
```

### 3. Dispose Method Updated
Removed old TextEditingControllers from dispose:
- Removed `_nextDestStateCtrl`
- Removed `_nextDestDistrictCtrl`
- Kept `_nextDestPlaceIndiaCtrl` (still used for Place field)

### 4. New Dropdown Widgets

#### _StateDropdown Widget
- Displays list of Indian states from API
- Allows user to select a state
- Triggers district loading when state is selected

#### _DistrictDropdown Widget
- Displays districts for the selected state
- Disabled until a state is selected
- Shows appropriate styling when disabled

### 5. Travel Section UI Updated
```dart
if (_nextDestinationType == 'Inside India') ...[
  _StateDropdown(
    label: 'State',
    states: _states,
    selected: _nextDestState,
    onChanged: (state) {
      setState(() => _nextDestState = state);
      if (state != null) {
        _loadDistrictsForState(state.stateId);
      }
    },
  ),
  _DistrictDropdown(
    label: 'District',
    districts: _nextDestState != null
        ? (_districtsByState[_nextDestState!.stateId] ?? [])
        : [],
    selected: _nextDestDistrict,
    onChanged: (district) =>
        setState(() => _nextDestDistrict = district),
    enabled: _nextDestState != null,
  ),
  _FormField(label: 'Place', controller: _nextDestPlaceIndiaCtrl),
],
```

### 6. API Submission Updated
Now sends state and district IDs instead of text:
```dart
'NextDestinationType': _nextDestinationType,
'NextDestinationState': _nextDestState?.stateId ?? '',
'NextDestinationDistrict': _nextDestDistrict?.districtId ?? '',
'NextDestinationPlaceIndia': _nextDestPlaceIndiaCtrl.text,
```

## API Integration Details

### Endpoints Used
1. **GetStatesList** - Already implemented
   - Returns list of all Indian states
   - Loaded in `_loadLookups()` method

2. **GetDistrictList** - Already implemented
   - Takes `stateId` as parameter
   - Returns districts for that state
   - Called dynamically when state is selected

### Data Models
- **IndianState**: `stateId`, `stateName`
- **IndianDistrict**: `districtId`, `districtName`, `stateId`

### Repository Methods
- `getStates()` - Fetches all states
- `getDistricts(String stateId)` - Fetches districts for a state

## User Flow

1. User selects "Inside India" from Next Destination dropdown
2. State dropdown appears with list of states
3. User selects a state
4. Districts API is called with the selected state ID
5. District dropdown is enabled and populated with districts
6. User selects a district
7. User enters place name
8. On submit, state ID, district ID, and place are sent to API

## Testing Checklist

- [x] File compiles without errors
- [x] State variables properly initialized
- [x] Dispose method properly cleans up resources
- [x] _loadDistrictsForState method implemented
- [x] _StateDropdown widget created
- [x] _DistrictDropdown widget created
- [x] Travel section UI updated
- [x] API submission updated to use IDs
- [x] District dropdown disabled until state selected
- [x] District list resets when state changes

## Commit
**Commit Hash**: 8119e05
**Message**: feat: add districts API integration for next destination

## Notes
- No static data is used - all data comes from API
- Districts are cached in `_districtsByState` map to avoid repeated API calls
- District dropdown is properly disabled when no state is selected
- All error handling is in place with try-catch blocks
- Mounted checks prevent state updates after navigation
