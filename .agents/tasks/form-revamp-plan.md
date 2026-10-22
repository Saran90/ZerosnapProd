# Implementation Plan — Form Revamp

**Files touched:**
- `lib/features/scan/presentation/pages/passport_form_page.dart`
- `lib/features/scan/presentation/pages/card_scan_page.dart`

**Build / verify commands:**
- Analyze: `flutter analyze` (from repo root `c:\Users\SARAN\Documents\Work\ZerosnapProd`)
- Build: `flutter build apk --debug`
- Manual smoke-test: hot-reload on device, open both forms, confirm all sections and fields render.

---

## FEAT-001 — Shared widget upgrades (both files)

- [ ] 1. Add `import 'package:flutter/services.dart';` to **both** files (for `FilteringTextInputFormatter`).
      Files: `passport_form_page.dart`, `card_scan_page.dart`
      Verify: `flutter analyze` — 0 errors.

- [ ] 2. Introduce `_buildSectionCard()` helper in **both** files.
      Each call returns a `Card` (elevation 2, radius 12) whose child is a `Column` containing:
      (a) A `Container` with `decoration: BoxDecoration(border: Border(left: BorderSide(color: AppColors.accent, width: 3)), borderRadius: BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)))` wrapping the inner `Padding`.
      (b) Header row: 32×32 circle `Container` with `color: AppColors.accent.withValues(alpha: 0.15)` holding the `icon` in `AppColors.accent` size 18; then 12 px gap; then `Text(title)` bold uppercase `AppColors.textPrimaryLight` size 13.
      (c) `Divider(height: 1, color: AppColors.dividerLight)` with 12 px top margin / 16 px bottom margin.
      (d) Spread of `children` widgets.
      Signature: `Widget _buildSectionCard({required IconData icon, required String title, required List<Widget> children})`.
      In **passport_form_page.dart** this replaces all direct `Card()+_SectionHeader()` call sites.
      In **card_scan_page.dart** this replaces `_sectionHeader()` call sites; delete `_sectionHeader()` after migration.
      Files: `passport_form_page.dart`, `card_scan_page.dart`
      Verify: `flutter analyze` — 0 errors.

- [ ] 3. Update `_FormField` widget class in **both** files:
      - Increase `OutlineInputBorder` radius from 10 → **12** in all three border variants.
      - Reduce bottom `Padding` from 16 → **14**.
      - Add `bool required = false` parameter. When `true`, set `label:` on `InputDecoration` to a `RichText` widget: `RichText(text: TextSpan(children: [TextSpan(text: label, style: TextStyle(fontSize: 13, color: Colors.grey[600])), if (required) TextSpan(text: ' *', style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600))]))`.  Replace `labelText:` with `label:`.
      - Add `int maxLines = 1` parameter; pass to `TextField`.
      - Add `List<TextInputFormatter>? inputFormatters` parameter; pass to `TextField`.
      Files: `passport_form_page.dart`, `card_scan_page.dart`
      Verify: `flutter analyze` — 0 errors.

- [ ] 4. Update `_DateField` and `_DropdownField` widget classes in **both** files:
      - Radius 10 → **12** in all borders; bottom padding 16 → **14**.
      - In `_DropdownField`: make `value` parameter `String?` (nullable) to support unselected state; add `bool required = false` and apply same RichText label asterisk pattern as `_FormField`.
      Files: `passport_form_page.dart`, `card_scan_page.dart`
      Verify: `flutter analyze` — 0 errors.

- [ ] 5. Update `_CountryDropdown` and `_SearchableDropdown` border radius 10 → **12**, padding 16 → **14** in **passport_form_page.dart**.
      Files: `passport_form_page.dart`
      Verify: `flutter analyze` — 0 errors.

- [ ] 6. Add `_DashedBorderPainter extends CustomPainter` private class at bottom of **both** files.
      Draws a dashed rectangular border: in `paint()` iterate around the rect, alternating `canvas.drawLine` at intervals (dashWidth=6, dashSpace=4). Used by `_ImageTile`.
      Also add / upgrade `_ImageTile` widget in **both** files:
      - When `imagePath` is null/empty: wrap the tile `Container` in a `CustomPaint(painter: _DashedBorderPainter(color: Colors.grey[400]!))` instead of `Border.all`.
      - When `imagePath` is not empty: add a `Positioned` top-right green badge: `Container(width:20, height:20, decoration: BoxDecoration(color: AppColors.success, shape: BoxShape.circle), child: Icon(Icons.check, color: Colors.white, size: 13))`.
      - Add `VoidCallback? onRemove` parameter (optional); show an ×-button overlay when set and image is present.
      In **passport_form_page.dart** this is a new class (does not already exist there). In **card_scan_page.dart** this upgrades the existing `_ImageTile`.
      Files: `passport_form_page.dart`, `card_scan_page.dart`
      Verify: `flutter analyze` — 0 errors.

