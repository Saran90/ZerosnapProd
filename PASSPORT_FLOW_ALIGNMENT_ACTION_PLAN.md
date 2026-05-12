# Passport Flow Alignment - Action Plan

## Overview
This document outlines the steps to align the MRZ flow (PassportFormPage) with the OCR flow (PassportCardScanPage) by adding missing fields and standardizing field types.

## Phase 1: Analysis & Planning (Current)

### Completed:
- ✅ Identified all field differences
- ✅ Identified API field name inconsistencies
- ✅ Identified field type inconsistencies
- ✅ Prioritized changes

### Key Findings:
1. **OCR Flow has 11 additional travel/destination fields** that MRZ flow lacks
2. **MRZ Flow has 2 fields** (Purpose of Visit, Room Number) that OCR flow lacks
3. **API field names are inconsistent** (e.g., Signature: `GuestSignatureFile` vs `User_Signature`)
4. **Field types differ** (e.g., Arrived From Country: dropdown vs text)

## Phase 2: Implementation Plan

### Step 1: Add Missing Fields to MRZ Flow (PassportFormPage)

#### 1.1 Add State Variables
```dart
// ── Next Destination fields ───────────────────────────────────────────────
String _nextDestinationType = 'Inside India';
IndianState? _nextDestState;
IndianDistrict? _nextDestDistrict;
final _nextDestPlaceIndiaCtrl = TextEditingController();
MrzCountry? _nextDestCountry;
final _nextDestCityCtrl = TextEditingController();
final _nextDestPlaceOutsideCtrl = TextEditingController();
Map<String, List<IndianDistrict>> _districtsByState = {};

// ── Additional Travel fields ───────────────────────────────────────────────
final _arrivalTimeCtrl = TextEditingController();
final _hotelArrivalDateCtrl = TextEditingController();
final _hotelArrivalTimeCtrl = TextEditingController();
DateTime? _hotelArrivalDate;

// ── Visa Sub Type ─────────────────────────────────────────────────────────
List<VisaSubType> _visaSubTypes = [];
VisaSubType? _selectedVisaSubType;
```

#### 1.2 Add Methods
```dart
Future<void> _loadDistrictsForState(String stateId) async { ... }
Future<void> _loadVisaSubTypes(String visaTypeId) async { ... }
void _updateCheckoutDate() { ... }
```

#### 1.3 Add UI Components
- Next Destination section with state/district/country/city/place fields
- Arrival Time field
- Hotel Check-in Date and Time fields
- Visa Sub Type dropdown (for e-Visa)

#### 1.4 Update API Submission
Add to submission body:
```dart
'Arrival_Time': _arrivalTimeCtrl.text,
'Arrival_Date': _hotelArrivalDateCtrl.text,
'Arrival_Time_Hotel': _hotelArrivalTimeCtrl.text,
'NextDestinationType': _nextDestinationType,
'NextDestinationState': _nextDestState?.stateId ?? '',
'NextDestinationDistrict': _nextDestDistrict?.districtId ?? '',
'NextDestinationPlaceIndia': _nextDestPlaceIndiaCtrl.text,
'NextDestinationCountry': _nextDestCountry?.code ?? '',
'NextDestinationCity': _nextDestCityCtrl.text,
'NextDestinationPlaceOutside': _nextDestPlaceOutsideCtrl.text,
'guest_VisaSubType': _selectedVisaSubType?.visaSubTypeId ?? '',
```

### Step 2: Add Missing Fields to OCR Flow (PassportCardScanPage)

#### 2.1 Add State Variables
```dart
// ── Purpose of Visit ──────────────────────────────────────────────────────
List<Purpose> _purposes = [];
Purpose? _selectedPurpose;

// ── Room Number ───────────────────────────────────────────────────────────
final _roomNoCtrl = TextEditingController();
```

#### 2.2 Add Methods
```dart
Future<void> _loadPurposes() async { ... }
```

#### 2.3 Add UI Components
- Purpose of Visit searchable dropdown
- Room Number text field

#### 2.4 Update API Submission
Add to submission body:
```dart
'guest_PurposeofVisit': _selectedPurpose?.purposeId ?? '',
'GuestRoomNo': _roomNoCtrl.text,
```

### Step 3: Standardize Field Types

#### 3.1 Arrived From Country
- **Current**: MRZ uses MrzCountry dropdown; OCR uses TextEditingController
- **Action**: Update OCR flow to use MrzCountry dropdown
- **File**: `lib/features/scan/presentation/pages/passport_card_scan_page.dart`
- **Change**: Replace `_arrivedFromCountryCtrl` with `MrzCountry? _arrivedFromCountry`

