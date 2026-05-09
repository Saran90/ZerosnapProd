# FRRO Guest ID Tracking Fix

## Problem Identified

### Issue
When submitting FRRO form for Guest A, but then selecting Guest B from the list before clicking Check-in, the system was updating Guest B instead of Guest A.

### Root Cause
The code was using `_selectedGuest` to determine which guest to check in, but `_selectedGuest` can change if the user selects a different guest from the list after submission.

```dart
// BEFORE (WRONG)
if (_selectedGuest != null) {
  context.read<GuestListBloc>().add(
    CheckInGuest(
      guestdataId: _selectedGuest!.guestdataId,  // ❌ Wrong guest!
      branchId: 5,
      applicationId: _detectedApplicationId ?? '',
    ),
  );
}
```

---

## Solution

### New Field Added
Added `_submittedGuestId` to track which specific guest submitted the FRRO form:

```dart
int? _submittedGuestId; // Track which guest was submitted
```

### Updated Tracking Logic
When submission is detected, store the submitted guest's ID:

```dart
Future<void> _trackSubmission(String url, Guest guest) async {
  // ... extract application ID ...
  
  setState(() {
    _submissionDetected = true;
    _detectedApplicationId = applicationId.isNotEmpty ? applicationId : null;
    _submittedGuestId = guest.guestdataId; // ✅ Store the submitted guest's ID
  });
  
  // Show notification with guest name
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'FRRO submission detected for ${guest.fullName}!\n...',
      ),
    ),
  );
}
```

### Updated Check-in Logic
Use the stored guest ID instead of current selection:

```dart
// AFTER (CORRECT)
if (_submittedGuestId != null) {
  context.read<GuestListBloc>().add(
    CheckInGuest(
      guestdataId: _submittedGuestId!,  // ✅ Correct guest!
      branchId: 5,
      applicationId: _detectedApplicationId ?? '',
    ),
  );
  
  // Reset tracking
  setState(() {
    _submissionDetected = false;
    _detectedApplicationId = null;
    _submittedGuestId = null;  // ✅ Clear the stored ID
  });
}
```

---

## How It Works Now

### Scenario: Submit Guest A, Then Select Guest B

```
1. User selects Guest A (ID: 123)
   _selectedGuest = Guest A
   _submittedGuestId = null

2. User submits FRRO form for Guest A
   Submission detected!
   _submittedGuestId = 123  ← Locked to Guest A
   _detectedApplicationId = "FRRO-2024-001"

3. User selects Guest B (ID: 456) from list
   _selectedGuest = Guest B  ← Changed!
   _submittedGuestId = 123   ← Still Guest A

4. User clicks Check-in button
   API called with guestdataId = 123  ← Correct! (Guest A)
   Not 456 (Guest B)
```

---

## Visual Flow

### Before Fix (Wrong Behavior)
```
┌─────────────────────────────────────────────────┐
│ 1. Select Guest A                               │
│    _selectedGuest = Guest A                     │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│ 2. Submit FRRO for Guest A                      │
│    _submissionDetected = true                   │
│    _selectedGuest = Guest A                     │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│ 3. Select Guest B from list                     │
│    _selectedGuest = Guest B  ❌ Changed!        │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│ 4. Click Check-in                               │
│    Uses _selectedGuest (Guest B)  ❌ WRONG!     │
│    Guest B gets updated instead of Guest A      │
└─────────────────────────────────────────────────┘
```

### After Fix (Correct Behavior)
```
┌─────────────────────────────────────────────────┐
│ 1. Select Guest A                               │
│    _selectedGuest = Guest A                     │
│    _submittedGuestId = null                     │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│ 2. Submit FRRO for Guest A                      │
│    _submissionDetected = true                   │
│    _submittedGuestId = 123  ✅ Locked!          │
│    _selectedGuest = Guest A                     │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│ 3. Select Guest B from list                     │
│    _selectedGuest = Guest B  (Changed)          │
│    _submittedGuestId = 123  ✅ Still Guest A!   │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│ 4. Click Check-in                               │
│    Uses _submittedGuestId (123)  ✅ CORRECT!    │
│    Guest A gets updated (as expected)           │
└─────────────────────────────────────────────────┘
```

---

## Improved User Feedback