---

## FEAT-002 — passport_form_page.dart revamp

### State additions

- [ ] 7. Add new state variable declarations to `_PassportFormPageState` (insert after existing `_backImagePath`):
      ```dart
      String? _idFrontImagePath;
      final _frroAppIdCtrl = TextEditingController();
      final _arrivalDateInStateCtrl = TextEditingController();
      DateTime? _arrivalDateInState;
      MrzCountry? _selectedArrivedFromCountry;
      final _companyCtrl       = TextEditingController();
      final _designationCtrl   = TextEditingController();
      final _noOfPersonsCtrl   = TextEditingController();
      final _adultsCtrl        = TextEditingController();
      final _childrenCtrl      = TextEditingController();
      String? _selectedEmployedInIndia;
      final _durationInIndiaCtrl = TextEditingController();
      String? _selectedModeOfPayment;
      ```
      Remove `_arrivedFromCountryCtrl` field (replace with `_selectedArrivedFromCountry`).
      Remove `bool? _showRoomNo` field.
      Remove `bool? _showNextDestination` field.
      Files: `passport_form_page.dart`
      Verify: `flutter analyze` — 0 errors (field references will break until fixed in later steps).

- [ ] 8. Remove `_loadRoomNoVisibility()` method and its `initState()` call.
      Remove `_loadNextDestinationVisibility()` method and its `initState()` call.
      Files: `passport_form_page.dart`
      Verify: `flutter analyze` — 0 errors.

- [ ] 9. Remove `_arrivedFromCountryCtrl` from the `dispose()` controller list.
      Add new controllers to `dispose()` list: `_frroAppIdCtrl`, `_arrivalDateInStateCtrl`, `_companyCtrl`, `_designationCtrl`, `_noOfPersonsCtrl`, `_adultsCtrl`, `_childrenCtrl`, `_durationInIndiaCtrl`.
      Files: `passport_form_page.dart`
      Verify: `flutter analyze` — 0 errors.

- [ ] 10. Add `_showIdFrontSheet()` method:
       ```dart
       void _showIdFrontSheet() {
         _showImageSourceSheet('ID Front', (src) async {
           final path = await _pickImageToPath(src);
           if (path != null && mounted) setState(() => _idFrontImagePath = path);
         });
       }
       ```
       Files: `passport_form_page.dart`
       Verify: `flutter analyze` — 0 errors.

### build() restructure

- [ ] 11. Rewrite the `Column` children inside `build()` → `SingleChildScrollView`:
       Replace the old list with:
       ```dart
       _buildPassportDetailsCard(),
       const SizedBox(height: 20),
       if (widget.showVisaSection) _buildVisaDetailsCard(),
       if (widget.showVisaSection) const SizedBox(height: 20),
       _buildTravelDetailsCard(),
       const SizedBox(height: 20),
       _buildOtherDetailsCard(),
       const SizedBox(height: 20),
       _buildIdCardImagesCard(),
       ```
       Files: `passport_form_page.dart`
       Verify: `flutter analyze` — compiler errors expected until new `_build*` methods are added.

- [ ] 12. Add `_buildPassportDetailsCard()` method.
       Uses `_buildSectionCard(icon: Icons.badge_outlined, title: 'ID / PASSPORT DETAILS', children: [...])`.
       Field list in order:
       1. `_FormField(label: 'First name', controller: _givenNamesCtrl, required: true)`
       2. `_FormField(label: 'Last name', controller: _surnameCtrl, required: true)`
       3. `_DropdownField(label: 'Gender', value: _sex, items: const ['M', 'F', 'O'], onChanged: (v) => setState(() => _sex = v!), required: true)`
       4. `_DateField(label: 'Date of birth', controller: _dobCtrl, onTap: ...)` (required asterisk via `_buildRequiredLabel` or inline label)
       5. `_FormField(label: 'Address', controller: _addressCtrl, keyboardType: TextInputType.streetAddress, maxLines: 3)`
       6. `_FormField(label: 'Document no', controller: _docNoCtrl, required: true)`
       7. `_DateField(label: 'Date of issue', controller: _issuingDateCtrl, onTap: ...)`
       8. `_DateField(label: 'Expiry date', controller: _expiryDateCtrl, onTap: ...)`
       9. `_CountryDropdown(label: 'Nationality', countries: _countries, selected: _selectedNationality, onChanged: ...)`
       10. `_CountryDropdown(label: 'Place of issue', countries: _countries, selected: _selectedIssuingCountry, onChanged: ...)` ← label renamed from 'Issuing Country'
       11. `_FormField(label: 'Place of issue city', controller: _placeOfIssueCtrl)`
       Files: `passport_form_page.dart`
       Verify: `flutter analyze` — 0 errors.

