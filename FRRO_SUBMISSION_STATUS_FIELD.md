# FRRO Submission Status Field

## Overview
A new field `frroSubmissionStatus` has been added to track FRRO form submission status independently from the existing `passToFRRO` field.

## New Field Details

### Field Name
- **Entity Field**: `frroSubmissionStatus`
- **API Field**: `FRRO_SubmissionStatus`
- **Type**: `int`
- **Default Value**: `0`

### Field Values
- `0` = **Not Submitted** - Guest has not submitted FRRO form yet
- `1` = **Submitted** - Guest has submitted FRRO form (detected on svnext.jsp or ext.jsp)

### Helper Method
```dart
bool get isFRROSubmitted => frroSubmissionStatus == 1;
```

## Existing Fields (Unchanged)

### passToFRRO
- **Purpose**: Indicates if guest data has been synced to backend
- **Values**: `0` = Not Synced, `1` = Synced
- **Helper**: `bool get isSyncedToFRRO => passToFRRO == 1;`

### isCheckOut
- **Purpose**: Indicates if guest has checked out
- **Values**: `0` = Not Checked Out, `1` = Checked Out
- **Helper**: `bool get isCheckedOut => isCheckOut == 1;`

## Status Display Logic

The guest list now shows different statuses based on these fields:

### Check-in Tab Status Badge

```dart
if (guest.isFRROSubmitted) {
  // Blue badge
  'FRRO Submitted' 
} else if (guest.isSyncedToFRRO) {
  // Green badge
  'Synced'
} else {
  // Orange badge
  'Pending'
}
```

### Visual Status Indicators

