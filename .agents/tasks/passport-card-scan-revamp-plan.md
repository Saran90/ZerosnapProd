# Implementation Plan — Revamp `passport_card_scan_page.dart`

> Reference implementation: `passport_form_page.dart` (already revamped, 2,466 lines)
> Target file: `passport_card_scan_page.dart` (3,063 lines, currently un-revamped)

---

## 1. Inventory of all existing controllers and state variables in `passport_card_scan_page.dart`

### Images (String paths, not base64)
| Variable | Type | Purpose |
|---|---|---|
| `_frontImagePath` | `String` | Passport bio-data page |
| `_backImagePath` | `String` | Back / last page |
| `_profileImagePath` | `String` | Portrait / profile photo |
| `_mrzPortraitBase64` | `String?` | Portrait from MRZ scan (base64) |
| `_visaImagePath` | `String?` | Visa front |
| `_visaImageBackPath` | `String?` | OCI back page |
| `_visaImageStampPath` | `String?` | OCI stamp page |

### Passport fields
| Variable | Type | Purpose |
|---|---|---|
| `_surnameCtrl` | `TextEditingController` | Surname / last name |
| `_givenNamesCtrl` | `TextEditingController` | Given names / first name |
| `_docNoCtrl` | `TextEditingController` | Passport document number |
| `_dobCtrl` | `TextEditingController` | Date of birth (text) |
| `_issuingDateCtrl` | `TextEditingController` | Passport date of issue |
| `_expiryDateCtrl` | `TextEditingController` | Passport expiry date |
| `_placeOfIssueCtrl` | `TextEditingController` | Place of issue city |
| `_addressCtrl` | `TextEditingController` | Home address |
| `_emailCtrl` | `TextEditingController` | Email |
| `_phoneCtrl` | `TextEditingController` | Phone |
| `_roomNoCtrl` | `TextEditingController` | Room number |
| `_sex` | `String` | 'M' / 'F' / 'O' |
| `_dob` | `DateTime?` | DOB DateTime object |
| `_issuingDate` | `DateTime?` | Issue date DateTime |
| `_expiryDate` | `DateTime?` | Expiry date DateTime |
| `_selectedIssuingCountry` | `MrzCountry?` | Issuing country |
| `_selectedNationality` | `MrzCountry?` | Nationality |
| `_selectedPlaceOfIssueCountry` | `MrzCountry?` | Place of issue country |
| `_selectedPurpose` | `Purpose?` | Purpose of visit |

### Travel fields
| Variable | Type | Purpose |
|---|---|---|
| `_arrivalInIndiaCtrl` | `TextEditingController` | Date of arrival in India |
| `_arrivalTimeCtrl` | `TextEditingController` | Arrival time in India |
| `_hotelArrivalDateCtrl` | `TextEditingController` | Hotel check-in date |
| `_hotelArrivalTimeCtrl` | `TextEditingController` | Hotel check-in time |
| `_arrivedFromCityCtrl` | `TextEditingController` | City arrived from |
| `_arrivedFromPlaceCtrl` | `TextEditingController` | Place arrived from |
| `_durationCtrl` | `TextEditingController` | Duration of stay (days) — note: scan page uses `_durationCtrl`; reference uses `_durationOfStayCtrl` |
| `_checkoutDateCtrl` | `TextEditingController` | Checkout date |
| `_selectedArrivedFromCountry` | `MrzCountry?` | Country arrived from |
| `_arrivalInIndia` | `DateTime?` | Arrival in India DateTime |
| `_hotelArrivalDate` | `DateTime?` | Hotel check-in DateTime |
| `_checkoutDate` | `DateTime?` | Checkout DateTime |

### Next destination fields
| Variable | Type | Purpose |
|---|---|---|
| `_nextDestinationType` | `String` | 'Inside India' or 'Outside India' |
| `_nextDestState` | `IndianState?` | State (inside India) |
| `_nextDestDistrict` | `IndianDistrict?` | District (inside India) |
| `_nextDestPlaceIndiaCtrl` | `TextEditingController` | Place (inside India) |
| `_nextDestCountry` | `MrzCountry?` | Country (outside India) |
| `_nextDestCityCtrl` | `TextEditingController` | City (outside India) |
| `_nextDestPlaceOutsideCtrl` | `TextEditingController` | Place (outside India) |
| `_districtsByState` | `Map<String, List<IndianDistrict>>` | Cached districts per state |

