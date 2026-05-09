# FRRO Form-C Field Mapping Analysis

## 📊 API Data Structure Analysis

Based on the API response, here are all available fields for each guest:

### Personal Information
| API Field | Sample Value | Data Type | Notes |
|-----------|--------------|-----------|-------|
| `Guest_Firstname` | "RODRIGO" | String | First name |
| `Guest_Lastname` | "FARIAS DOS SANTOS" | String | Last name/Surname |
| `Guest_Father` | null | String | Father's name |
| `Guest_Mother` | null | String | Mother's name |
| `Guest_Spouse` | null | String | Spouse name |
| `Guest_Gender` | "Male" | String | Gender (Male/Female) |
| `Guest_DOB` | "16/03/2004" | String | Date of birth (DD/MM/YYYY) |

### Contact Information
| API Field | Sample Value | Data Type | Notes |
|-----------|--------------|-----------|-------|
| `Guest_PhoneNo` | "" | String | Phone number |
| `Guest_Email` | "" | String | Email address |
| `Guest_Address` | "" | String | Current address |

### Nationality & Country
| API Field | Sample Value | Data Type | Notes |
|-----------|--------------|-----------|-------|
| `Guest_Nationality` | "BRA" | String | 3-letter country code |
| `Guest_NationalityTxt` | "BRAZIL" | String | Full country name |
| `Guest_Country` | "BRA" | String | Country code |
| `Guest_CountryTxt` | "BRAZIL" | String | Full country name |
| `Guest_City` | "DPAS/DPF" | String | City |
| `Guest_State` | null | String | State |

### Document Information (Passport)
| API Field | Sample Value | Data Type | Notes |
|-----------|--------------|-----------|-------|
| `Guest_DocumentNo` | "AA000261" | String | Passport number |
| `Guest_CountryofIssue` | "BRA" | String | Country of issue code |
| `Guest_CountryofIssueTxt` | "DPAS/DPF" | String | Place of issue |
| `Guest_DateOfIssue` | "06/07/2015" | String | Issue date (DD/MM/YYYY) |
| `Guest_ExpiryDate` | "02/05/2026" | String | Expiry date (DD/MM/YYYY) |

### Visa Information
| API Field | Sample Value | Data Type | Notes |
|-----------|--------------|-----------|-------|
| `Guest_VisaNo` | "VL7789991" | String | Visa number |
| `Guest_VisaType` | "17" | String | Visa type code |
| `Guest_VisaSubTypeId` | "242" | String | Visa subtype |
| `Guest_VisaPOICity` | "" | String | Place of issue city |
| `Guest_VisaPOICountry` | "IND" | String | Place of issue country |
| `Guest_VisaPOICountryTxt` | "" | String | Place of issue country text |
| `Guest_VisaDateofIssue` | "30/01/2025" | String | Visa issue date |
| `Guest_VisaValidTill` | "09/05/2026" | String | Visa valid till |
| `VisaIDCardType` | 0 | Int | Visa/ID card type |

### Arrival Information
| API Field | Sample Value | Data Type | Notes |
|-----------|--------------|-----------|-------|
| `Arrival_Date` | "25/04/2026" | String | Hotel arrival date |
| `Arrival_Time` | "14:42" | String | Hotel arrival time |
| `DateOfArrivalInIndia` | "30/01/2025" | String | India arrival date |
| `ArrivedFromCountry` | "BRA" | String | Arrived from country code |
| `ArrivedFromCountryName` | null | String | Arrived from country name |
| `ArrivedFromCity` | "DPAS/DPF" | String | Arrived from city |
| `ArrivedFromPlace` | "DPAS/DPF" | String | Arrived from place |
| `ArrivalInHotel` | "0001-01-01T00:00:00" | String | Hotel arrival datetime |
| `ArrivalDateInState` | null | String | State arrival date |

