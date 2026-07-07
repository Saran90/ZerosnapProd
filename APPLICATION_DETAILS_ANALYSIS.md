# Application Details Analysis - Zerosnap Smart Check-In

## Investigation Results from Codebase

### 1. Application Framework & Version ✅
**Screenshot Value**: Flutter  
**Codebase Verification**:
- **Framework**: Flutter
- **Flutter SDK Version**: 3.41.4 (stable channel)
- **Dart SDK Version**: 3.11.1
- **Build Tools**: DevTools 2.54.1
- **App Version**: 1.0.6+7 (from pubspec.yaml)

**Source**: `pubspec.yaml`, `flutter --version` command

---

### 2. Number of Screens/Views ✅
**Screenshot Value**: Approximately 5-7  
**Codebase Verification**: **19 Page Files**

**Main Screens/Pages** (Unique user-facing screens):
1. **Splash Page** (`splash_page.dart`)
2. **Login Page** (`login_page.dart`)
3. **Dashboard Page** (`dashboard_page.dart`)
4. **Settings Page** (`settings_page.dart`)
5. **FRRO Credentials Page** (`frro_credentials_page.dart`)
6. **FRRO List Page** (`frro_list_page.dart`) - Guest list for FRRO submission
7. **FRRO Form Page** (`frro_form_page.dart`) - Web view for FRRO form
8. **Guest List Page** (`guest_list_page.dart`)
9. **Guest Detail Page** (`guest_detail_page.dart`)
10. **Add Guest Page** (`add_guest_page.dart`)
11. **Card Scan Page** (`card_scan_page.dart`) - Domestic cards (Aadhaar, PAN, DL, Voter ID)
12. **MRZ Scanner Page** (`mrz_scanner_page.dart`)
13. **Passport Card Scan Page** (`passport_card_scan_page.dart`) - Main implementation
14. **Passport Form Page** (`passport_form_page.dart`) - Main implementation
15. **Profile Crop Page** (`profile_crop_page.dart`)

**Wrapper Pages** (configuration wrappers, not unique screens):
- `passport_card_scan_page_domestic.dart` (wrapper)
- `passport_card_scan_page_landing.dart` (wrapper)
- `passport_form_page_domestic.dart` (wrapper)
- `passport_form_page_landing.dart` (wrapper)

**Actual Unique User-Facing Screens**: **15**

**Analysis**: The screenshot estimate of 5-7 is lower than actual count (15 screens). Likely counting only main workflow screens without settings/admin screens.

**Source**: File listing in `lib/features/*/presentation/pages/`

---

### 3. Total Number of Mobile-Specific Input Forms ✅
**Screenshot Value**: Approximately 2-5  
**Codebase Verification**: **5 Main Forms**

**Primary Input Forms**:
1. **Login Form** (`login_page.dart`)
   - URL, Username, Password fields

2. **Passport & Visa Form** (`passport_form_page.dart` / `passport_card_scan_page.dart`)
   - Passport details, Travel info, Visa details
   - Largest form with 25+ fields

3. **Domestic Card Form** (`card_scan_page.dart`)
   - For Aadhaar, PAN, Driving License, Voter ID, Other ID
   - Personal details, document info, stay details

4. **FRRO Credentials Form** (`frro_credentials_page.dart`)
   - Username and Password for FRRO portal

5. **Guest Search/Filter Form** (`guest_list_page.dart`)
   - Search and filter controls

**Verification**: **5 forms** matches the screenshot range of 2-5 ✅

**Source**: Analysis of `TextEditingController` instances and form structures

---

### 4. Total Number of Input Fields ✅
**Screenshot Value**: Approximately 25  
**Codebase Verification**: **50+ Total Fields** across all forms

**Field Count by Form**:

#### Passport Form (`passport_form_page.dart`): **28 fields**
- Passport: surname, givenNames, docNo, dob, issuingDate, expiryDate, placeOfIssue, address, email, phone, roomNo (11)
- Travel: arrivalInIndia, arrivalTime, hotelArrivalDate, hotelArrivalTime, arrivedFromCountry, arrivedFromCity, arrivedFromPlace, durationOfStay, checkoutDate (9)
- Next Destination: nextDestPlaceIndia, nextDestCity, nextDestPlaceOutside (3)
- Visa: visaDocNo, visaIssuingDate, visaExpiryDate, visaPOICity (4)
- Search controller: 1

