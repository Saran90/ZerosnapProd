# Passport Fields Comparison - OCR Flow vs MRZ Flow

## Complete Side-by-Side Field Comparison

### PASSPORT CORE DETAILS SECTION

| Field Name | OCR Flow | MRZ Flow | Type | Notes |
|---|---|---|---|---|
| Surname | ✅ | ✅ | TextEditingController | API: guest_Firstname |
| Given Names | ✅ | ✅ | TextEditingController | API: guest_Lastname |
| Document Number | ✅ | ✅ | TextEditingController | API: guest_DocumentNo |
| Issuing Country | ✅ | ✅ | Text (OCR) / Dropdown (MRZ) | API: guest_CountryofIssue |
| Nationality | ✅ | ✅ | Text (OCR) / Dropdown (MRZ) | API: guest_Nationality |
| Date of Birth | ✅ | ✅ | DateTime Picker | API: guest_DOB |
| Sex | ✅ | ✅ | Dropdown (M/F/O) | API: guest_Gender |
| Issuing Date | ✅ | ✅ | DateTime Picker | API: guest_DateOfIssue |
| Expiry Date | ✅ | ✅ | DateTime Picker | API: guest_ExpiryDate |
| Place of Issue | ✅ | ✅ | TextEditingController | API: Guest_POICity |
| Address | ✅ | ✅ | TextEditingController | API: guest_Address |
| Email | ✅ | ✅ | TextEditingController | API: Guest_Email |
| Phone | ✅ | ✅ | TextEditingController | API: Guest_PhoneNo |

---

### TRAVEL / ARRIVAL SECTION

| Field Name | OCR Flow | MRZ Flow | Type | Notes |
|---|---|---|---|---|
| Date of Arrival in India | ✅ | ✅ | DateTime Picker | API: DateOfArrivalInIndia |
| Arrival Time (India) | ✅ | ❌ | TextEditingController | API: Arrival_Time |
| Arrived From Country | ✅ | ✅ | Text (OCR) / Dropdown (MRZ) | API: ArrivedFromCountry |
| Arrived From City | ✅ | ✅ | TextEditingController | API: ArrivedFromCity |
| Arrived From Place | ✅ | ✅ | TextEditingController | API: ArrivedFromPlace |
| Hotel Check-in Date | ✅ | ❌ | DateTime Picker | API: Arrival_Date |
| Hotel Check-in Time | ✅ | ❌ | TextEditingController | API: Arrival_Time_Hotel |
| Duration of Stay (days) | ✅ | ✅ | TextEditingController | API: IntendedDurationStayIndividualHouse |
| Checkout Date | ✅ | ✅ | DateTime Picker (auto-calc) | API: Guest_HotelCheckOutDate |

---

### NEXT DESTINATION SECTION

| Field Name | OCR Flow | MRZ Flow | Type | Notes |
|---|---|---|---|---|
| Next Destination Type | ✅ | ❌ | Dropdown (Inside/Outside India) | API: NextDestinationType |
| **For Inside India:** | | | | |
| - State | ✅ | ❌ | Dropdown | API: NextDestinationState |
| - District | ✅ | ❌ | Dropdown | API: NextDestinationDistrict |
| - Place | ✅ | ❌ | TextEditingController | API: NextDestinationPlaceIndia |
| **For Outside India:** | | | | |
| - Country | ✅ | ❌ | Dropdown | API: NextDestinationCountry |
| - City | ✅ | ❌ | TextEditingController | API: NextDestinationCity |
| - Place | ✅ | ❌ | TextEditingController | API: NextDestinationPlaceOutside |

---

### OTHER DETAILS SECTION

| Field Name | OCR Flow | MRZ Flow | Type | Notes |
|---|---|---|---|---|
| Purpose of Visit | ❌ | ✅ | Searchable Dropdown | API: guest_PurposeofVisit |
| Room Number | ❌ | ✅ | TextEditingController | API: GuestRoomNo |

---

### VISA INFORMATION SECTION

| Field Name | OCR Flow | MRZ Flow | Type | Notes |
|---|---|---|---|---|
| Visa Type | ✅ | ✅ | Dropdown | Options: MRZ Enable Visa, e-Visa, OCI, Diplomat, No Visa |
| Visa Document Number | ✅ | ✅ | TextEditingController | API: guest_VisaNo |
| Visa Issuing Country | ✅ | ✅ | Dropdown | API: guest_VisaPOICountry |
| Visa POI City | ✅ | ✅ | TextEditingController | API: Guest_VisaPOICity |
| Visa Issuing Date | ✅ | ✅ | DateTime Picker | API: guest_VisaDateofIssue |
| Visa Expiry Date | ✅ | ✅ | DateTime Picker | API: guest_VisaValidTill |
| Visa Sub Type | ✅ | ❌ | Dropdown (e-Visa only) | API: guest_VisaSubType |