- [ ] 13. Add `_buildVisaDetailsCard()` method.
       Uses `_buildSectionCard(icon: Icons.card_travel_outlined, title: 'VISA / OCI DETAILS', children: [...])`.
       Field list:
       1. `_DropdownField(label: 'Visa ID type', value: _visaType.isEmpty ? null : _visaType, items: _visaTypes, onChanged: (v) { if (v != null) _onVisaTypeChanged(v); })`
       2. `if (_showVisaFields)` block containing:
          - `_FormField(label: 'Visa number', controller: _visaDocNoCtrl)`
          - `_DateField(label: 'Date of issue', controller: _visaIssuingDateCtrl, onTap: ...)`
          - `_DateField(label: 'Expiry date', controller: _visaExpiryDateCtrl, onTap: ...)`
          - `_CountryDropdown(label: 'Place of issue', countries: _countries, selected: _selectedVisaCountry, onChanged: ...)`
          - `_FormField(label: 'Place of issue city', controller: _visaPOICityCtrl)`
          - `if (_visaDropTypes.isNotEmpty) _SearchableDropdown<VisaType>(label: 'Visa type', ...)`
          - `if (_visaType == 'e-Visa' && _visaSubTypes.isNotEmpty) _SearchableDropdown<VisaSubType>(...)`
          - `_FormField(label: 'FRRO application ID no', controller: _frroAppIdCtrl)`
       **No image slots here** — images move to ID Card Images card.
       Files: `passport_form_page.dart`
       Verify: `flutter analyze` — 0 errors.

- [ ] 14. Add `_buildTravelDetailsCard()` method.
       Uses `_buildSectionCard(icon: Icons.flight_outlined, title: 'TRAVEL DETAILS', children: [...])`.
       Field list in order:
       1. Arrival in India row (70/30): `Row(children: [Expanded(flex:7, child: _DateField(label:'Arrival in India', controller:_arrivalInIndiaCtrl, onTap:...)), SizedBox(width:8), Expanded(flex:3, child: _FormField(label:'Time', controller:_arrivalTimeCtrl, keyboardType:TextInputType.datetime))])`
       2. `_CountryDropdown(label: 'Arrived from country', countries: _countries, selected: _selectedArrivedFromCountry, onChanged: (c) => setState(() => _selectedArrivedFromCountry = c))`
       3. `_FormField(label: 'Arrived from city', controller: _arrivedFromCityCtrl)`
       4. `_FormField(label: 'Arrived from place', controller: _arrivedFromPlaceCtrl)`
       5. `_FormField(label: 'Duration of stay days', controller: _durationOfStayCtrl, keyboardType: TextInputType.numberWithOptions(decimal: false), inputFormatters: [FilteringTextInputFormatter.digitsOnly])`
       6. Hotel arrival row (70/30): `Row(children: [Expanded(flex:7, child: _DateField(label:'Arrival in hotel', controller:_hotelArrivalDateCtrl, onTap:...)), SizedBox(width:8), Expanded(flex:3, child: _FormField(label:'Time', controller:_hotelArrivalTimeCtrl, keyboardType:TextInputType.datetime))])`
       7. `_DateField(label: 'Hotel departure', controller: _checkoutDateCtrl, onTap: ...)`
       8. `_DateField(label: 'Arrival date in state', controller: _arrivalDateInStateCtrl, onTap: () => _pickDate(initial: _arrivalDateInState, first: DateTime(2000), last: DateTime.now().add(const Duration(days: 365 * 5)), helpText: 'Arrival Date in State', onPicked: (d) => setState(() { _arrivalDateInState = d; _arrivalDateInStateCtrl.text = _fmt(d); })))`
       9. Next Destination block — **always shown** (no `_showNextDestination` gate):
          - `_DropdownField(label: 'Next destination', value: _nextDestinationType, items: const ['Inside India', 'Outside India'], onChanged: ...)`
          - `if (_nextDestinationType == 'Inside India')`: State dropdown, District dropdown, Place field
          - `if (_nextDestinationType == 'Outside India')`: Country dropdown, City field, Place field
       Files: `passport_form_page.dart`
       Verify: `flutter analyze` — 0 errors.