#### Passport Card Scan (`passport_card_scan_page.dart`): **31 fields**
- Similar to passport form + additional fields

#### Domestic Card Form (`card_scan_page.dart`): **16 fields**
- docNo, firstName, lastName, dob, address, issueDate, expiryDate, email, phone
- duration, checkout, roomNo, vehicleNo, department, contactPerson
- Plus 2 search controllers in guest list

#### Login Form: **3 fields**
- url, username, password

#### FRRO Credentials: **2 fields**
- username, password

**Total Unique Input Fields**: **50+** (counting all TextEditingController instances)

**Analysis**: The screenshot value of "Approximately 25" likely refers to the **largest single form** (Passport form with ~25-28 visible fields), not total across all forms.

**Source**: Grep search for `TextEditingController()` declarations

---

### 5. Number of API Endpoints ✅
**Screenshot Value**: Approximately 2-3  
**Codebase Verification**: **31 Unique Endpoints**

**API Endpoints by Category**:

#### Auth (3):
- `/api/UrlValid`
- `/api/MRZauthenticate`
- `/api/CheckApiIsAccessible`

#### Passport/Visa (3):
- `/api/SavePassportAndVisa`
- `/api/SaveIndianPassport`
- `/api/Zerosnap/GetGVPassportFront`

#### Domestic Cards (3):
- `/api/SaveIndianCard`
- `/api/SaveIdCardImage`
- `/api/SaveIdCardsWithExtract`

#### OCR Extract (5):
- `/api/intellilabs/GetIndianDrivingLicenceOCR`
- `/api/intellilabs/GetVoterCardOCR`
- `/api/intellilabs/GetAadharOCR`
- `/api/intellilabs/GetPanOCR`
- `/api/Zerosnap/GetGVVisa`

#### Verify (4):
- `/api/intellilabs/GetDLBasicVerify`
- `/api/intellilabs/GetVoterBasicVerify`
- `/api/intellilabs/GetAadhaarBasicVerify`
- `/api/intellilabs/GetPanVerify`

#### Lookup Lists (7):
- `/api/GetVisaTypeList`
- `/api/GetVisaSubTypeList`
- `/api/GetPurposeOfVisitList`
- `/api/GetVehicleTypeList`
- `/api/GetNationalityList`
- `/api/GetStatesList`
- `/api/GetDistrictList`

#### Check-in/Check-out (4):
- `/api/GetFrroGuestDataMobile`
- `/api/UpdateFRROBeforeCheckInStatusMobile`
- `/api/UpdateFRROCheckInStatusMobile`
- `/api/UpdateFRROCheckOutStatusMobile`

#### Other (2):
- `/api/CheckDupilcateGuest`
- `/api/GetFRROCredentialsMobile`

**Total**: **31 Endpoints**

**Analysis**: Screenshot value "2-3" is significantly lower than actual (31). Possibly counting only primary business logic endpoints (Save/Submit APIs) or major endpoint categories.

**Source**: `lib/core/config/api_constants.dart`

---

### 6. Total Number of Parameters in API ✅
**Screenshot Value**: Approximately 20-30  
**Codebase Verification**: **40-50 Parameters** (largest API)

**SavePassportAndVisa API Parameters**: **48 total** (with all visa fields)