### Visa fields
| Variable | Type | Purpose |
|---|---|---|
| `_visaType` | `String` | 'e-Visa' / 'OCI' / 'Diplomat' / 'No Visa' / '' |
| `_visaDocNoCtrl` | `TextEditingController` | Visa document number |
| `_visaIssuingDateCtrl` | `TextEditingController` | Visa date of issue |
| `_visaExpiryDateCtrl` | `TextEditingController` | Visa expiry date |
| `_visaPOICityCtrl` | `TextEditingController` | Visa place of issue city |
| `_visaIssuingDate` | `DateTime?` | Visa issue DateTime |
| `_visaExpiryDate` | `DateTime?` | Visa expiry DateTime |
| `_selectedVisaCountry` | `MrzCountry?` | Visa issuing country |
| `_selectedDropVisaType` | `VisaType?` | Visa type from lookup |
| `_selectedVisaSubType` | `VisaSubType?` | Visa sub-type |

### Lookup lists
| Variable | Type |
|---|---|
| `_countries` | `List<MrzCountry>` |
| `_visaDropTypes` | `List<VisaType>` |
| `_states` | `List<IndianState>` |
| `_visaSubTypes` | `List<VisaSubType>` |
| `_purposes` | `List<Purpose>` |

### Signature / misc
| Variable | Type | Purpose |
|---|---|---|
| `_signatureBytes` | `Uint8List?` | Captured signature |
| `_termsAndConditionsAccepted` | `bool` | Terms acceptance flag |
| `_isSubmitting` | `bool` | Submit spinner |
| `_isExtractingOcr` | `bool` | OCR spinner |
| `_isExtractingVisa` | `bool` | Visa OCR spinner |
| `_showNextDestination` | `bool?` | Loaded from prefs |
| `_showRoomNo` | `bool?` | Loaded from prefs |

---

## 2. Controller → field label mapping (old label → new label)

| Controller | Old label in scan page | New label to use (matches reference) |
|---|---|---|
| `_surnameCtrl` | 'Surname' | 'Last name' |
| `_givenNamesCtrl` | 'Given Names' | 'First name' |
| `_docNoCtrl` | 'Document Number' | 'Document no' |
| `_dobCtrl` | 'Date of Birth' | 'Date of birth' |
| `_issuingDateCtrl` | 'Issuing Date' | 'Date of issue' |
| `_expiryDateCtrl` | 'Expiry Date' | 'Expiry date' |
| `_placeOfIssueCtrl` | 'Place of Issue (City)' | 'Place of issue city' |
| `_addressCtrl` | 'Address' | 'Address' (keep, move above Document no) |
| `_emailCtrl` | 'Email' | 'Email' (move to Other Details card) |
| `_phoneCtrl` | 'Phone' | 'Phone no' (move to Other Details card) |
| `_roomNoCtrl` | 'Room Number' | 'Room no' (always shown in Other Details, drop prefs gate) |
| `_sex` | label='Sex' | label='Gender' |
| `_selectedIssuingCountry` | 'Issuing Country' | 'Place of issue' (country) |
| `_selectedNationality` | 'Nationality' | 'Nationality' |
| `_selectedPlaceOfIssueCountry` | 'Place of Issue (Country)' | REMOVE as separate field — fold into 'Place of issue' country dropdown (reuse `_selectedIssuingCountry` or keep `_selectedPlaceOfIssueCountry` and keep it synced the same way the reference does) |
| `_arrivalInIndiaCtrl` | 'Date of Arrival in India' | 'Arrival in India' (date part of split row) |
| `_arrivalTimeCtrl` | 'Arrival Time (India)' | 'Time' (time part of split row) |
| `_hotelArrivalDateCtrl` | 'Hotel Check-in Date' | 'Arrival in hotel' (date part) |
| `_hotelArrivalTimeCtrl` | 'Hotel Check-in Time' | 'Time' (time part) |
| `_arrivedFromCityCtrl` | 'Arrived From City' | 'Arrived from city' |
| `_arrivedFromPlaceCtrl` | 'Arrived From Place' | 'Arrived from place' |
| `_durationCtrl` | 'Duration of Stay (days)' | 'Duration of stay days' |
| `_checkoutDateCtrl` | 'Checkout Date' | 'Hotel departure' |
| `_visaDocNoCtrl` | 'Document Number' | 'Visa number' |
| `_visaIssuingDateCtrl` | 'Issuing Date' | 'Date of issue' |
| `_visaExpiryDateCtrl` | 'Expiry Date' | 'Expiry date' |
| `_visaPOICityCtrl` | 'Place of Issue (City)' | 'Place of issue city' |