### Notification Now Shows Guest Name
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(
      'FRRO submission detected for ${guest.fullName}!\n'
      'Application ID: $applicationId\n'
      'Click Check-in to sync.',
    ),
  ),
);
```

**Before:**
```
FRRO submission detected!
Application ID: FRRO-2024-001
Click Check-in to sync.
```

**After:**
```
FRRO submission detected for John Doe!
Application ID: FRRO-2024-001
Click Check-in to sync.
```

---

## State Management

### State Variables

| Variable | Type | Purpose |
|----------|------|---------|
| `_selectedGuest` | `Guest?` | Currently selected guest (can change) |
| `_submittedGuestId` | `int?` | ID of guest who submitted FRRO (locked) |
| `_submissionDetected` | `bool` | Whether submission was detected |
| `_detectedApplicationId` | `String?` | Extracted application ID |

### State Lifecycle

```
Initial State:
  _selectedGuest = null
  _submittedGuestId = null
  _submissionDetected = false
  _detectedApplicationId = null

After Guest Selection:
  _selectedGuest = Guest A
  _submittedGuestId = null
  _submissionDetected = false
  _detectedApplicationId = null

After FRRO Submission:
  _selectedGuest = Guest A
  _submittedGuestId = 123  ← Locked
  _submissionDetected = true
  _detectedApplicationId = "FRRO-2024-001"

After Selecting Different Guest:
  _selectedGuest = Guest B  ← Changed
  _submittedGuestId = 123  ← Still locked to Guest A
  _submissionDetected = true
  _detectedApplicationId = "FRRO-2024-001"

After Check-in:
  _selectedGuest = Guest B
  _submittedGuestId = null  ← Reset
  _submissionDetected = false  ← Reset
  _detectedApplicationId = null  ← Reset
```

---

## Testing Scenarios

### Test Case 1: Normal Flow (No Guest Change)
```
1. Select Guest A
2. Submit FRRO for Guest A
3. Click Check-in
Expected: Guest A is updated ✅
```

### Test Case 2: Guest Change After Submission
```
1. Select Guest A
2. Submit FRRO for Guest A
3. Select Guest B from list
4. Click Check-in
Expected: Guest A is updated (not Guest B) ✅
```

### Test Case 3: Multiple Submissions
```
1. Select Guest A
2. Submit FRRO for Guest A
3. Select Guest B
4. Submit FRRO for Guest B
Expected: _submittedGuestId updates to Guest B ✅
```

### Test Case 4: Check-in Resets State
```
1. Select Guest A
2. Submit FRRO for Guest A
3. Click Check-in
Expected: 
  - Guest A is updated ✅
  - _submittedGuestId = null ✅
  - Check-in button disappears ✅
```

---

## Code Changes Summary

### File Modified
`lib/features/frro/presentation/pages/frro_list_page.dart`

### Changes Made

1. **Added new state variable:**
   ```dart
   int? _submittedGuestId;
   ```

2. **Updated `_trackSubmission()` method:**
   ```dart
   _submittedGuestId = guest.guestdataId;
   ```

3. **Updated Check-in button condition:**
   ```dart
   if (_submissionDetected && _submittedGuestId != null)
   ```

4. **Updated Check-in button action:**
   ```dart
   guestdataId: _submittedGuestId!,
   ```

5. **Updated state reset:**
   ```dart
   _submittedGuestId = null;
   ```

6. **Improved notification message:**
   ```dart
   'FRRO submission detected for ${guest.fullName}!'
   ```

---

## Benefits

### ✅ Correct Guest Updated
- Always updates the guest who actually submitted the form
- No confusion about which guest is being checked in

### ✅ Better User Feedback
- Notification shows guest name
- User knows exactly which guest was detected

### ✅ Prevents Errors
- Can't accidentally update wrong guest
- Locked to submitted guest until check-in completes

### ✅ Flexible Workflow
- User can still browse other guests after submission
- Check-in button always refers to correct guest

---

## Summary

### Problem
Wrong guest was being updated when user changed selection after FRRO submission.

### Solution
Store the submitted guest's ID separately from the current selection.

### Result
Correct guest is always updated, regardless of what user selects after submission.

### Files Changed
- `lib/features/frro/presentation/pages/frro_list_page.dart` (~6 lines modified)
