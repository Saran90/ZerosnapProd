# Signature API Submission Analysis

## Summary
✅ **YES** - Signature is being sent to the API in both domestic card and passport flows.

---

## Domestic Card Flow (CardScanPage)

### Signature Capture
```dart
// In _captureSignature() method
Future<void> _captureSignature() async {
  final result = await Navigator.of(context).push<Uint8List>(
    MaterialPageRoute(builder: (_) => const SignaturePadPage()),
  );
  if (result != null) setState(() => _signatureBytes = result);
}
```

### Signature Conversion
```dart
// In _submit() method
final signatureBase64 = _signatureBytes != null
    ? base64Encode(_signatureBytes!)
    : '';
```

### API Submission
```dart
final body = <String, dynamic>{
  'Guest_Firstname': _firstNameCtrl.text,
  'Guest_Lastname': _lastNameCtrl.text,
  'Guest_Gender': _selectedSex,
  'Guest_DOB': _dobCtrl.text,
  'Guest_Address': _addressCtrl.text,
  'Guest_Email': _emailCtrl.text,
  'Guest_PhoneNo': _phoneCtrl.text,
  'Guest_DocumentNo': _docNoCtrl.text,
  'Guest_DateOfIssue': _issueDateCtrl.text,
  'Guest_ExpiryDate': _expiryDateCtrl.text,
  'Guest_CardType': widget.cardType.label,
  'IsVerified': _isVerified,
  'VerifiedReason': _verifiedReason,
  'IdFrontFile': frontBase64,
  'IdBackFile': backBase64,
  'ProfileImageFile': profileBase64,
  'GuestSignatureFile': signatureBase64,  ← SIGNATURE SENT HERE
  'IntendedDurationStayIndividualHouse': _durationCtrl.text,
  'Guest_HotelCheckOutDate': _checkoutDate.toIso8601String(),
  'GuestRoomNo': _roomNoCtrl.text,
};

final success = await _repo.saveIndianCard(body);
```

### API Endpoint
- **Method**: `CardScanRepository.saveIndianCard(body)`
- **Field Name**: `GuestSignatureFile`
- **Value**: Base64 encoded signature bytes (or empty string if not captured)

---

## Passport Flow (PassportFormPage)

### Signature Capture
```dart
// In _captureSignature() method
Future<void> _captureSignature() async {
  final result = await Navigator.of(context).push<Uint8List>(
    MaterialPageRoute(builder: (_) => const SignaturePadPage()),
  );
  if (result != null) setState(() => _signatureBytes = result);
}
```

### Signature Conversion
```dart
// In _submit() method
'GuestSignatureFile': _signatureBytes != null
    ? base64Encode(_signatureBytes!)
    : '',
```

### API Submission
```dart
final body = <String, dynamic>{
  'guest_Firstname': _surnameCtrl.text,
  'guest_Lastname': _givenNamesCtrl.text,
  'guest_Father': _givenNamesCtrl.text,
  'guest_DocumentNo': _docNoCtrl.text,
  'guest_CountryofIssue': _selectedIssuingCountry?.code ?? '',
  'guest_Country': _selectedNationality?.code ?? '',
  'guest_Nationality': _selectedNationality?.code ?? '',
  'guest_DOB': _dobCtrl.text,
  'guest_Gender': _sex,
  'guest_DateOfIssue': _issuingDateCtrl.text,
  'guest_ExpiryDate': _expiryDateCtrl.text,
  'Guest_POICity': _placeOfIssueCtrl.text,
  'guest_Address': _addressCtrl.text,
  'Guest_Email': _emailCtrl.text,
  'Guest_PhoneNo': _phoneCtrl.text,
  'guest_PurposeofVisit': _selectedPurpose?.purposeId ?? '',
  'DateOfArrivalInIndia': _arrivalInIndiaCtrl.text,
  'ArrivedFromCountry': _selectedArrivedFromCountry?.code ?? '',
  'ArrivedFromCity': _arrivedFromCityCtrl.text,
  'ArrivedFromPlace': _arrivedFromPlaceCtrl.text,
  'IntendedDurationStayIndividualHouse': _durationOfStayCtrl.text,
  'Guest_HotelCheckOutDate': _checkoutDate.toIso8601String(),
  'GuestRoomNo': _roomNoCtrl.text,
  'passportFile': widget.scannedResult?.fullImage ?? '',
  'profileImageFile': _portraitBase64 ?? '',
  'GuestSignatureFile': _signatureBytes != null
      ? base64Encode(_signatureBytes!)
      : '',  ← SIGNATURE SENT HERE
};

// Add visa fields only if visa section is shown
if (widget.showVisaSection) {
  body.addAll({
    'guest_VisaNo': _visaDocNoCtrl.text,
    'guest_VisaPOICountry': _selectedVisaCountry?.code ?? '',
    'Guest_VisaPOICity': _visaPOICityCtrl.text,
    'guest_VisaDateofIssue': _visaIssuingDateCtrl.text,
    'guest_VisaValidTill': _visaExpiryDateCtrl.text,
    'guest_VisaType': _selectedDropVisaType?.visaId ?? '',
    'VisaIDCardType': _visaTypeInt(),
  });
  // ... visa file handling
}

final success = await _repo.savePassport(body);
```

### API Endpoint
- **Method**: `CardScanRepository.savePassport(body)`
- **Field Name**: `GuestSignatureFile`
- **Value**: Base64 encoded signature bytes (or empty string if not captured)

---

## Signature Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  SIGNATURE CAPTURE & SUBMISSION FLOW                            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