- [ ] 15. Add `_buildOtherDetailsCard()` method.
       Uses `_buildSectionCard(icon: Icons.info_outline, title: 'OTHER DETAILS', children: [...])`.
       Field list:
       1. `_FormField(label: 'Room no', controller: _roomNoCtrl)` — **always shown** (no gate)
       2. `_FormField(label: 'Company', controller: _companyCtrl)`
       3. `_FormField(label: 'Designation', controller: _designationCtrl)`
       4. `_FormField(label: 'Number of persons', controller: _noOfPersonsCtrl, keyboardType: TextInputType.numberWithOptions(decimal: false), inputFormatters: [FilteringTextInputFormatter.digitsOnly])`
       5. `_FormField(label: 'Adults', controller: _adultsCtrl, keyboardType: TextInputType.numberWithOptions(decimal: false), inputFormatters: [FilteringTextInputFormatter.digitsOnly])`
       6. `_FormField(label: 'Children', controller: _childrenCtrl, keyboardType: TextInputType.numberWithOptions(decimal: false), inputFormatters: [FilteringTextInputFormatter.digitsOnly])`
       7. `_DropdownField(label: 'Employed in India', value: _selectedEmployedInIndia, items: const ['Yes', 'No'], onChanged: (v) => setState(() => _selectedEmployedInIndia = v))`
       8. `_FormField(label: 'Duration of stay in India days', controller: _durationInIndiaCtrl, keyboardType: TextInputType.numberWithOptions(decimal: false), inputFormatters: [FilteringTextInputFormatter.digitsOnly])`
       9. `_DropdownField(label: 'Mode of payment', value: _selectedModeOfPayment, items: const ['Cash', 'Card', 'UPI', 'Online'], onChanged: (v) => setState(() => _selectedModeOfPayment = v))`
       10. `_FormField(label: 'Email', controller: _emailCtrl, keyboardType: TextInputType.emailAddress, required: true)`
       11. `_FormField(label: 'Phone no', controller: _phoneCtrl, keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly], required: true)`
       Files: `passport_form_page.dart`
       Verify: `flutter analyze` — 0 errors.

- [ ] 16. Add `_buildIdCardImagesCard()` method.
       Uses `_buildSectionCard(icon: Icons.photo_library_outlined, title: 'ID CARD IMAGES', children: [...])`.
       Layout:
       - Row 1: Portrait tile (left) + ID Front Side tile (right).
         - Portrait tile: inline `GestureDetector` wrapping a `Container` (height 110, dashed border when `_portraitBase64 == null`, green badge when set) showing `Image.memory(base64Decode(_portraitBase64!))` or an `Icons.person_outline` placeholder. Tap calls `_showPortraitSourceSheet()`.
         - ID Front tile: `_ImageTile(label: 'ID front side', imagePath: _idFrontImagePath ?? '', onTap: _showIdFrontSheet, onRemove: () => setState(() => _idFrontImagePath = null))`.
         - Wrap in: `Row(children: [Expanded(child: <portrait>), SizedBox(width: 12), Expanded(child: <id front>)])`.
       - Row 2: ID Back tile full-width: `_ImageTile(label: 'ID back side', imagePath: _backImagePath ?? '', onTap: _showBackImageSheet, onRemove: () => setState(() => _backImagePath = null), fullWidth: true)`.
         - Add `_showBackImageSheet()` helper that calls `_showImageSourceSheet('ID Back', (src) async { final p = await _pickImageToPath(src); if (p != null && mounted) setState(() => _backImagePath = p); })` if it doesn't already exist (currently the back image path has no dedicated sheet method — add it).
       - Visa/OCI image tiles (conditional, same logic as old `_buildVisaCard` image block):
         - `if (_isOCI)`: Row with OCI Front + OCI Back, then Row with OCI Stamp + empty `Expanded(child: SizedBox())`.
         - `if (_isEVisaOrDiplomat)`: Single `_ImageTile(label: 'Visa image', imagePath: _visaImagePath ?? '', ...)` full-width.
       - Signature tile: full-width `GestureDetector` wrapping the existing signature `Container` (height 100, dashed border when null, shows `Image.memory(_signatureBytes!)` when set). Preceded by a `Padding` row `Row(children: [Icon(Icons.draw_outlined, size: 16, color: AppColors.textSecondaryLight), SizedBox(width: 6), Text('Signature', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight))])` with `SizedBox(height: 8)` between label and the container. Tap calls `_captureSignature()`. Include the existing Clear button for signature.
       Files: `passport_form_page.dart`
       Verify: `flutter analyze` — 0 errors.