---

### IMAGE FIELDS SECTION

| Field Name | OCR Flow | MRZ Flow | Type | Notes |
|---|---|---|---|---|
| Passport Front Image | ✅ | ✅ | File Path (Base64) | API: passportFile |
| Passport Back Image | ✅ | ❌ | File Path (Base64) | API: passportBackFile |
| Profile Photo | ✅ | ✅ | File Path (Base64) | API: profileImageFile |
| Signature | ✅ | ✅ | Uint8List (Base64) | API: User_Signature (OCR) / GuestSignatureFile (MRZ) |

---

### SUMMARY STATISTICS

| Metric | OCR Flow | MRZ Flow |
|---|---|---|
| **Total Fields** | 42 | 33 |
| **Passport Core Fields** | 13 | 13 |
| **Travel Fields** | 9 | 6 |
| **Next Destination Fields** | 7 | 0 |
| **Other Details Fields** | 0 | 2 |
| **Visa Fields** | 7 | 6 |
| **Image Fields** | 4 | 3 |
| **Unique to OCR** | 11 | - |
| **Unique to MRZ** | - | 2 |
| **Common Fields** | 31 | 31 |

---

## Field Availability Matrix

### Legend:
- ✅ = Field is available
- ❌ = Field is NOT available
- (Type) = Field type/control used

### Detailed Matrix:

```
PASSPORT CORE DETAILS
┌─────────────────────────────┬──────────┬──────────┐
│ Field                       │ OCR Flow │ MRZ Flow │
├─────────────────────────────┼──────────┼──────────┤
│ Surname                     │    ✅    │    ✅    │
│ Given Names                 │    ✅    │    ✅    │
│ Document Number             │    ✅    │    ✅    │
│ Issuing Country             │    ✅    │    ✅    │
│ Nationality                 │    ✅    │    ✅    │
│ Date of Birth               │    ✅    │    ✅    │
│ Sex                         │    ✅    │    ✅    │
│ Issuing Date                │    ✅    │    ✅    │
│ Expiry Date                 │    ✅    │    ✅    │
│ Place of Issue              │    ✅    │    ✅    │
│ Address                     │    ✅    │    ✅    │
│ Email                       │    ✅    │    ✅    │
│ Phone                       │    ✅    │    ✅    │
└─────────────────────────────┴──────────┴──────────┘

TRAVEL / ARRIVAL
┌─────────────────────────────┬──────────┬──────────┐
│ Field                       │ OCR Flow │ MRZ Flow │
├─────────────────────────────┼──────────┼──────────┤
│ Date of Arrival in India    │    ✅    │    ✅    │
│ Arrival Time (India)        │    ✅    │    ❌    │
│ Arrived From Country        │    ✅    │    ✅    │
│ Arrived From City           │    ✅    │    ✅    │
│ Arrived From Place          │    ✅    │    ✅    │
│ Hotel Check-in Date         │    ✅    │    ❌    │
│ Hotel Check-in Time         │    ✅    │    ❌    │
│ Duration of Stay            │    ✅    │    ✅    │
│ Checkout Date               │    ✅    │    ✅    │
└─────────────────────────────┴──────────┴──────────┘

NEXT DESTINATION
┌─────────────────────────────┬──────────┬──────────┐
│ Field                       │ OCR Flow │ MRZ Flow │
├─────────────────────────────┼──────────┼──────────┤
│ Next Destination Type       │    ✅    │    ❌    │
│ State (Inside India)        │    ✅    │    ❌    │
│ District (Inside India)     │    ✅    │    ❌    │
│ Place (Inside India)        │    ✅    │    ❌    │
│ Country (Outside India)     │    ✅    │    ❌    │
│ City (Outside India)        │    ✅    │    ❌    │
│ Place (Outside India)       │    ✅    │    ❌    │
└─────────────────────────────┴──────────┴──────────┘

OTHER DETAILS
┌─────────────────────────────┬──────────┬──────────┐
│ Field                       │ OCR Flow │ MRZ Flow │
├─────────────────────────────┼──────────┼──────────┤
│ Purpose of Visit            │    ❌    │    ✅    │
│ Room Number                 │    ❌    │    ✅    │
└─────────────────────────────┴──────────┴──────────┘

VISA INFORMATION
┌─────────────────────────────┬──────────┬──────────┐
│ Field                       │ OCR Flow │ MRZ Flow │
├─────────────────────────────┼──────────┼──────────┤
│ Visa Type                   │    ✅    │    ✅    │
│ Visa Document Number        │    ✅    │    ✅    │
│ Visa Issuing Country        │    ✅    │    ✅    │
│ Visa POI City               │    ✅    │    ✅    │
│ Visa Issuing Date           │    ✅    │    ✅    │
│ Visa Expiry Date            │    ✅    │    ✅    │
│ Visa Sub Type               │    ✅    │    ❌    │
└─────────────────────────────┴──────────┴──────────┘

IMAGES
┌─────────────────────────────┬──────────┬──────────┐
│ Field                       │ OCR Flow │ MRZ Flow │
├─────────────────────────────┼──────────┼──────────┤
│ Passport Front Image        │    ✅    │    ✅    │
│ Passport Back Image         │    ✅    │    ❌    │
│ Profile Photo               │    ✅    │    ✅    │
│ Signature                   │    ✅    │    ✅    │
└─────────────────────────────┴──────────┴──────────┘
```