### Departure Information
| API Field | Sample Value | Data Type | Notes |
|-----------|--------------|-----------|-------|
| `Guest_HotelCheckOut` | "26/04/2026" | String | Checkout date |
| `Guest_HotelCheckOutTime` | "14:42" | String | Checkout time |
| `NextDestination` | "I" | String | Next destination (I/O) |
| `NextDestination_IN_State` | "" | String | Next state in India |
| `NextDestination_IN_District` | "" | String | Next district in India |
| `NextDestination_IN_Place` | "" | String | Next place in India |
| `NextDestination_OUT_Country` | "" | String | Next country outside |
| `NextDestination_OUT_City` | "" | String | Next city outside |
| `NextDestination_OUT_Place` | "" | String | Next place outside |

### Purpose & Stay
| API Field | Sample Value | Data Type | Notes |
|-----------|--------------|-----------|-------|
| `Guest_PurposeofVisit` | "16" | String | Purpose code |
| `SpecialCategory` | "9" | String | Special category code |
| `IntendedDurationStayIndividualHouse` | 1 | Int | Duration of stay |
| `DurationOfStayInIndia` | null | String | Total India stay |

### Employment & Company
| API Field | Sample Value | Data Type | Notes |
|-----------|--------------|-----------|-------|
| `Company` | null | String | Company name |
| `Designation` | null | String | Designation |
| `EmployedInIndia_Yes_No` | "" | String | Employed in India |

### Accommodation
| API Field | Sample Value | Data Type | Notes |
|-----------|--------------|-----------|-------|
| `GuestRoomNo` | null | String | Room number |
| `AddressInIndia` | null | String | Address in India |
| `AddressResidingPermanently` | null | String | Permanent address |

### Contact Person
| API Field | Sample Value | Data Type | Notes |
|-----------|--------------|-----------|-------|
| `GuestContactPersonToVisit` | null | String | Contact person name |
| `GuestDepartmentToVisit` | null | String | Department to visit |

### Vehicle Information
| API Field | Sample Value | Data Type | Notes |
|-----------|--------------|-----------|-------|
| `GuestVehicleType` | 0 | Int | Vehicle type |
| `GuestVehicleNo` | null | String | Vehicle number |

### Group Information
| API Field | Sample Value | Data Type | Notes |
|-----------|--------------|-----------|-------|
| `NumberOfPersons` | null | String | Number of persons |
| `Adults` | null | Int | Number of adults |
| `Children` | null | Int | Number of children |
| `PaxNo` | 0 | Int | Passenger number |
| `PaxNoAll` | 0 | Int | Total passengers |

### System Fields
| API Field | Sample Value | Data Type | Notes |
|-----------|--------------|-----------|-------|
| `Guestdata_id` | 192 | Int | Guest ID |
| `Guest_Code` | "XSLSFKX9" | String | Guest code |
| `Guest_PassToFRRO` | 0 | Int | Synced to FRRO (0/1) |
| `IsCheckOut` | 0 | Int | Checked out (0/1) |
| `Guest_ProfilePic` | "base64..." | String | Profile photo |

## 🎯 FRRO Form-C Required Fields Mapping

Based on the official FRRO Form-C, here's the mapping:

### Section 1: Personal Details
| Form Field | API Field | JavaScript ID | Required | Available |
|------------|-----------|---------------|----------|-----------|
| Surname | `Guest_Lastname` | `applicant_surname` | ✅ Yes | ✅ Yes |
| Given Name | `Guest_Firstname` | `applicant_givenname` | ✅ Yes | ✅ Yes |
| Gender | `Guest_Gender` | `applicant_sex` | ✅ Yes | ✅ Yes |
| Date of Birth | `Guest_DOB` | `applicant_dob` | ✅ Yes | ✅ Yes |
| Nationality | `Guest_Nationality` | `applicant_nationality` | ✅ Yes | ✅ Yes |
| Father's Name | `Guest_Father` | `applicant_father` | ❌ No | ⚠️ Null |
| Mother's Name | `Guest_Mother` | `applicant_mother` | ❌ No | ⚠️ Null |
| Spouse Name | `Guest_Spouse` | `applicant_spouse` | ❌ No | ⚠️ Null |