---

## 3. New controllers and state variables to ADD

These exist in `passport_form_page.dart` but are absent from `passport_card_scan_page.dart`:

```dart
// FRRO / state arrival
final _frroAppIdCtrl = TextEditingController();
final _arrivalDateInStateCtrl = TextEditingController();
DateTime? _arrivalDateInState;

// Other Details
final _companyCtrl = TextEditingController();
final _designationCtrl = TextEditingController();
final _noOfPersonsCtrl = TextEditingController();
final _adultsCtrl = TextEditingController();
final _childrenCtrl = TextEditingController();
String? _selectedEmployedInIndia;
final _durationInIndiaCtrl = TextEditingController();
String? _selectedModeOfPayment;
```

Additionally, the scan page is missing `_idFrontImagePath` (used in `passport_form_page.dart` as the "ID Front Side" image slot). The scan page instead uses `_frontImagePath` for the passport image. The implementation **should not add** `_idFrontImagePath` — instead, the `passportFile` submit key should continue using `_frontImagePath` (already a file path that can be read to base64).

---

## 4. Widget helpers to copy verbatim from `passport_form_page.dart`

The scan page already has its own versions of these widgets but they are **simpler / missing features**. Replace each one with the version from `passport_form_page.dart`:

| Widget class | What changes vs. current scan page version |
|---|---|
| `_buildSectionCard(...)` | Brand-new method — does not exist in scan page; adds left-accent Card with icon header |
| `_FormField` | Add `required`, `maxLines`, `inputFormatters` params; use `RichText` label with red `*` for required; use `BorderRadius.circular(12)` (reference) instead of `circular(10)` (scan page) |
| `_DateField` | Add `required` param; wrap in `Padding` + `GestureDetector` + `AbsorbPointer`; use `circular(12)` |
| `_DropdownField` | Change `value` param from non-nullable `String` to `String?`; add `required` param; use `circular(12)` |
| `_CountryDropdown` | Structurally identical, just change border radius to `circular(12)` to match reference |
| `_CountrySearchSheet` | Already identical — no change needed |
| `_SearchableDropdown<T>` | Already identical — no change needed |
| `_ImageTile` | Major change: scan page version takes `String imagePath` (non-nullable) and lacks `onRemove`; reference version takes `String? imagePath` and adds `onRemove` callback with close button. Replace the scan page class with the reference version. |
| `_DashedBorderPainter` | Does NOT exist in scan page at all — copy it wholesale from the reference |
| `_ImagePreviewSheet` | Scan page version takes `String imagePath` (file path); reference version takes `Uint8List bytes`. Keep scan page's file-path version since scan page uses file paths (reference uses bytes because it's portrait-from-picker). No change needed. |
| `_StateDropdown` | Already identical — no change needed |
| `_DistrictDropdown` | Already identical — no change needed |
| `_SectionLabel` | Keep as-is in scan page — it will be replaced by `_buildSectionCard` headers so it becomes dead code. Optionally delete it at the end. |
| `_ProfileOption` | Keep as-is — used by `_showProfilePhotoOptions()` which is unique to scan page |

---

## 5. Step-by-step approach to replace the 5 old section build methods with 5 new section cards

The scan page currently has these section methods in the `build()` `Column`:
1. `_buildImagesSection()` → flat Column with `_SectionLabel`
2. `_buildPassportSection()` → flat Column with `_SectionLabel`
3. `_buildTravelSection()` → flat Column with `_SectionLabel`
4. `_buildVisaSection()` → flat Column with `_SectionLabel` + custom white Container
5. `_buildSignatureSection()` → flat Column with `_SectionLabel`

Replace each with a card-based equivalent using `_buildSectionCard(...)`:

### Step 5a — Add `_buildSectionCard` method
Copy the `_buildSectionCard` method from `passport_form_page.dart` directly into `_PassportCardScanPageState`. Place it just before the first `_build...` section method, around line 1540.