| Status | Badge Color | Text Color | Meaning |
|--------|-------------|------------|---------|
| **FRRO Submitted** | Light Blue (#E3F2FD) | Blue (#1976D2) | Form submitted on FRRO website |
| **Synced** | Light Green (#E6F9EE) | Green (#27AE60) | Data synced to backend |
| **Pending** | Light Orange (#FFF3E0) | Orange (#F57C00) | Not yet submitted |
| **Checked In** | Light Green (#E8F5E9) | Green (#27AE60) | Guest checked in (Check-out tab) |

## Status Flow

```
┌─────────────────┐
│  Guest Created  │
│  Status:        │
│  • Pending      │
│  • passToFRRO=0 │
│  • frroSubmission│
│    Status=0     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ FRRO Form       │
│ Submitted       │
│ Status:         │
│ • FRRO Submitted│
│ • passToFRRO=0  │
│ • frroSubmission│
│   Status=1      │ ← NEW STATUS
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Check-in Button │
│ Clicked         │
│ (API Called)    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Backend Synced  │
│ Status:         │
│ • Synced        │
│ • passToFRRO=1  │
│ • frroSubmission│
│   Status=1      │
└─────────────────┘
```

## Implementation Details

### 1. Guest Entity
**File**: `lib/features/frro/domain/entities/guest.dart`

```dart
class Guest extends Equatable {
  // ... existing fields ...
  final int passToFRRO;
  final int isCheckOut;
  final int frroSubmissionStatus; // NEW FIELD
  
  const Guest({
    // ... existing parameters ...
    required this.passToFRRO,
    required this.isCheckOut,
    this.frroSubmissionStatus = 0, // Default to 0
    // ... other parameters ...
  });
  
  // Helper methods
  bool get isSyncedToFRRO => passToFRRO == 1;
  bool get isCheckedOut => isCheckOut == 1;
  bool get isFRROSubmitted => frroSubmissionStatus == 1; // NEW HELPER
}
```

### 2. Guest Model
**File**: `lib/features/frro/data/models/guest_model.dart`

```dart
class GuestModel extends Guest {
  const GuestModel({
    // ... existing parameters ...
    required super.passToFRRO,
    required super.isCheckOut,
    super.frroSubmissionStatus = 0, // NEW PARAMETER
    // ... other parameters ...
  });

  factory GuestModel.fromJson(Map<String, dynamic> json) {
    return GuestModel(
      // ... existing mappings ...
      passToFRRO: json['Guest_PassToFRRO'] ?? 0,
      isCheckOut: json['IsCheckOut'] ?? 0,
      frroSubmissionStatus: json['FRRO_SubmissionStatus'] ?? 0, // NEW MAPPING
      // ... other mappings ...
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // ... existing mappings ...
      'Guest_PassToFRRO': passToFRRO,
      'IsCheckOut': isCheckOut,
      'FRRO_SubmissionStatus': frroSubmissionStatus, // NEW MAPPING
      // ... other mappings ...
    };
  }
}
```

### 3. Status Badge Widget
**File**: `lib/features/guest_management/presentation/pages/guest_list_page.dart`

```dart
class _StatusBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = isCheckOutTab
        ? ('Checked In', lightGreen, green)
        : guest.isFRROSubmitted                    // NEW CHECK (highest priority)
        ? ('FRRO Submitted', lightBlue, blue)
        : guest.isSyncedToFRRO
        ? ('Synced', lightGreen, green)
        : ('Pending', lightOrange, orange);
    
    // ... render badge ...
  }
}
```

## API Integration

### Backend Field
The backend should return this field in the guest list API response:

```json
{
  "Guestdata_id": 123,
  "Guest_Firstname": "John",
  "Guest_Lastname": "Doe",
  "Guest_PassToFRRO": 0,
  "IsCheckOut": 0,
  "FRRO_SubmissionStatus": 1,  // NEW FIELD
  // ... other fields ...
}
```

### When to Update This Field

The `FRRO_SubmissionStatus` should be set to `1` when:
1. User submits FRRO form on the website
2. Submission is detected (svnext.jsp or ext.jsp page loads)
3. User clicks Check-in button
4. `UpdateFRROStatusForChrome` API is called successfully

**Note**: The backend API should update this field when the check-in API is called.

## Benefits

### 1. Clear Status Tracking
- Users can see at a glance which guests have submitted FRRO forms
- Distinguishes between "submitted" and "synced to backend"

### 2. Better User Experience
- Visual feedback that submission was detected
- Clear indication of what action is needed next

### 3. Data Integrity
- Separate field means no confusion with existing `passToFRRO` field
- Backend can track submission independently from sync status

### 4. Workflow Clarity
```
Pending → FRRO Submitted → Synced
(Orange)   (Blue)          (Green)
```

## Migration Notes

### Existing Data
- All existing guests will have `frroSubmissionStatus = 0` by default
- No data migration needed
- Existing `passToFRRO` field remains unchanged

### Backward Compatibility
- The new field has a default value of `0`
- If backend doesn't return this field, it defaults to `0` (Not Submitted)
- App will continue to work with old API responses

## Testing Checklist

- [ ] Guest list displays "Pending" for new guests (frroSubmissionStatus=0)
- [ ] Guest list displays "FRRO Submitted" when frroSubmissionStatus=1
- [ ] Guest list displays "Synced" when passToFRRO=1 and frroSubmissionStatus=0
- [ ] Status badge colors are correct (Orange, Blue, Green)
- [ ] Check-out tab shows "Checked In" status
- [ ] API correctly sends FRRO_SubmissionStatus field
- [ ] Backend updates FRRO_SubmissionStatus when check-in API is called

## Related Files

- `lib/features/frro/domain/entities/guest.dart` - Guest entity with new field
- `lib/features/frro/data/models/guest_model.dart` - JSON serialization
- `lib/features/guest_management/presentation/pages/guest_list_page.dart` - Status badge display
- `lib/features/frro/presentation/pages/frro_list_page.dart` - Submission detection

## Future Enhancements

### Possible Additional Fields
- `frroApplicationId` - Store the extracted application ID
- `frroSubmissionDate` - Timestamp when form was submitted
- `frroSubmissionType` - "Temporary Save" or "Save and Continue"

### Enhanced Status Display
```dart
if (guest.isFRROSubmitted && guest.frroApplicationId.isNotEmpty) {
  'FRRO Submitted (${guest.frroApplicationId})'
} else if (guest.isFRROSubmitted) {
  'FRRO Submitted'
}
```