- [ ] 17. Delete old build methods no longer referenced: `_buildPortraitCard()`, `_buildPassportCard()`, `_buildTravelCard()`, `_buildVisaCard()`, `_buildSignatureCard()`.
       Also delete the `_SectionHeader` widget class at the bottom of the file (replaced by `_buildSectionCard` function).
       Files: `passport_form_page.dart`
       Verify: `flutter analyze` — 0 errors.

### Submit map updates

- [ ] 18. Update `_submit()` body map in passport_form_page.dart:
       - Change `'passportFile': ''` → `'passportFile': _toBase64FromPath(_idFrontImagePath) ?? ''`
       - Change `'ArrivedFromCountry': _arrivedFromCountryCtrl.text` → `'ArrivedFromCountry': _selectedArrivedFromCountry?.code ?? ''`
       - Add entries:
         ```dart
         'FRROApplicationID':   _frroAppIdCtrl.text,
         'ArrivalDateInState':  _arrivalDateInStateCtrl.text,
         'Guest_Company':       _companyCtrl.text,
         'Guest_Designation':   _designationCtrl.text,
         'Guest_NoOfPersons':   _noOfPersonsCtrl.text,
         'Guest_Adults':        _adultsCtrl.text,
         'Guest_Children':      _childrenCtrl.text,
         'Guest_EmployedInIndia': _selectedEmployedInIndia ?? '',
         'Guest_DurationInIndia': _durationInIndiaCtrl.text,
         'Guest_ModeOfPayment': _selectedModeOfPayment ?? '',
         ```
       Files: `passport_form_page.dart`
       Verify: `flutter analyze` — 0 errors, `flutter build apk --debug` — exits 0.

---

## FEAT-003 — card_scan_page.dart revamp

### Imports & state additions

- [ ] 19. Add imports to card_scan_page.dart:
       ```dart
       import '../../data/repositories/passport_repository.dart';
       import '../../domain/entities/lookup_models.dart';
       ```
       (flutter/services.dart was already added in step 1.)
       Files: `card_scan_page.dart`
       Verify: `flutter analyze` — 0 errors.

- [ ] 20. Add new state variable declarations to `_CardScanPageState`:
       ```dart
       final _passportRepo = PassportRepository();
       List<Purpose> _purposes = [];
       Purpose? _selectedPurpose;

       final _arrivalInHotelDateCtrl  = TextEditingController();
       final _arrivalInHotelTimeCtrl  = TextEditingController();
       final _arrivalDateInStateCtrl  = TextEditingController();
       DateTime? _arrivalInHotelDate;

       final _companyCtrl        = TextEditingController();
       final _designationCtrl    = TextEditingController();
       final _noOfPersonsCtrl    = TextEditingController();
       final _adultsCtrl         = TextEditingController();
       final _childrenCtrl       = TextEditingController();
       String? _selectedEmployedInIndia;
       final _durationInIndiaCtrl = TextEditingController();
       String? _selectedModeOfPayment;
       ```
       Remove `bool? _showRoomNo` field.
       Files: `card_scan_page.dart`
       Verify: `flutter analyze` — 0 errors (downstream references will break until later steps).

- [ ] 21. Update `initState()` in `_CardScanPageState`:
       - Remove `_loadRoomNoVisibility()` call and delete `_loadRoomNoVisibility()` method.
       - Add after existing setup code:
         ```dart
         _passportRepo.getPurposes().then((v) {
           if (mounted) setState(() => _purposes = v);
         });
         _arrivalInHotelDate = DateTime.now();
         _arrivalInHotelDateCtrl.text = _fmt(_arrivalInHotelDate!);
         _arrivalInHotelTimeCtrl.text =
             '${_arrivalInHotelDate!.hour.toString().padLeft(2, '0')}:'
             '${_arrivalInHotelDate!.minute.toString().padLeft(2, '0')}';
         ```
       Files: `card_scan_page.dart`
       Verify: `flutter analyze` — 0 errors.