### Section 2: Passport Details
| Form Field | API Field | JavaScript ID | Required | Available |
|------------|-----------|---------------|----------|-----------|
| Passport Number | `Guest_DocumentNo` | `applicant_passpno` | ✅ Yes | ✅ Yes |
| Place of Issue | `Guest_CountryofIssueTxt` | `applicant_passpplace` | ✅ Yes | ✅ Yes |
| Country of Issue | `Guest_CountryofIssue` | `applicant_passpcountry` | ✅ Yes | ✅ Yes |
| Date of Issue | `Guest_DateOfIssue` | `applicant_passpdoissue` | ✅ Yes | ✅ Yes |
| Date of Expiry | `Guest_ExpiryDate` | `applicant_passpvalidtill` | ✅ Yes | ✅ Yes |

### Section 3: Visa Details
| Form Field | API Field | JavaScript ID | Required | Available |
|------------|-----------|---------------|----------|-----------|
| Visa Number | `Guest_VisaNo` | `applicant_visano` | ✅ Yes | ✅ Yes |
| Visa Type | `Guest_VisaType` | `applicant_visatype` | ✅ Yes | ✅ Yes |
| Visa Subtype | `VisaSubTypeId` | `applicant_visasubtype` | ❌ No | ✅ Yes |
| Place of Issue | `Guest_VisaPOICity` | `applicant_visaplace` | ✅ Yes | ⚠️ Empty |
| Country of Issue | `Guest_VisaPOICountry` | `applicant_visacountry` | ✅ Yes | ✅ Yes |
| Date of Issue | `Guest_VisaDateofIssue` | `applicant_visadoissue` | ✅ Yes | ✅ Yes |
| Valid Till | `Guest_VisaValidTill` | `applicant_visavalidtill` | ✅ Yes | ✅ Yes |

### Section 4: Arrival in India
| Form Field | API Field | JavaScript ID | Required | Available |
|------------|-----------|---------------|----------|-----------|
| Date of Arrival | `DateOfArrivalInIndia` | `applicant_arrivaldate` | ✅ Yes | ✅ Yes |
| Arrived From (Country) | `ArrivedFromCountry` | `applicant_arrivedfrom_country` | ✅ Yes | ✅ Yes |
| Arrived From (City) | `ArrivedFromCity` | `applicant_arrivedfrom_city` | ✅ Yes | ✅ Yes |
| Arrived From (Place) | `ArrivedFromPlace` | `applicant_arrivedfrom_place` | ❌ No | ✅ Yes |

### Section 5: Arrival at Hotel
| Form Field | API Field | JavaScript ID | Required | Available |
|------------|-----------|---------------|----------|-----------|
| Date of Arrival | `Arrival_Date` | `applicant_hotelarrivaldate` | ✅ Yes | ✅ Yes |
| Time of Arrival | `Arrival_Time` | `applicant_hotelarrivaltime` | ❌ No | ✅ Yes |
| Intended Duration | `IntendedDurationStayIndividualHouse` | `applicant_duration` | ✅ Yes | ✅ Yes |

### Section 6: Next Destination
| Form Field | API Field | JavaScript ID | Required | Available |
|------------|-----------|---------------|----------|-----------|
| Next Destination Type | `NextDestination` | `applicant_nextdest_type` | ✅ Yes | ✅ Yes |
| State (if India) | `NextDestination_IN_State` | `applicant_nextdest_state` | ⚠️ Conditional | ⚠️ Empty |
| District (if India) | `NextDestination_IN_District` | `applicant_nextdest_district` | ⚠️ Conditional | ⚠️ Empty |
| Place (if India) | `NextDestination_IN_Place` | `applicant_nextdest_place` | ⚠️ Conditional | ⚠️ Empty |
| Country (if Outside) | `NextDestination_OUT_Country` | `applicant_nextdest_country` | ⚠️ Conditional | ⚠️ Empty |
| City (if Outside) | `NextDestination_OUT_City` | `applicant_nextdest_city` | ⚠️ Conditional | ⚠️ Empty |

### Section 7: Purpose of Visit
| Form Field | API Field | JavaScript ID | Required | Available |
|------------|-----------|---------------|----------|-----------|
| Purpose of Visit | `Guest_PurposeofVisit` | `applicant_purpose` | ✅ Yes | ✅ Yes |
| Special Category | `SpecialCategory` | `applicant_specialcategory` | ❌ No | ✅ Yes |

