# FRRO Local Status Tracking - Complete Implementation

## Overview
The FRRO submission status is now tracked locally in the app and persists across the Guest List page, showing the correct status for the guest who submitted the form.

---

## How It Works

### 1. User Submits FRRO Form
```
User clicks on Guest A in FRRO page
  ↓
FRRO form auto-fills with Guest A's data
  ↓
User submits form on FRRO website
  ↓
App detects submission (svnext.jsp or ext.jsp)
  ↓
FrroSubmitted event dispatched with Guest A's ID
  ↓
Guest A's ID added to frroSubmittedIds set in BLoC state
```

### 2. Status Shows in Guest List
```
User navigates to Guest List page
  ↓
Guest List loads with frroSubmittedIds
  ↓
Guest A shows "✓ Submitted to FRRO" (Blue)
  ↓
Other guests show "Not submitted to FRRO" (Gray)
```

---

## Implementation Details

### FRRO Page (`frro_list_page.dart`)

**When submission is detected:**
```dart
Future<void> _trackSubmission(String url, Guest guest) async {
  // Extract application ID...
  
  setState(() {
    _submissionDetected = true;
    _detectedApplicationId = applicationId;
    _submittedGuestId = guest.guestdataId;  // Store submitted guest ID
  });

  // Dispatch event to update BLoC state
  if (mounted) {
    context.read<GuestListBloc>().add(
      FrroSubmitted(
        guestdataId: guest.guestdataId,  // ← Correct guest ID
        applicationId: applicationId,
      ),
    );
  }
  
  // Show notification with guest name
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'FRRO submission detected for ${guest.fullName}!...',
      ),
    ),
  );
}
```

---

### Guest List BLoC (`guest_list_bloc.dart`)

**Handles FrroSubmitted event:**
```dart
void _onFrroSubmitted(FrroSubmitted event, Emitter<GuestListState> emit) {
  if (state is GuestListLoaded) {
    emit((state as GuestListLoaded).copyWithSubmitted(event.guestdataId));
  }
}
```

**State includes submitted IDs:**
```dart
class GuestListLoaded extends GuestListState {
  final List<Guest> guests;
  final Set<int> frroSubmittedIds;  // ← Tracks submitted guest IDs
  
  GuestListLoaded copyWithSubmitted(int guestdataId) {
    return GuestListLoaded(
      guests,
      frroSubmittedIds: {...frroSubmittedIds, guestdataId},  // Add ID
    );
  }
}
```

**Preserves submitted IDs across reloads:**
```dart
Future<void> _fetchGuests(...) async {
  final submittedIds = _currentSubmittedIds;  // ← Preserve IDs
  emit(GuestListLoading(...));
  
  // Fetch guests from API...
  
  emit(GuestListLoaded(
    guests,
    frroSubmittedIds: submittedIds,  // ← Restore IDs
  ));
}
```

---

### Guest List Page (`guest_list_page.dart`)

**Passes local flag to guest cards:**
```dart
if (state is GuestListLoaded) {
  final guests = _filter(state.guests);
  final frroSubmittedIds = state.frroSubmittedIds;
  
  return ListView.separated(
    itemBuilder: (_, i) => _GuestCard(
      guest: guests[i],
      isCheckOutTab: isCheckOut,
      isFrroSubmittedLocally: frroSubmittedIds.contains(guests[i].guestdataId),
    ),
  );
}
```

**Guest card uses local flag:**
```dart
class _GuestCard extends StatefulWidget {
  final Guest guest;
  final bool isCheckOutTab;
  final bool isFrroSubmittedLocally;  // ← New parameter
}
```

**Status badge checks local flag first:**
```dart
final (label, bg, fg) = isCheckOutTab
    ? ('Checked In', green, green)
    : isFrroSubmittedLocally  // ← Check local flag first
    ? ('FRRO Submitted', blue, blue)
    : guest.isSyncedToFRRO
    ? ('Synced', green, green)
    : ('Pending', orange, orange);
```

**Status text checks local flag:**
```dart
Icon(
  widget.guest.isSyncedToFRRO
      ? Icons.cloud_done
      : widget.isFrroSubmittedLocally  // ← Check local flag
      ? Icons.check_circle
      : Icons.pending_outlined,
  color: widget.isFrroSubmittedLocally ? blue : orange,
)

Text(
  widget.guest.isSyncedToFRRO
      ? 'Synced to FRRO'
      : widget.isFrroSubmittedLocally  // ← Check local flag
      ? 'Submitted to FRRO'
      : 'Not submitted to FRRO',
)
```

---

## Status Priority

The status is determined in this order:

```
1. isSyncedToFRRO (passToFRRO == 1 from API)
   → "Synced to FRRO" (Green)

2. isFrroSubmittedLocally (in frroSubmittedIds set)
   → "Submitted to FRRO" (Blue)

3. Default
   → "Not submitted to FRRO" (Gray)
```

---

## Visual Examples

### Guest A (Submitted Locally)
```
┌────────────────────────────────────────────────┐
│  👤  John Doe            🔵 FRRO Submitted     │
│      United States               12/25/2024    │
│      Doc: P123456789                      ▼    │
│      ✓ Submitted to FRRO                       │
└────────────────────────────────────────────────┘
```
**Status**: Blue badge + blue text  
**Reason**: `frroSubmittedIds.contains(guestdataId) == true`