- [ ] 22. Update `dispose()` in `_CardScanPageState`:
       Add to controller list: `_arrivalInHotelDateCtrl`, `_arrivalInHotelTimeCtrl`, `_arrivalDateInStateCtrl`, `_companyCtrl`, `_designationCtrl`, `_noOfPersonsCtrl`, `_adultsCtrl`, `_childrenCtrl`, `_durationInIndiaCtrl`.
       Files: `card_scan_page.dart`
       Verify: `flutter analyze` — 0 errors.

### build() restructure

- [ ] 23. Rewrite the `Column` children inside `build()` → `SingleChildScrollView` in card_scan_page.dart:
       Replace old list with:
       ```dart
       _buildDocumentDetailsCard(),
       const SizedBox(height: 20),
       _buildTravelDetailsCard(),
       const SizedBox(height: 20),
       _buildOtherDetailsCard(),
       const SizedBox(height: 20),
       _buildIdCardImagesCard(),
       ```
       Files: `card_scan_page.dart`
       Verify: `flutter analyze` — compiler errors expected until new methods added.

- [ ] 24. Add `_buildDocumentDetailsCard()` method using `_buildSectionCard(icon: Icons.badge_outlined, title: 'DOCUMENT DETAILS', children: [...])`.
       Field list:
       1. `_FormField(label: 'Document number', controller: _docNoCtrl, required: true)`
       2. `_FormField(label: 'First name', controller: _firstNameCtrl, required: true)`
       3. `_FormField(label: 'Last name', controller: _lastNameCtrl)`
       4. `_DropdownField(label: 'Gender', value: _selectedSex, items: const ['M', 'F', 'O'], onChanged: ..., required: true)`
       5. `_FormField(label: 'Address', controller: _addressCtrl, keyboardType: TextInputType.streetAddress)`
       6. `_DateField(label: 'Date of birth', controller: _dobCtrl, onTap: ..., required: true)`
       7. **Conditional** — only for `DomesticCardType.drivingLicense`:
          `if (widget.cardType == DomesticCardType.drivingLicense) ...[ _DateField(label: 'Issuing date', ...), _DateField(label: 'Expiration date', ...) ]`
       8. `_FormField(label: 'Email', controller: _emailCtrl, keyboardType: TextInputType.emailAddress)`
       9. `_FormField(label: 'Phone no', controller: _phoneCtrl, keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly], required: true)`
       Files: `card_scan_page.dart`
       Verify: `flutter analyze` — 0 errors.

- [ ] 25. Add `_buildTravelDetailsCard()` method using `_buildSectionCard(icon: Icons.flight_outlined, title: 'TRAVEL DETAILS', children: [...])`.
       Field list:
       1. `_FormField(label: 'Duration of stay days', controller: _durationCtrl, keyboardType: TextInputType.numberWithOptions(decimal: false), inputFormatters: [FilteringTextInputFormatter.digitsOnly])`
       2. `_DateField(label: 'Checkout date', controller: _checkoutCtrl, onTap: ...)`
       3. `if (_purposes.isNotEmpty) _SearchableDropdown<Purpose>(label: 'Purpose of visit', items: _purposes, selected: _selectedPurpose, itemLabel: (p) => p.purposeName, onChanged: (p) => setState(() => _selectedPurpose = p))`
       4. Hotel arrival row (70/30): `Row(children: [Expanded(flex:7, child: _DateField(label:'Arrival in hotel', controller:_arrivalInHotelDateCtrl, onTap:() => _pickDate(initial:_arrivalInHotelDate, first:DateTime(2000), last:DateTime.now().add(const Duration(days:365*5)), helpText:'Arrival in Hotel', onPicked:(d)=>setState((){_arrivalInHotelDate=d; _arrivalInHotelDateCtrl.text=_fmt(d);})))), SizedBox(width:8), Expanded(flex:3, child:_FormField(label:'Time', controller:_arrivalInHotelTimeCtrl, keyboardType:TextInputType.datetime))])`
       5. `_DateField(label: 'Arrival date in state', controller: _arrivalDateInStateCtrl, onTap: () => _pickDate(initial: null, first: DateTime(2000), last: DateTime.now().add(const Duration(days: 365 * 5)), helpText: 'Arrival Date in State', onPicked: (d) => setState(() => _arrivalDateInStateCtrl.text = _fmt(d))))`
       Files: `card_scan_page.dart`
       Verify: `flutter analyze` — 0 errors.

