# Age Calculation Flow - Visual Guide

## 📊 Complete Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                     GUEST API RESPONSE                          │
│  POST http://smartcheckindev.atintellilabs.live/api/           │
│       GuestDataForChrome                                        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │  Guest_DOB      │
                    │  "15/03/1990"   │
                    └─────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              FLUTTER APP - Guest Entity                         │
│  lib/features/frro/domain/entities/guest.dart                   │
│                                                                  │
│  class Guest {                                                   │
│    final String dateOfBirth; // "15/03/1990"                    │
│  }                                                               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│         FRRO LIST PAGE - Form Fill Script                       │
│  lib/features/frro/presentation/pages/frro_list_page.dart       │
│                                                                  │
│  1. Set DOB field:                                               │
│     setVal('applicant_dob', '15/03/1990');                       │
│                                                                  │
│  2. Calculate Age:                                               │
│     var calculatedAge = calculateAge('15/03/1990');              │
│     // Returns: "36"                                             │
│                                                                  │
│  3. Set Age field:                                               │
│     ageField.value = "36";                                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              WEBVIEW - FRRO Form-C Website                       │
│  https://indianfrro.gov.in/frro/FormC                           │
│                                                                  │
│  Personal Details Section:                                       │
│  ┌────────────────────────────────────┐                         │
│  │ Date of Birth: [15/03/1990]       │                         │
│  │ Age:           [36]                │ ← Auto-calculated!      │
│  └────────────────────────────────────┘                         │
└─────────────────────────────────────────────────────────────────┘
```

## 🔄 Age Calculation Logic

```javascript
function calculateAge(dobString) {
  // Input: "15/03/1990" (DD/MM/YYYY)
  
  // Step 1: Parse the date
  var parts = dobString.split('/');
  var day = 15, month = 2 (March-1), year = 1990
  
  // Step 2: Create date objects
  var birthDate = new Date(1990, 2, 15);  // March 15, 1990
  var today = new Date();                  // April 26, 2026
  
  // Step 3: Calculate age
  var age = 2026 - 1990 = 36
  
  // Step 4: Adjust if birthday hasn't occurred
  // March 15 < April 26 → Birthday has passed
  // No adjustment needed
  
  // Output: "36"
  return "36";
}
```

## 📋 Field Selector Priority

The system tries these selectors in order:

```
1. document.getElementById('applicant_age')     ← Most common
2. document.getElementById('age')
3. document.getElementById('guest_age')
4. document.getElementById('personal_age')
5. document.querySelector('[name="applicant_age"]')
6. document.querySelector('[name="age"]')
7. document.querySelector('[name="guest_age"]')
```

**First match wins!**

## 🎯 Example Scenarios

### Scenario 1: Birthday Already Passed
```
DOB: 15/03/1990
Today: 26/04/2026
Age: 36 years ✅
```

### Scenario 2: Birthday Not Yet Occurred
```
DOB: 15/12/1990
Today: 26/04/2026
Age: 35 years ✅ (birthday in December)
```

### Scenario 3: Birthday Today
```
DOB: 26/04/1990
Today: 26/04/2026
Age: 36 years ✅
```

## 🔍 Console Output Examples

### ✅ Success Case
```
📅 Age calculated: 36 years (DOB: 15/03/1990)
✅ Age set successfully: 36 years (applicant_age)
```

### ⚠️ Field Not Found
```
📅 Age calculated: 36 years (DOB: 15/03/1990)
⚠️ Age field not found in form
```

### ℹ️ No DOB Available
```
// DOB not available, cannot calculate age
```

## 🧪 Testing Checklist

- [ ] Rebuild app: `flutter clean && flutter pub get && flutter run`
- [ ] Select guest with valid DOB
- [ ] Click "Fill FRRO Form"
- [ ] Open browser console (F12)
- [ ] Verify age calculation log
- [ ] Check age field in form
- [ ] Verify age matches calculation

## 📊 Integration Points

| Component | File | Purpose |
|-----------|------|---------|
| API Response | Guest API | Provides `Guest_DOB` |
| Entity | `guest.dart` | Stores `dateOfBirth` |
| Model | `guest_model.dart` | Maps API to entity |
| Form Fill | `frro_list_page.dart` | Calculates & sets age |
| WebView | FRRO Form-C | Displays age field |

## 🎉 Result

**Before**: Age field was empty, user had to calculate manually
**After**: Age field is automatically filled with accurate calculation