#### 3.2 Signature Field Name
- **Current**: MRZ sends `GuestSignatureFile`; OCR sends `User_Signature`
- **Action**: Standardize both to use `GuestSignatureFile`
- **Files**: Both passport pages
- **Change**: Update API submission in OCR flow

#### 3.3 Checkout Date Format
- **Current**: MRZ sends ISO8601 string; OCR sends formatted string
- **Action**: Standardize both to send ISO8601 string
- **Files**: Both passport pages
- **Change**: Update API submission in both flows

### Step 4: Add Passport Back Image Support to MRZ Flow

#### 4.1 Add State Variable
```dart
String? _backImagePath;
```

#### 4.2 Add UI Component
- Back image tile (optional)

#### 4.3 Update API Submission
```dart
'passportBackFile': _backImagePath != null 
    ? base64Encode(await File(_backImagePath!).readAsBytes())
    : '',
```

## Phase 3: Testing & Validation

### Test Cases:

#### MRZ Flow Tests:
1. ✅ All new fields render correctly
2. ✅ Next Destination state/district dropdowns work
3. ✅ Hotel check-in date/time fields work
4. ✅ Arrival time field works
5. ✅ Visa Sub Type dropdown works (for e-Visa)
6. ✅ Purpose of Visit dropdown works
7. ✅ Room Number field works
8. ✅ Passport back image upload works
9. ✅ API submission includes all new fields
10. ✅ Checkout date auto-calculation works

#### OCR Flow Tests:
1. ✅ Purpose of Visit dropdown works
2. ✅ Room Number field works
3. ✅ Arrived From Country dropdown works
4. ✅ API submission uses correct field names
5. ✅ Signature field name is consistent

#### Cross-Flow Tests:
1. ✅ Both flows submit same passport core fields
2. ✅ Both flows submit same visa fields
3. ✅ Both flows use same API field names
4. ✅ Both flows use same field types

## Phase 4: Deployment

### Pre-Deployment Checklist:
- ✅ All files compile without errors
- ✅ No diagnostics found
- ✅ All tests pass
- ✅ Code review completed
- ✅ Documentation updated

### Deployment Steps:
1. Create feature branch: `feature/passport-flow-alignment`
2. Implement all changes
3. Run tests
4. Create pull request
5. Code review
6. Merge to master
7. Deploy to staging
8. User acceptance testing
9. Deploy to production

## Estimated Effort

### MRZ Flow Enhancements:
- Add state variables: 1 hour
- Add methods: 2 hours
- Add UI components: 3 hours
- Update API submission: 1 hour
- Testing: 2 hours
- **Total: 9 hours**

### OCR Flow Enhancements:
- Add state variables: 30 minutes
- Add methods: 1 hour
- Add UI components: 1 hour
- Update API submission: 30 minutes
- Testing: 1 hour
- **Total: 4 hours**

### Standardization:
- Arrived From Country: 1 hour
- Signature field name: 30 minutes
- Checkout date format: 30 minutes
- Testing: 1 hour
- **Total: 3 hours**

### Grand Total: ~16 hours

## Risk Assessment

### Low Risk:
- Adding new fields to MRZ flow (isolated changes)
- Adding new fields to OCR flow (isolated changes)

### Medium Risk:
- Standardizing field types (affects existing functionality)
- Standardizing API field names (affects API submission)

### Mitigation:
- Comprehensive testing before deployment
- Gradual rollout (staging first)
- Rollback plan if issues arise

## Success Criteria

1. ✅ All fields from OCR flow available in MRZ flow
2. ✅ All fields from MRZ flow available in OCR flow
3. ✅ Field types consistent across flows
4. ✅ API field names consistent across flows
5. ✅ Both flows compile without errors
6. ✅ All tests pass
7. ✅ No regressions in existing functionality

## Next Steps

1. **Review this plan** with the team
2. **Get approval** to proceed
3. **Create feature branch**
4. **Implement Phase 2 changes**
5. **Execute Phase 3 testing**
6. **Deploy Phase 4**

## Questions to Answer Before Implementation

1. Are all the new fields actually required by the backend API?
2. Should Purpose of Visit be mandatory or optional?
3. Should Room Number be mandatory or optional?
4. Should Passport Back Image be mandatory or optional?
5. What is the correct API field name for Signature?
6. Should Arrived From Country be a dropdown in both flows?
7. Are there any other fields missing from either flow?