- [ ] 26. Add `_buildOtherDetailsCard()` method using `_buildSectionCard(icon: Icons.info_outline, title: 'OTHER DETAILS', children: [...])`.
       Field list:
       1. `_FormField(label: 'Room no', controller: _roomNoCtrl)` — **always visible** (no gate)
       2. `_FormField(label: 'Company', controller: _companyCtrl)`
       3. `_FormField(label: 'Designation', controller: _designationCtrl)`
       4. `_FormField(label: 'Number of persons', controller: _noOfPersonsCtrl, keyboardType: TextInputType.numberWithOptions(decimal: false), inputFormatters: [FilteringTextInputFormatter.digitsOnly])`
       5. `_FormField(label: 'Adults', controller: _adultsCtrl, ...)`
       6. `_FormField(label: 'Children', controller: _childrenCtrl, ...)`
       7. `_DropdownField(label: 'Employed in India', value: _selectedEmployedInIndia, items: const ['Yes', 'No'], onChanged: ...)`
       8. `_FormField(label: 'Duration of stay in India days', controller: _durationInIndiaCtrl, ...)`
       9. `_DropdownField(label: 'Mode of payment', value: _selectedModeOfPayment, items: const ['Cash', 'Card', 'UPI', 'Online'], onChanged: ...)`
       Files: `card_scan_page.dart`
       Verify: `flutter analyze` — 0 errors.

- [ ] 27. Add `_buildIdCardImagesCard()` method using `_buildSectionCard(icon: Icons.photo_library_outlined, title: 'ID CARD IMAGES', children: [...])`.
       Reuses existing image-picker handlers. Layout:
       - Row 1: Front tile + Profile Photo tile (`Row` with two `Expanded`)
       - Row 2: Back (optional) full-width tile
       - Signature tile: full-width, same `GestureDetector`+`Container` block from old `_buildSignatureCard()`, with a small label row above it.
       Use upgraded `_ImageTile` (dashed/badge from FEAT-001 step 6).
       Files: `card_scan_page.dart`
       Verify: `flutter analyze` — 0 errors.

- [ ] 28. Delete old build methods from `_CardScanPageState`: `_buildImagesCard()`, `_buildDetailsCard()`, `_buildStayCard()`, `_buildSignatureCard()`. Delete `_sectionHeader()` instance method (replaced by `_buildSectionCard`).
       Files: `card_scan_page.dart`
       Verify: `flutter analyze` — 0 errors.

- [ ] 29. Add `_SearchableDropdown<T>` private widget class at the bottom of `card_scan_page.dart` (for Purpose dropdown). Copy the implementation from `passport_form_page.dart` (same signature and body; no external dependency needed). This is the only new widget class to add to this file.
       Files: `card_scan_page.dart`
       Verify: `flutter analyze` — 0 errors.

### Submit map updates

- [ ] 30. Update `_submit()` body map in card_scan_page.dart — add keys:
       ```dart
       'Guest_Purpose':          _selectedPurpose?.purposeId ?? '',
       'Guest_ArrivalInHotel':   _arrivalInHotelDateCtrl.text,
       'Guest_ArrivalInHotelTime': _arrivalInHotelTimeCtrl.text,
       'Guest_ArrivalDateInState': _arrivalDateInStateCtrl.text,
       'Guest_Company':          _companyCtrl.text,
       'Guest_Designation':      _designationCtrl.text,
       'Guest_NoOfPersons':      _noOfPersonsCtrl.text,
       'Guest_Adults':           _adultsCtrl.text,
       'Guest_Children':         _childrenCtrl.text,
       'Guest_EmployedInIndia':  _selectedEmployedInIndia ?? '',
       'Guest_DurationInIndia':  _durationInIndiaCtrl.text,
       'Guest_ModeOfPayment':    _selectedModeOfPayment ?? '',
       ```
       Files: `card_scan_page.dart`
       Verify: `flutter analyze` — 0 errors, `flutter build apk --debug` — exits 0.

---

## Summary reference