### Step 5b — Replace `_buildImagesSection` → keep as is (no card wrapper)
The images section sits outside the card system in both files (passport_form_page uses a dedicated `_buildIdCardImagesCard`). In the scan page, rename the method `_buildImagesSection` to `_buildIdCardImagesCard` and wrap its content in `_buildSectionCard`:

```
_buildSectionCard(
  icon: Icons.photo_library_outlined,
  title: 'ID CARD IMAGES',
  children: [
    // Row 1: Front + Profile (existing Row widget, kept as is)
    // Row 2: Back / Last Page (existing _ImageTile, kept as is)
    // Signature sub-section (extract from _buildSignatureSection)
  ],
)
```

Note: The reference keeps "ID Card Images" and puts the Signature inside it. Apply the same pattern: merge `_buildSignatureSection()` content into the bottom of `_buildIdCardImagesCard()` after the image tiles.

### Step 5c — Replace `_buildPassportSection` → `_buildPassportDetailsCard`
New method mirrors `passport_form_page.dart`'s `_buildPassportDetailsCard()`:

```
_buildSectionCard(
  icon: Icons.badge_outlined,
  title: 'ID / PASSPORT DETAILS',
  children: [
    _FormField(label: 'First name',    controller: _givenNamesCtrl, required: true),
    _FormField(label: 'Last name',     controller: _surnameCtrl,    required: true),
    _DropdownField(label: 'Gender', value: _sex, items: ['M','F','O'], onChanged: ...),
    _DateField(label: 'Date of birth', controller: _dobCtrl, required: true, onTap: ...),
    _FormField(label: 'Address',       controller: _addressCtrl,    maxLines: 3),
    _FormField(label: 'Document no',   controller: _docNoCtrl,      required: true),
    _DateField(label: 'Date of issue', controller: _issuingDateCtrl, onTap: ...),
    _DateField(label: 'Expiry date',   controller: _expiryDateCtrl,  onTap: ...),
    _CountryDropdown(label: 'Nationality',    countries: _countries, selected: _selectedNationality,      onChanged: ...),
    _CountryDropdown(label: 'Place of issue', countries: _countries, selected: _selectedIssuingCountry,   onChanged: ...),
    _FormField(label: 'Place of issue city',  controller: _placeOfIssueCtrl),
  ],
)
```

Drop: the separate `_selectedPlaceOfIssueCountry` dropdown (was "Place of Issue (Country)") — the reference uses `_selectedIssuingCountry` for "Place of issue" country. Keep `_selectedPlaceOfIssueCountry` only to populate `Guest_POICountry` in the submit body; do NOT show it as a visible field (sync it to `_selectedIssuingCountry` via the `_fillFromOcr` method, which already does this).

Also drop: the standalone `_SearchableDropdown` for `Purpose of Visit` from this card. It moves to the Other Details card (as the reference does not show it in passport details).

Actually, looking at the reference more carefully: the reference does NOT include a Purpose of Visit field at all (it was removed). The scan page's `_selectedPurpose` is used in the submit body (`Guest_PurposeofVisit`) so keep the state variable and the submit key, but drop the UI field from the form.

### Step 5d — Replace `_buildVisaSection` → `_buildVisaDetailsCard`
New method mirrors `passport_form_page.dart`'s `_buildVisaDetailsCard()`:

```
_buildSectionCard(
  icon: Icons.card_travel_outlined,
  title: 'VISA / OCI DETAILS',
  children: [
    _DropdownField(label: 'Visa ID type', value: _visaType.isEmpty ? null : _visaType,
                   items: _visaTypes, onChanged: (v) { if (v != null) _onVisaTypeChanged(v); }),
    if (_showVisaFields) ...[
      _FormField(label: 'Visa number', controller: _visaDocNoCtrl),
      _DateField(label: 'Date of issue', controller: _visaIssuingDateCtrl, onTap: ...),
      _DateField(label: 'Expiry date',   controller: _visaExpiryDateCtrl,  onTap: ...),
      _CountryDropdown(label: 'Place of issue', countries: _countries,
                       selected: _selectedVisaCountry, onChanged: ...),
      _FormField(label: 'Place of issue city', controller: _visaPOICityCtrl),
      if (_visaDropTypes.isNotEmpty)
        _SearchableDropdown<VisaType>(label: 'Visa type', items: _visaDropTypes, ...),
      if (_visaType == 'e-Visa' && _visaSubTypes.isNotEmpty)
        _SearchableDropdown<VisaSubType>(label: 'Visa sub type', items: _visaSubTypes, ...),
      _FormField(label: 'FRRO application ID no', controller: _frroAppIdCtrl),
    ],
  ],
)
```

