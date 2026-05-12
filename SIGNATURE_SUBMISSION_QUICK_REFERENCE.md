# Signature Submission - Quick Reference

## Answer
✅ **YES** - Signature is being sent to the API in both flows.

---

## Quick Facts

| Aspect | Details |
|--------|---------|
| **Domestic Card Flow** | ✅ Signature sent |
| **Passport Flow** | ✅ Signature sent |
| **API Field Name** | `GuestSignatureFile` |
| **Format** | Base64 encoded bytes |
| **Optional** | Yes (empty string if not captured) |
| **Capture Method** | `SignaturePadPage` |

---

## Signature Journey

```
SignaturePadPage (User draws signature)
    ↓
Uint8List (signature bytes)
    ↓
_signatureBytes variable
    ↓
base64Encode() conversion
    ↓
'GuestSignatureFile': signatureBase64
    ↓
API Request Body
    ↓
API Endpoint (saveIndianCard or savePassport)
    ↓
Database Storage
```

---

## Code Locations

### Domestic Card
- **File**: `lib/features/scan/presentation/pages/card_scan_page.dart`
- **Line**: ~506
- **Field**: `'GuestSignatureFile': signatureBase64`
- **API**: `_repo.saveIndianCard(body)`

### Passport
- **File**: `lib/features/scan/presentation/pages/passport_form_page.dart`
- **Line**: ~545-548
- **Field**: `'GuestSignatureFile': _signatureBytes != null ? base64Encode(_signatureBytes!) : ''`
- **API**: `_repo.savePassport(body)`

---

## Signature Capture UI

Both flows have a "Capture Signature" button that:
1. Opens `SignaturePadPage`
2. User draws signature
3. Returns `Uint8List`
4. Stored in `_signatureBytes`
5. Sent to API on submit

---

## Example API Request

```json
{
  "Guest_Firstname": "John",
  "Guest_Lastname": "Doe",
  "GuestSignatureFile": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==",
  ...other fields...
}
```

---

## Status
✅ **Working Correctly** - Signature is properly captured, encoded, and sent to API in both flows.
