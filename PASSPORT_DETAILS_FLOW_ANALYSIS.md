# Passport Details Screen - OCR vs MRZ Flow Analysis

## Executive Summary
The OCR flow (PassportCardScanPage) and MRZ flow (PassportFormPage) have significant differences in available fields. The OCR flow has MORE fields than the MRZ flow, particularly in:
- Travel details (hotel check-in time, arrival time)
- Next Destination (state, district, country, city, place)
- Visa Sub Type
- Passport back image support

The MRZ flow has fields NOT in OCR:
- Purpose of Visit
- Room Number

## Detailed Field Comparison

### 1. PASSPORT CORE FIELDS (Present in Both)
✅ Surname
✅ Given Names
✅ Document Number
✅ Issuing Country
✅ Nationality
✅ Date of Birth
✅ Sex (M/F/O)
✅ Issuing Date
✅ Expiry Date
✅ Place of Issue
✅ Address
✅ Email
✅ Phone

### 2. TRAVEL FIELDS - DIFFERENCES

#### Present in BOTH:
- Date of Arrival in India
- Arrived From Country
- Arrived From City
- Arrived From Place
- Duration of Stay
- Checkout Date

#### ONLY in OCR Flow:
- **Arrival Time (India)** - Time of arrival in India
- **Hotel Check-in Date** - Separate from arrival date
- **Hotel Check-in Time** - Separate from arrival time
- **Next Destination Type** - Dropdown: Inside India / Outside India
- **Next Destination State** - For Inside India
- **Next Destination District** - For Inside India
- **Next Destination Place (India)** - For Inside India
- **Next Destination Country** - For Outside India
- **Next Destination City** - For Outside India
- **Next Destination Place (Outside)** - For Outside India

#### ONLY in MRZ Flow:
- **Purpose of Visit** - Searchable dropdown
- **Room Number** - Guest room number

#### Type Differences:
- **Arrived From Country**: MRZ uses Dropdown (MrzCountry); OCR uses TextEditingController
- **Checkout Date**: MRZ sends ISO8601 string; OCR sends formatted string

### 3. IMAGE FIELDS - DIFFERENCES

#### MRZ Flow:
- Portrait (optional, manual upload)
- Passport File (from MRZ scan)
- Signature

#### OCR Flow:
- Front Image (required)
- Back Image (optional)
- Profile Image (optional, with auto-crop)
- Signature
- MRZ Portrait Fallback (if no profile image)

### 4. VISA FIELDS - DIFFERENCES

#### Present in BOTH:
- Visa Type
- Visa Document Number
- Visa Issuing Country
- Visa POI City
- Visa Issuing Date
- Visa Expiry Date

#### ONLY in OCR Flow:
- **Visa Sub Type** - Dropdown for e-Visa sub types

#### Visa Type Options (Both):
- MRZ Enable Visa
- e-Visa
- OCI
- Diplomat
- No Visa

#### Visa Image Handling:
- OCI: 3 images (Front, Back, Stamp)
- e-Visa/Diplomat: 1 image
- MRZ Enable Visa: Scanned visa document

#### OCR-Specific:
- Auto-extracts visa details from e-Visa/Diplomat images

### 5. API SUBMISSION FIELD MAPPING

#### Inconsistencies Found:

| Field | MRZ API Name | OCR API Name | Issue |
|-------|-------------|-------------|-------|
| Signature | `GuestSignatureFile` | `User_Signature` | Different field names |
| Checkout | `Guest_HotelCheckOutDate` | `Guest_HotelCheckOut` + `Guest_HotelCheckOutDate` | OCR sends both |
| Passport Back | Not sent | `passportBackFile` | Only OCR supports |
| Arrival Time | Not sent | `Arrival_Time` | Only OCR has |
| Hotel Arrival | Not sent | `Arrival_Date` + `Arrival_Time_Hotel` | Only OCR has |
| Next Destination | Not sent | Multiple fields | Only OCR has |
| Visa Sub Type | Not sent | `guest_VisaSubType` | Only OCR has |

## Recommendations

### Option 1: Add OCR Fields to MRZ Flow (Recommended)
Add the following fields to PassportFormPage:
1. ✅ Arrival Time (India)
2. ✅ Hotel Check-in Date
3. ✅ Hotel Check-in Time
4. ✅ Next Destination Type (dropdown)
5. ✅ Next Destination State (conditional)
6. ✅ Next Destination District (conditional)
7. ✅ Next Destination Place (conditional)
8. ✅ Next Destination Country (conditional)
9. ✅ Next Destination City (conditional)
10. ✅ Next Destination Place Outside (conditional)
11. ✅ Visa Sub Type (for e-Visa)
12. ✅ Passport Back Image (optional)

### Option 2: Add MRZ Fields to OCR Flow
Add the following fields to PassportCardScanPage:
1. ✅ Purpose of Visit (searchable dropdown)
2. ✅ Room Number

### Option 3: Hybrid Approach (Best)
- Add OCR fields to MRZ flow (more important for data collection)
- Add MRZ fields to OCR flow (for completeness)
- Standardize API field names
- Standardize field types (e.g., Arrived From Country should be dropdown in both)

## Implementation Priority

### High Priority (Add to MRZ Flow):
1. Next Destination section (complete with state/district/country/city/place)
2. Hotel Check-in Date and Time (separate from arrival)
3. Arrival Time (India)
4. Visa Sub Type dropdown

### Medium Priority (Add to MRZ Flow):
1. Passport Back Image support
2. Standardize Arrived From Country to dropdown

### Low Priority (Add to OCR Flow):
1. Purpose of Visit dropdown
2. Room Number field

## Field Standardization Needed

### 1. Arrived From Country
- **Current**: MRZ uses MrzCountry dropdown; OCR uses TextEditingController
- **Recommendation**: Both should use MrzCountry dropdown for consistency

### 2. Signature Field Name
- **Current**: MRZ sends `GuestSignatureFile`; OCR sends `User_Signature`
- **Recommendation**: Standardize to one field name (suggest `GuestSignatureFile`)

### 3. Checkout Date Format
- **Current**: MRZ sends ISO8601 string; OCR sends formatted string
- **Recommendation**: Both should send ISO8601 string for consistency

### 4. Hotel Arrival Fields
- **Current**: OCR sends `Arrival_Date` and `Arrival_Time_Hotel`
- **Recommendation**: MRZ should also send these fields

## Next Steps

1. **Analyze API Requirements**: Confirm which fields are actually required by the backend
2. **Implement MRZ Enhancements**: Add missing OCR fields to MRZ flow
3. **Implement OCR Enhancements**: Add missing MRZ fields to OCR flow
4. **Standardize Field Types**: Ensure consistent field types across flows
5. **Standardize API Field Names**: Ensure consistent API field names
6. **Test Both Flows**: Verify data submission works correctly for both flows
7. **Update Documentation**: Document all available fields and their purposes

## Files to Modify

### For Adding OCR Fields to MRZ Flow:
- `lib/features/scan/presentation/pages/passport_form_page.dart`
- `lib/features/scan/data/repositories/passport_repository.dart` (if new API calls needed)

### For Adding MRZ Fields to OCR Flow:
- `lib/features/scan/presentation/pages/passport_card_scan_page.dart`

### For Standardization:
- Both files above
- `lib/core/config/api_constants.dart` (if new endpoints needed)
- `lib/features/scan/domain/entities/lookup_models.dart` (if new models needed)

## Conclusion

The OCR flow is more comprehensive with additional travel and destination fields. To ensure consistency and completeness, the MRZ flow should be enhanced with the missing OCR fields, particularly the Next Destination section which is important for guest tracking and compliance.