### Section 8: Contact Details
| Form Field | API Field | JavaScript ID | Required | Available |
|------------|-----------|---------------|----------|-----------|
| Phone Number | `Guest_PhoneNo` | `applicant_phone` | ✅ Yes | ⚠️ Empty |
| Mobile Number | `Guest_PhoneNo` | `applicant_mobile` | ✅ Yes | ⚠️ Empty |
| Email | `Guest_Email` | `applicant_email` | ❌ No | ⚠️ Empty |
| Address in India | `AddressInIndia` | `applicant_addressindia` | ✅ Yes | ⚠️ Null |

### Section 9: Employment Details
| Form Field | API Field | JavaScript ID | Required | Available |
|------------|-----------|---------------|----------|-----------|
| Employed in India | `EmployedInIndia_Yes_No` | `applicant_employed` | ❌ No | ⚠️ Empty |
| Company Name | `Company` | `applicant_company` | ⚠️ Conditional | ⚠️ Null |
| Designation | `Designation` | `applicant_designation` | ⚠️ Conditional | ⚠️ Null |

### Section 10: Contact Person in India
| Form Field | API Field | JavaScript ID | Required | Available |
|------------|-----------|---------------|----------|-----------|
| Contact Person | `GuestContactPersonToVisit` | `applicant_contactperson` | ❌ No | ⚠️ Null |
| Department | `GuestDepartmentToVisit` | `applicant_department` | ❌ No | ⚠️ Null |

## 📋 Field Availability Summary

### ✅ Fully Available (Can Auto-fill)
1. Surname
2. Given Name
3. Gender
4. Date of Birth
5. Nationality
6. Passport Number
7. Passport Place of Issue
8. Passport Country of Issue
9. Passport Date of Issue
10. Passport Expiry Date
11. Visa Number
12. Visa Type
13. Visa Subtype
14. Visa Country of Issue
15. Visa Date of Issue
16. Visa Valid Till
17. Date of Arrival in India
18. Arrived From Country
19. Arrived From City
20. Arrived From Place
21. Hotel Arrival Date
22. Hotel Arrival Time
23. Intended Duration
24. Next Destination Type
25. Purpose of Visit
26. Special Category

### ⚠️ Partially Available (Empty/Null but field exists)
1. Father's Name (null)
2. Mother's Name (null)
3. Spouse Name (null)
4. Visa Place of Issue (empty)
5. Phone Number (empty)
6. Email (empty)
7. Address in India (null)
8. Next Destination Details (empty)
9. Employment Details (null/empty)
10. Contact Person (null)

### ❌ Not Available in API
None - All FRRO fields have corresponding API fields

## 🎯 Auto-fill Strategy

### Priority 1: Critical Fields (Always fill)
- Personal details (name, DOB, gender, nationality)
- Passport details (number, issue/expiry dates, country)
- Visa details (number, type, dates, country)
- Arrival details (dates, from where)
- Purpose of visit

### Priority 2: Optional Fields (Fill if available)
- Contact details (phone, email)
- Next destination
- Employment details
- Contact person

### Priority 3: User Input Required
- Fields that are null/empty in API
- Fields that need verification
- Special cases

## 🔄 Data Transformation Rules

### Gender Mapping
- API: "Male" / "Female"
- Form: "M" / "F" / "X"
- Transform: Take first character and uppercase

### Date Format
- API: "DD/MM/YYYY"
- Form: "DD/MM/YYYY" (same format)
- No transformation needed

### Country Codes
- API: 3-letter codes (BRA, IND, USA)
- Form: 3-letter ISO codes
- No transformation needed

### Next Destination
- API: "I" (India) / "O" (Outside)
- Form: Dropdown selection
- Map: I → "Within India", O → "Outside India"

## 📝 Implementation Notes

1. **Null Handling**: Check for null/empty before filling
2. **Validation**: Validate dates and formats
3. **Fallbacks**: Provide defaults for missing data
4. **User Override**: Allow users to edit auto-filled data
5. **Highlighting**: Highlight fields that need user input