The OCI / e-Visa **image** tiles that were inside `_buildVisaSection` move into `_buildIdCardImagesCard` (Row 2 conditionally shows OCI Front or Visa Image, plus OCI extra rows — keep exactly as they are now, just inside the card wrapper).

### Step 5e — Replace `_buildTravelSection` → `_buildTravelDetailsCard`
New method mirrors `passport_form_page.dart`'s `_buildTravelDetailsCard()`:

```
_buildSectionCard(
  icon: Icons.flight_outlined,
  title: 'TRAVEL DETAILS',
  children: [
    // 70/30 Row: Arrival in India date + Time
    Row(children: [
      Expanded(flex:7, child: _DateField(label:'Arrival in India', controller:_arrivalInIndiaCtrl, onTap:...)),
      SizedBox(width:8),
      Expanded(flex:3, child: _FormField(label:'Time', controller:_arrivalTimeCtrl, keyboardType:datetime)),
    ]),
    _CountryDropdown(label:'Arrived from country', ...),
    _FormField(label:'Arrived from city',  controller:_arrivedFromCityCtrl),
    _FormField(label:'Arrived from place', controller:_arrivedFromPlaceCtrl),
    _FormField(label:'Duration of stay days', controller:_durationCtrl,
               keyboardType:numberWithOptions, inputFormatters:[digitsOnly]),
    // 70/30 Row: Hotel arrival date + Time
    Row(children: [
      Expanded(flex:7, child: _DateField(label:'Arrival in hotel', controller:_hotelArrivalDateCtrl, onTap:...)),
      SizedBox(width:8),
      Expanded(flex:3, child: _FormField(label:'Time', controller:_hotelArrivalTimeCtrl, keyboardType:datetime)),
    ]),
    _DateField(label:'Hotel departure', controller:_checkoutDateCtrl, onTap:...),
    _DateField(label:'Arrival date in state', controller:_arrivalDateInStateCtrl, onTap:...),  // NEW
    // Next Destination — always shown (drop _showNextDestination prefs gate; reference always shows it)
    _DropdownField(label:'Next destination', value:_nextDestinationType,
                   items:['Inside India','Outside India'], onChanged:...),
    if (_nextDestinationType == 'Inside India') ...[
      _StateDropdown(...), _DistrictDropdown(...), _FormField(label:'Place', ...),
    ],
    if (_nextDestinationType == 'Outside India') ...[
      _CountryDropdown(label:'Country', ...), _FormField(label:'City', ...), _FormField(label:'Place', ...),
    ],
  ],
)
```

Key changes vs. current:
- Remove the `if (_showNextDestination == true)` prefs gate — always show Next Destination.
- Remove the `if (_showRoomNo == true)` room-number field from here — Room No moves to Other Details.
- Change date+time from two sequential full-width fields to a 70/30 split Row.
- Add `_arrivalDateInStateCtrl` date field (new).

### Step 5f — Replace stub `_buildSignatureSection` with content merged into `_buildIdCardImagesCard`
The reference puts the signature widget at the bottom of the "ID Card Images" card. Merge the scan page's `_buildSignatureSection()` body directly into the end of `_buildIdCardImagesCard()`. Delete the standalone `_buildSignatureSection()` method.

### Step 5g — Add `_buildOtherDetailsCard`
This card does not exist at all in the scan page. Create it, mirroring the reference:

```
_buildSectionCard(
  icon: Icons.info_outline,
  title: 'OTHER DETAILS',
  children: [
    _FormField(label:'Room no',          controller:_roomNoCtrl),       // was gated by prefs
    _FormField(label:'Company',          controller:_companyCtrl),       // NEW
    _FormField(label:'Designation',      controller:_designationCtrl),   // NEW
    _FormField(label:'Number of persons',controller:_noOfPersonsCtrl,    // NEW
               keyboardType:numberWithOptions, inputFormatters:[digitsOnly]),
    _FormField(label:'Adults',           controller:_adultsCtrl,         // NEW
               keyboardType:numberWithOptions, inputFormatters:[digitsOnly]),
    _FormField(label:'Children',         controller:_childrenCtrl,       // NEW
               keyboardType:numberWithOptions, inputFormatters:[digitsOnly]),
    _DropdownField(label:'Employed in India',
                   value:_selectedEmployedInIndia,                       // NEW
                   items:['Yes','No'], onChanged:...),
    _FormField(label:'Duration of stay in India days',
               controller:_durationInIndiaCtrl,                          // NEW
               keyboardType:numberWithOptions, inputFormatters:[digitsOnly]),
    _DropdownField(label:'Mode of payment',
                   value:_selectedModeOfPayment,                         // NEW
                   items:['Cash','Card','UPI','Online'], onChanged:...),
    _FormField(label:'Email', controller:_emailCtrl,
               keyboardType:emailAddress, required:true),
    _FormField(label:'Phone no', controller:_phoneCtrl,
               keyboardType:phone, inputFormatters:[digitsOnly], required:true),
  ],
)
```

### Step 5h — Update `build()` Column children
Replace the old section method calls:

```dart
// OLD
_buildImagesSection(),
_buildPassportSection(),
_buildTravelSection(),
if (widget.showVisaSection) _buildVisaSection(),
_buildSignatureSection(),

// NEW
_buildIdCardImagesCard(),        // images + signature merged
const SizedBox(height: 20),
_buildPassportDetailsCard(),
const SizedBox(height: 20),
if (widget.showVisaSection) _buildVisaDetailsCard(),
if (widget.showVisaSection) const SizedBox(height: 20),
_buildTravelDetailsCard(),
const SizedBox(height: 20),
_buildOtherDetailsCard(),
const SizedBox(height: 20),
```

---

## 6. New submit body keys to add

The current scan page `_submit()` body is missing these keys. Add them after the existing keys:

```dart
// New FRRO / state arrival field
'FRROApplicationID':         _frroAppIdCtrl.text,
'ArrivalDateInState':        _arrivalDateInStateCtrl.text,

// New Other Details fields
'Guest_Company':             _companyCtrl.text,
'Guest_Designation':         _designationCtrl.text,
'Guest_NoOfPersons':         _noOfPersonsCtrl.text,
'Guest_Adults':              _adultsCtrl.text,
'Guest_Children':            _childrenCtrl.text,
'Guest_EmployedInIndia':     _selectedEmployedInIndia ?? '',
'Guest_DurationInIndia':     _durationInIndiaCtrl.text,
'Guest_ModeOfPayment':       _selectedModeOfPayment ?? '',
```

The scan page already sends `Guest_POICountry` via `_selectedPlaceOfIssueCountry`. Keep it — just ensure the value is still populated from OCR via `_selectedIssuingCountry` (the existing `_fillFromOcr` already sets both).

---

## 7. Import additions needed

Add these two imports that exist in `passport_form_page.dart` but are absent from `passport_card_scan_page.dart`:

```dart
import 'package:flutter/services.dart';           // FilteringTextInputFormatter, TextInputFormatter
import '../utils/date_validator.dart';             // DateValidator.validateIssuingDate / validatePassportExpiryDate / validateVisaIssuingDate / validateVisaExpiryDate
import '../utils/image_converter.dart';            // ImageConverter.toBase64FromPath (optional — scan page has inline _toBase64FromPath, can keep that)
```

Minimum required addition:
- `package:flutter/services.dart` — needed for `FilteringTextInputFormatter.digitsOnly` used in the new numeric fields (Number of Persons, Adults, Children, Duration in India, Duration of Stay).
- `'../utils/date_validator.dart'` — strongly recommended; the reference uses it for issuing/expiry date validation in `_validate()`. Update `_validate()` in the scan page to call `DateValidator.validateIssuingDate`, `validatePassportExpiryDate`, `validateVisaIssuingDate`, `validateVisaExpiryDate` — matching the reference pattern and catching user errors before submit.

`image_converter.dart` is optional — the scan page already has its own inline `_toBase64FromPath()` helper that reads the file synchronously, which is fine.

---

## 8. Additional notes and constraints