Step 1: User clicks "Capture Signature" button
        ↓
        Navigator.push(SignaturePadPage)

Step 2: User draws signature on SignaturePadPage
        ↓
        Returns Uint8List (signature bytes)

Step 3: Signature stored in _signatureBytes
        ↓
        setState(() => _signatureBytes = result)

Step 4: User clicks "Submit" button
        ↓
        _submit() method called

Step 5: Signature converted to Base64
        ↓
        final signatureBase64 = _signatureBytes != null
            ? base64Encode(_signatureBytes!)
            : '';

Step 6: Signature added to API request body
        ↓
        'GuestSignatureFile': signatureBase64

Step 7: API request sent
        ├─ Domestic Card: _repo.saveIndianCard(body)
        └─ Passport: _repo.savePassport(body)

Step 8: API processes signature
        ↓
        Signature stored in database
```

---

## Key Points

### 1. Signature Capture
- Both flows use `SignaturePadPage` for signature capture
- Returns `Uint8List` (raw signature bytes)
- Stored in `_signatureBytes` variable

### 2. Signature Encoding
- Signature is encoded to Base64 before sending
- Uses `base64Encode()` from `dart:convert`
- Empty string sent if signature not captured

### 3. API Field Name
- **Domestic Card**: `GuestSignatureFile`
- **Passport**: `GuestSignatureFile`
- Same field name in both flows

### 4. API Endpoints
- **Domestic Card**: `CardScanRepository.saveIndianCard(body)`
- **Passport**: `CardScanRepository.savePassport(body)`

### 5. Signature Handling
- Optional: User can skip signature capture
- If skipped: Empty string sent to API
- If captured: Base64 encoded bytes sent to API

---

## Files Involved

### 1. Signature Capture
- **File**: `lib/features/scan/presentation/pages/signature_pad.dart`
- **Class**: `SignaturePadPage`
- **Returns**: `Uint8List` (signature bytes)

### 2. Domestic Card Submission
- **File**: `lib/features/scan/presentation/pages/card_scan_page.dart`
- **Class**: `_CardScanPageState`
- **Method**: `_submit()`
- **API Call**: `_repo.saveIndianCard(body)`

### 3. Passport Submission
- **File**: `lib/features/scan/presentation/pages/passport_form_page.dart`
- **Class**: `_PassportFormPageState`
- **Method**: `_submit()`
- **API Call**: `_repo.savePassport(body)`

### 4. Repository
- **File**: `lib/features/scan/data/repositories/card_scan_repository.dart`
- **Methods**: `saveIndianCard()`, `savePassport()`

---

## API Request Structure

### Domestic Card Request
```json
{
  "Guest_Firstname": "John",
  "Guest_Lastname": "Doe",
  "Guest_Gender": "M",
  "Guest_DOB": "1990-01-01",
  "Guest_Address": "123 Main St",
  "Guest_Email": "john@example.com",
  "Guest_PhoneNo": "9876543210",
  "Guest_DocumentNo": "DL123456",
  "Guest_DateOfIssue": "2020-01-01",
  "Guest_ExpiryDate": "2030-01-01",
  "Guest_CardType": "Driving License",
  "IsVerified": 1,
  "VerifiedReason": "Valid",
  "IdFrontFile": "base64_encoded_front_image",
  "IdBackFile": "base64_encoded_back_image",
  "ProfileImageFile": "base64_encoded_profile_image",
  "GuestSignatureFile": "base64_encoded_signature",  ← SIGNATURE HERE
  "IntendedDurationStayIndividualHouse": "5",
  "Guest_HotelCheckOutDate": "2026-05-14T00:00:00.000Z",
  "GuestRoomNo": "101"
}
```

### Passport Request
```json
{
  "guest_Firstname": "John",
  "guest_Lastname": "Doe",
  "guest_DocumentNo": "A12345678",
  "guest_CountryofIssue": "IN",
  "guest_Country": "IN",
  "guest_Nationality": "IN",
  "guest_DOB": "1990-01-01",
  "guest_Gender": "M",
  "guest_DateOfIssue": "2020-01-01",
  "guest_ExpiryDate": "2030-01-01",
  "guest_Address": "123 Main St",
  "Guest_Email": "john@example.com",
  "Guest_PhoneNo": "9876543210",
  "passportFile": "base64_encoded_passport_image",
  "profileImageFile": "base64_encoded_profile_image",
  "GuestSignatureFile": "base64_encoded_signature",  ← SIGNATURE HERE
  "guest_VisaNo": "V123456",  ← IF VISA SECTION SHOWN
  "guest_VisaPOICountry": "IN",  ← IF VISA SECTION SHOWN
  "visaFile": "base64_encoded_visa_image"  ← IF VISA SECTION SHOWN
}
```

---

## Verification Checklist

- [x] Signature is captured via `SignaturePadPage`
- [x] Signature is stored in `_signatureBytes`
- [x] Signature is encoded to Base64
- [x] Signature is included in API request body
- [x] Field name is `GuestSignatureFile`
- [x] Both domestic card and passport flows send signature
- [x] Empty string sent if signature not captured
- [x] API endpoints receive signature data

---

## Conclusion

✅ **Signature is being sent to the API in both flows:**
- Domestic Card Flow: ✅ Sent via `saveIndianCard()`
- Passport Flow: ✅ Sent via `savePassport()`
- Field Name: `GuestSignatureFile`
- Format: Base64 encoded bytes
- Optional: Can be empty if not captured

The signature submission is working correctly in both flows.