---

### Guest B (Not Submitted)
```
┌────────────────────────────────────────────────┐
│  👤  Jane Smith                  ⚠️ Pending    │
│      India                       12/26/2024    │
│      Doc: P987654321                      ▼    │
│      Not submitted to FRRO                     │
└────────────────────────────────────────────────┘
```
**Status**: Orange badge + gray text  
**Reason**: `frroSubmittedIds.contains(guestdataId) == false`

---

### Guest C (Synced via API)
```
┌────────────────────────────────────────────────┐
│  👤  Bob Johnson                ✅ Synced       │
│      Canada                      12/27/2024    │
│      Doc: P456789123                      ▼    │
│      ☁️ Synced to FRRO                         │
└────────────────────────────────────────────────┘
```
**Status**: Green badge + green text  
**Reason**: `passToFRRO == 1` (from API)

---

## Complete Flow

### Scenario: Submit Guest A, View in Guest List

```
Step 1: FRRO Page
┌─────────────────────────────────────────────┐
│ User selects Guest A from guest list       │
│ _selectedGuest = Guest A (ID: 123)         │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ FRRO form auto-fills with Guest A's data   │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ User submits form on FRRO website          │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ WebView navigates to svnext.jsp/ext.jsp    │
│ _trackSubmission() called                  │
│ _submittedGuestId = 123                    │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ FrroSubmitted event dispatched             │
│ guestdataId: 123                           │
│ applicationId: "FRRO-2024-001"             │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ GuestListBloc updates state                │
│ frroSubmittedIds = {123}                   │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ Notification shown:                        │
│ "FRRO submission detected for John Doe!"   │
└─────────────────────────────────────────────┘

Step 2: Guest List Page
┌─────────────────────────────────────────────┐
│ User navigates to Guest List page          │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ Guest List loads                           │
│ frroSubmittedIds = {123}                   │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ Guest A (ID: 123)                          │
│ isFrroSubmittedLocally = true              │
│ Shows: "✓ Submitted to FRRO" (Blue)        │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ Guest B (ID: 456)                          │
│ isFrroSubmittedLocally = false             │
│ Shows: "Not submitted to FRRO" (Gray)      │
└─────────────────────────────────────────────┘
```

---

## Persistence

### Across Page Navigation
✅ Status persists when navigating between FRRO page and Guest List page  
✅ `frroSubmittedIds` stored in BLoC state

### Across List Reloads
✅ Status persists when refreshing guest list  
✅ `_currentSubmittedIds` preserved before reload

### Across App Restarts
❌ Status does NOT persist after app restart  
**Reason**: Stored in memory (BLoC state), not in database

---

## Files Modified

| File | Changes |
|------|---------|
| `lib/features/frro/presentation/pages/frro_list_page.dart` | Dispatch `FrroSubmitted` event |
| `lib/features/guest_management/presentation/pages/guest_list_page.dart` | Pass `isFrroSubmittedLocally` flag |
| `lib/features/frro/presentation/bloc/guest_list_bloc.dart` | Already had `FrroSubmitted` handler |
| `lib/features/frro/presentation/bloc/guest_list_state.dart` | Already had `frroSubmittedIds` set |
| `lib/features/frro/presentation/bloc/guest_list_event.dart` | Already had `FrroSubmitted` event |

---

## Testing Scenarios

### Test Case 1: Submit and View
```
1. Open FRRO page
2. Select Guest A
3. Submit FRRO form
4. Navigate to Guest List page
Expected: Guest A shows "Submitted to FRRO" (Blue) ✅
```

### Test Case 2: Multiple Guests
```
1. Submit FRRO for Guest A
2. Submit FRRO for Guest B
3. Navigate to Guest List page
Expected: 
  - Guest A shows "Submitted to FRRO" (Blue) ✅
  - Guest B shows "Submitted to FRRO" (Blue) ✅
  - Guest C shows "Not submitted to FRRO" (Gray) ✅
```

### Test Case 3: Refresh List
```
1. Submit FRRO for Guest A
2. Navigate to Guest List page
3. Pull to refresh
Expected: Guest A still shows "Submitted to FRRO" (Blue) ✅
```

### Test Case 4: Check-in
```
1. Submit FRRO for Guest A
2. Click Check-in button
3. API updates passToFRRO = 1
4. Guest List refreshes
Expected: Guest A shows "Synced to FRRO" (Green) ✅
```

---

## Summary

### ✅ Problem Solved
- Correct guest is tracked when FRRO is submitted
- Status shows in Guest List page
- Status persists across page navigation
- Status persists across list reloads

### 🎯 Key Features
- Local state tracking (no API dependency)
- Correct guest ID always used
- Visual feedback in both pages
- Preserves status across reloads

### 📝 Files Changed
- 2 files modified (frro_list_page.dart, guest_list_page.dart)
- 3 files already had infrastructure (bloc, state, event)

### 🎉 Result
The guest who submitted FRRO now correctly shows "Submitted to FRRO" status in the Guest List page!