### New state variables — passport_form_page.dart
| Variable | Type | Purpose |
|---|---|---|
| `_idFrontImagePath` | `String?` | ID Front image file path (passportFile key) |
| `_frroAppIdCtrl` | `TextEditingController` | FRRO Application ID No |
| `_arrivalDateInStateCtrl` / `_arrivalDateInState` | `TextEditingController` / `DateTime?` | Arrival date in state |
| `_selectedArrivedFromCountry` | `MrzCountry?` | Replaces free-text `_arrivedFromCountryCtrl` |
| `_companyCtrl` | `TextEditingController` | Guest company |
| `_designationCtrl` | `TextEditingController` | Guest designation |
| `_noOfPersonsCtrl` | `TextEditingController` | Number of persons |
| `_adultsCtrl` | `TextEditingController` | Number of adults |
| `_childrenCtrl` | `TextEditingController` | Number of children |
| `_selectedEmployedInIndia` | `String?` | 'Yes'/'No' |
| `_durationInIndiaCtrl` | `TextEditingController` | Duration of stay in India (days) |
| `_selectedModeOfPayment` | `String?` | Cash/Card/UPI/Online |

### New state variables — card_scan_page.dart
| Variable | Type | Purpose |
|---|---|---|
| `_passportRepo` | `PassportRepository` | Load purposes |
| `_purposes` / `_selectedPurpose` | `List<Purpose>` / `Purpose?` | Purpose of visit |
| `_arrivalInHotelDateCtrl` / `_arrivalInHotelTimeCtrl` / `_arrivalInHotelDate` | Controllers / `DateTime?` | Hotel arrival |
| `_arrivalDateInStateCtrl` | `TextEditingController` | Arrival date in state |
| `_companyCtrl` | `TextEditingController` | Guest company |
| `_designationCtrl` | `TextEditingController` | Guest designation |
| `_noOfPersonsCtrl` / `_adultsCtrl` / `_childrenCtrl` | `TextEditingController` | Persons breakdown |
| `_selectedEmployedInIndia` | `String?` | Yes/No |
| `_durationInIndiaCtrl` | `TextEditingController` | Duration in India days |
| `_selectedModeOfPayment` | `String?` | Payment mode |

### Build methods — passport_form_page.dart
| Old method | Action | New method |
|---|---|---|
| `_buildPortraitCard()` | **Delete** | Portrait moved into `_buildIdCardImagesCard()` |
| `_buildPassportCard()` | **Replace** | `_buildPassportDetailsCard()` |
| `_buildTravelCard()` | **Replace** | `_buildTravelDetailsCard()` |
| `_buildVisaCard()` | **Replace** | `_buildVisaDetailsCard()` |
| `_buildSignatureCard()` | **Delete** | Signature inline in `_buildIdCardImagesCard()` |
| _(new)_ | **Add** | `_buildOtherDetailsCard()` |
| _(new)_ | **Add** | `_buildIdCardImagesCard()` |
| _(new)_ | **Add** | `_buildSectionCard()` helper |

### Build methods — card_scan_page.dart
| Old method | Action | New method |
|---|---|---|
| `_buildImagesCard()` | **Replace** | `_buildIdCardImagesCard()` |
| `_buildDetailsCard()` | **Replace** | `_buildDocumentDetailsCard()` |
| `_buildStayCard()` | **Replace** | `_buildTravelDetailsCard()` |
| `_buildSignatureCard()` | **Delete** | Signature inline in `_buildIdCardImagesCard()` |
| `_sectionHeader()` | **Delete** | `_buildSectionCard()` helper |
| _(new)_ | **Add** | `_buildOtherDetailsCard()` |
| _(new)_ | **Add** | `_buildSectionCard()` helper |

### Design rules (apply throughout)
- Section Card: 3 px left `AppColors.accent` border, elevation 2, radius 12.
- Section header: 32×32 accent-tinted circle icon + bold uppercase title + full-width `Divider`.
- Fields: `OutlineInputBorder` radius **12**, bottom padding **14 px**.
- Required fields (`First name`, `Last name`, `Document no`, `Date of birth`, `Gender`, `Phone no`, `Email`): red ` *` appended to label via `RichText`.
- Image tiles: dashed `CustomPaint` border when empty; green `AppColors.success` checkmark badge when filled.
- Number fields: `TextInputType.numberWithOptions(decimal: false)` + `FilteringTextInputFormatter.digitsOnly`.
- Date fields: calendar suffix icon (existing pattern unchanged).
- `SizedBox(height: 20)` between section cards (was 16).
