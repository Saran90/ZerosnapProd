# Visa Sub Type Integration for e-Visa - COMPLETE

## Summary
Successfully integrated the Visa Sub Type dropdown for e-Visa selection. When users select "e-Visa" as the visa type, they can now select a specific visa sub type (e.g., e-Tourist Visa, e-Medical Visa, etc.) from a dropdown populated from the API.

## Changes Made

### 1. API Endpoint Added
**File**: `lib/core/config/api_constants.dart`

```dart
static const String visaSubTypes = '/api/GetVisaSubTypeList';
```

### 2. Model Created
**File**: `lib/features/scan/domain/entities/lookup_models.dart`

```dart
class VisaSubType {
  final String visaSubTypeId;
  final String visaSubType;
  final String visaTypeId;
  final String visaSubTypeShort;

  const VisaSubType({
    required this.visaSubTypeId,
    required this.visaSubType,
    required this.visaTypeId,
    required this.visaSubTypeShort,
  });

  factory VisaSubType.fromJson(Map<String, dynamic> json) => VisaSubType(
    visaSubTypeId: json['VisaSubTypeId'] ?? '',
    visaSubType: json['VisaSubType'] ?? '',
    visaTypeId: json['VisaTypeId'] ?? '',
    visaSubTypeShort: json['VisaSubTypeShort'] ?? '',
  );
}
```

### 3. Repository Method Added
**File**: `lib/features/scan/data/repositories/passport_repository.dart`

```dart
/// GET /api/GetVisaSubTypeList?id={visaTypeId}
Future<List<VisaSubType>> getVisaSubTypes(String visaTypeId) async {
  final url = await _prefs.getBaseUrl();
  final response = await _api.get(
    '${ApiConstants.visaSubTypes}?id=$visaTypeId',
    baseUrl: url,
    headers: await _authHeaders,
  );
  final list = response is List
      ? response
      : (response['Data'] ?? response['data'] ?? []);
  return (list as List)
      .map((e) => VisaSubType.fromJson(e as Map<String, dynamic>))
      .toList();
}
```

### 4. State Variables Added
**File**: `lib/features/scan/presentation/pages/passport_card_scan_page.dart`

```dart
List<VisaSubType> _visaSubTypes = [];
VisaSubType? _selectedVisaSubType;
```

### 5. New Method: _loadVisaSubTypes()
Fetches visa sub types from API when e-Visa is selected:

```dart
Future<void> _loadVisaSubTypes(String visaTypeId) async {
  if (visaTypeId.isEmpty) return;
  try {
    final subTypes = await _repo.getVisaSubTypes(visaTypeId);
    if (!mounted) return;
    setState(() {
      _visaSubTypes = subTypes;
      _selectedVisaSubType = null;
    });
  } catch (_) {}
}
```

### 6. Updated _onVisaTypeChanged()
Now loads visa sub types when e-Visa is selected:

```dart
if (type == 'e-Visa') {
  _selectedDropVisaType = _visaDropTypes
      .where((v) => v.visaId == 'EV')
      .firstOrNull;
  // Load visa sub types for e-Visa
  _loadVisaSubTypes('EV');
}
```

### 7. UI Updated
Added Visa Sub Type dropdown in the visa detail fields section:

```dart
// Visa Sub Type dropdown for e-Visa
if (_visaType == 'e-Visa' && _visaSubTypes.isNotEmpty)
  _SearchableDropdown<VisaSubType>(
    label: 'Visa Sub Type',
    items: _visaSubTypes,
    selected: _selectedVisaSubType,
    itemLabel: (v) => v.visaSubTypeShort,
    onChanged: (v) => setState(() => _selectedVisaSubType = v),
  ),
```

### 8. API Submission Updated
Now includes the visa sub type ID:

```dart
'guest_VisaSubType': _selectedVisaSubType?.visaSubTypeId ?? '',
```

## User Flow

1. User selects "e-Visa" from the visa type dropdown
2. Visa Sub Type API is called with visa type ID "EV"
3. Visa Sub Type dropdown appears with options like:
   - e-Tourist Visa (e-TV)
   - e-Medical Visa (e-Med V)
   - e-Business Visa (e-BV)
   - e-Conference Visa (e-CV)
   - e-Ayush Visa (e-AY V)
   - etc.
4. User selects a sub type
5. On submit, the visa sub type ID is sent to the API

## API Integration Details

### Endpoint
- **GetVisaSubTypeList** - Takes `visaTypeId` as parameter
  - For e-Visa: `?id=EV`
  - Returns list of visa sub types with IDs and short names

### Data Model
- **VisaSubType**: `visaSubTypeId`, `visaSubType`, `visaTypeId`, `visaSubTypeShort`

### Repository Method
- `getVisaSubTypes(String visaTypeId)` - Fetches sub types for a visa type

## Testing Checklist

- [x] File compiles without errors
- [x] VisaSubType model created
- [x] API endpoint added
- [x] Repository method implemented
- [x] State variables added
- [x] _loadVisaSubTypes() method implemented
- [x] _onVisaTypeChanged() updated
- [x] UI dropdown added (only for e-Visa)
- [x] API submission updated
- [x] Visa sub type dropdown uses short name for display
- [x] Dropdown only shows when e-Visa is selected

## Commit
**Commit Hash**: 75ba88f
**Message**: feat: add visa sub type dropdown for e-Visa

## Notes
- Visa Sub Type dropdown only appears when "e-Visa" is selected
- The dropdown displays the short name (e.g., "e-TV", "e-Med V") for better readability
- Sub types are loaded dynamically from the API
- The full visa sub type description is available in the model but not displayed in the dropdown
- Visa sub type ID is sent to the API in the `guest_VisaSubType` field