### What must NOT be changed
- All OCR extraction methods: `_extractFromImage()`, `_extractPassportWithBackImage()`, `_fillFromOcr()`, `_fillVisaFromOcr()`.
- All image capture methods: `_autoCaptureFront()`, `_pickFrontImage()`, `_pickBackImage()`, `_pickProfileImage()`, `_showProfilePhotoOptions()`, `_retakeWithScanner()`, `_offerProfileCrop()`, `_offerBackImageCapture()`.
- All visa methods: `_onVisaTypeChanged()`, `_showVisaFrontSheet()`, `_showVisaBackSheet()`, `_showVisaStampSheet()`.
- `initState()` logic, `_loadLookups()`, `_loadDistrictsForState()`, `_loadVisaSubTypes()`, `_loadNextDestinationVisibility()`, `_loadRoomNoVisibility()`.
- `_handleSessionExpired()`, `_deleteProfileLatestFile()`.
- The `PassportCardScanPage` widget class and all its constructor params.
- `_ProfileOption`, `_ProfileOption` bottom sheet, `_ImagePreviewSheet` (file-path version), `_CountrySearchSheet`, `_StateDropdown`, `_DistrictDropdown`.

### Prefs-gated fields behaviour change
- `_showNextDestination` pref gate: **remove** — always show Next Destination (reference pattern).
- `_showRoomNo` pref gate: **remove** — Room No is always shown in Other Details card (reference pattern).
- Keep `_loadNextDestinationVisibility()` and `_loadRoomNoVisibility()` in `initState()` and as methods to avoid breaking unrelated logic; just stop using the booleans as gate conditions in the UI.

### `_buildVisaImageTile` helper
The scan page has a private `_buildVisaImageTile(label, imagePath, onTap, onRemove)` method used inside `_buildVisaSection`. After the refactor, visa images move into `_buildIdCardImagesCard` using the standard `_ImageTile` widget (same as the reference). Delete `_buildVisaImageTile` once the old `_buildVisaSection` is gone.

### Widget replacement compatibility: `_ImageTile`
The scan page's `_ImageTile` takes `String imagePath` (non-nullable). After replacement it will take `String? imagePath`. The call sites in `_buildIdCardImagesCard` pass `_visaImagePath` (nullable) and `_backImagePath` (String, non-nullable). Update `_backImagePath` call site to pass `_backImagePath.isNotEmpty ? _backImagePath : null` OR change the reference signature so it accepts both. Easiest: use the reference signature that takes `String? imagePath` and update existing call sites for `_frontImagePath` and `_profileImagePath` to pass `path.isEmpty ? null : path`.

### `_DropdownField` — value type change
Current scan page `_DropdownField.value` is `String` (non-nullable). After replacement it becomes `String?`. Existing call sites for `_sex` (always 'M'/'F'/'O') remain safe; call sites for `_visaType` (which can be empty string '') should pass `_visaType.isEmpty ? null : _visaType`.

---

## Verification

```
flutter analyze lib/features/scan/presentation/pages/passport_card_scan_page.dart
flutter build apk --debug
```

Both should complete without errors. No automated widget tests exist for this file; verify visually by navigating to the form from `foreign_passport_scan_page.dart` and `domestic_passport_scan_page.dart`.

---

## Analyze Output (post-implementation)

```
Analyzing passport_card_scan_page.dart...
No issues found! (ran in 6.0s)
Exit Code: 0
```

Implementation completed successfully. All 5 cards implemented:
1. ID / PASSPORT DETAILS card
2. VISA / OCI DETAILS card (gated by showVisaSection)
3. TRAVEL DETAILS card (always-shown Next Destination, 70/30 date+time rows, new arrival date in state field)
4. OTHER DETAILS card (new company, designation, persons, adults, children, employed, duration in India, mode of payment)
5. ID CARD IMAGES card (passport front, portrait, back, visa/OCI images, signature merged in)

New controllers added: _frroAppIdCtrl, _arrivalDateInStateCtrl, _companyCtrl, _designationCtrl, _noOfPersonsCtrl, _adultsCtrl, _childrenCtrl, _employedInIndia, _durationInIndiaCtrl, _selectedModeOfPayment.

New submit body keys added: FRROApplicationID, ArrivalDateInState, Guest_Company, Guest_Designation, Guest_NoOfPersons, Guest_Adults, Guest_Children, Guest_EmployedInIndia, Guest_DurationInIndia, Guest_ModeOfPayment.