**Base Parameters** (always sent): **37**
- Personal: guest_Firstname, guest_Lastname, guest_Father, guest_DocumentNo, guest_CountryofIssue, guest_Nationality, guest_DOB, guest_Gender, guest_DateOfIssue, guest_ExpiryDate, Guest_POICity, guest_Address, Guest_Email, Guest_PhoneNo, GuestRoomNo, Guest_PurposeofVisit (16)
- Travel: DateOfArrivalInIndia, Arrival_Time, Arrival_Date, Arrival_Time_Hotel, ArrivedFromCountry, ArrivedFromCity, ArrivedFromPlace, IntendedDurationStayIndividualHouse, Guest_HotelCheckOut, Guest_HotelCheckOutDate (10)
- Next Destination: NextDestination, NextDestination_IN_State, NextDestination_IN_District, NextDestination_IN_Place, NextDestination_OUT_Country, NextDestination_OUT_City, NextDestination_OUT_Place (7)
- Images: passportFile, passportBackFile, profileImageFile, User_Signature (4)

**Visa Parameters** (when visa section shown): **8-11 additional**
- Base visa: guest_VisaNo, guest_VisaPOICountry, Guest_VisaPOICity, guest_VisaDateofIssue, guest_VisaValidTill, guest_VisaType, VisaSubTypeId, VisaIDCardType (8)
- Visa images: visaFile (1 for e-Visa/Diplomat or MRZ) OR visaFile + visaFile2 + visaFile3 (3 for OCI)

**SaveIndianCard API**: **14 parameters** (smaller form)

**Analysis**: The screenshot range "20-30" is close to the base parameters (37) but doesn't account for all visa fields. The actual maximum is **48 parameters**.

**Source**: `passport_form_page.dart` body construction around line 776-843

---

### 7. Total Number of User Roles ✅
**Screenshot Value**: Super Admin, Organization Admin, Receptionist/Front Desk, Manager - (4)  
**Codebase Verification**: **Cannot be definitively confirmed from codebase**

**Evidence Found**:
- No explicit role enumeration or role management code found
- Login API (`/api/MRZauthenticate`) likely returns user role
- No role-based UI switching or permission checks visible in code
- Settings sync endpoints exist but don't show role structure

**Likely Explanation**:
- Roles are managed on the **backend/server side**
- The mobile app receives role information in login response
- The app may have limited role-based features (mainly data entry)

**Analysis**: The screenshot value of 4 roles is likely accurate based on business requirements, but **not verifiable** from the mobile app codebase alone. This is a **backend configuration**.

**Recommendation**: Verify roles in backend API documentation or database schema.

---

## Summary Table

| Field | Screenshot Value | Actual Codebase Value | Verification |
|-------|------------------|----------------------|--------------|
| Framework | Flutter | Flutter 3.41.4 + Dart 3.11.1 | ✅ Exact Match |
| Number of Screens | ~5-7 | **15 unique screens** | ⚠️ Higher than estimate |
| Input Forms | ~2-5 | **5 main forms** | ✅ Matches range |
| Input Fields | ~25 | **50+ total** (25-28 in largest form) | ⚠️ Likely per-form count |
| API Endpoints | ~2-3 | **31 endpoints** | ❌ Significantly higher |
| API Parameters | ~20-30 | **48 max** (SavePassportAndVisa) | ⚠️ Slightly higher |
| User Roles | 4 roles | **Not verifiable** (backend) | ⚠️ Cannot confirm |

---

## Recommendations

### For Screenshot Accuracy:
1. **Number of Screens**: Update to "15 unique screens" or "5-7 main workflow screens"
2. **API Endpoints**: Update to "31 API endpoints" or "3 primary categories"
3. **Input Fields**: Clarify as "25 fields in largest form, 50+ total"
4. **User Roles**: Verify with backend documentation

### Code Quality Notes:
- ✅ Well-structured feature-based architecture
- ✅ Proper separation of concerns (data/domain/presentation)
- ✅ Comprehensive API coverage
- ⚠️ Large page files (2000+ lines) - refactoring recommended
- ✅ Secure design practices (HTTPS, authentication, duplicate checking)

---

## Files Analyzed:
- `pubspec.yaml` - Framework and dependencies
- `lib/core/config/api_constants.dart` - API endpoints
- `lib/features/*/presentation/pages/*.dart` - All page files
- `lib/features/scan/presentation/pages/passport_form_page.dart` - API parameter counting
- Flutter version command output

**Analysis Date**: January 7, 2025
**Analyst**: Kiro AI Code Assistant