---

## Field Type Comparison

### Fields with Different Types:

| Field | OCR Type | MRZ Type | Issue |
|---|---|---|---|
| Issuing Country | TextEditingController | MrzCountry Dropdown | Type mismatch |
| Nationality | TextEditingController | MrzCountry Dropdown | Type mismatch |
| Arrived From Country | TextEditingController | MrzCountry Dropdown | Type mismatch |
| Signature | `User_Signature` | `GuestSignatureFile` | API field name mismatch |
| Checkout Date | Formatted String | ISO8601 String | Format mismatch |

---

## API Field Name Mapping

### Passport Core Fields:
- Surname → `guest_Firstname`
- Given Names → `guest_Lastname`
- Document Number → `guest_DocumentNo`
- Issuing Country → `guest_CountryofIssue`
- Nationality → `guest_Nationality`
- Date of Birth → `guest_DOB`
- Sex → `guest_Gender`
- Issuing Date → `guest_DateOfIssue`
- Expiry Date → `guest_ExpiryDate`
- Place of Issue → `Guest_POICity`
- Address → `guest_Address`
- Email → `Guest_Email`
- Phone → `Guest_PhoneNo`

### Travel Fields:
- Date of Arrival in India → `DateOfArrivalInIndia`
- Arrival Time (India) → `Arrival_Time` (OCR only)
- Arrived From Country → `ArrivedFromCountry`
- Arrived From City → `ArrivedFromCity`
- Arrived From Place → `ArrivedFromPlace`
- Hotel Check-in Date → `Arrival_Date` (OCR only)
- Hotel Check-in Time → `Arrival_Time_Hotel` (OCR only)
- Duration of Stay → `IntendedDurationStayIndividualHouse`
- Checkout Date → `Guest_HotelCheckOutDate`

### Next Destination Fields (OCR only):
- Next Destination Type → `NextDestinationType`
- State → `NextDestinationState`
- District → `NextDestinationDistrict`
- Place (India) → `NextDestinationPlaceIndia`
- Country → `NextDestinationCountry`
- City → `NextDestinationCity`
- Place (Outside) → `NextDestinationPlaceOutside`

### Other Details:
- Purpose of Visit → `guest_PurposeofVisit` (MRZ only)
- Room Number → `GuestRoomNo` (MRZ only)

### Visa Fields:
- Visa Type → `guest_VisaType`
- Visa Document Number → `guest_VisaNo`
- Visa Issuing Country → `guest_VisaPOICountry`
- Visa POI City → `Guest_VisaPOICity`
- Visa Issuing Date → `guest_VisaDateofIssue`
- Visa Expiry Date → `guest_VisaValidTill`
- Visa Sub Type → `guest_VisaSubType` (OCR only)

### Image Fields:
- Passport Front → `passportFile`
- Passport Back → `passportBackFile` (OCR only)
- Profile Photo → `profileImageFile`
- Signature → `User_Signature` (OCR) / `GuestSignatureFile` (MRZ)

---

## Recommendations for Alignment

### Add to MRZ Flow (from OCR):
1. ✅ Arrival Time (India)
2. ✅ Hotel Check-in Date
3. ✅ Hotel Check-in Time
4. ✅ Next Destination Type
5. ✅ Next Destination State
6. ✅ Next Destination District
7. ✅ Next Destination Place (India)
8. ✅ Next Destination Country
9. ✅ Next Destination City
10. ✅ Next Destination Place (Outside)
11. ✅ Visa Sub Type
12. ✅ Passport Back Image

### Add to OCR Flow (from MRZ):
1. ✅ Purpose of Visit
2. ✅ Room Number

### Standardize:
1. ✅ Issuing Country → Use Dropdown in both
2. ✅ Nationality → Use Dropdown in both
3. ✅ Arrived From Country → Use Dropdown in both
4. ✅ Signature field name → Use `GuestSignatureFile` in both
5. ✅ Checkout date format → Use ISO8601 in both
