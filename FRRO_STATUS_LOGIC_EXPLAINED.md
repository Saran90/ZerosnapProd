# FRRO Status Logic Explained

## Overview
The guest list shows different FRRO statuses based on specific conditions. Here's exactly what is checked for each status.

---

## Status Priority (Highest to Lowest)

### 1. 🟢 Synced to FRRO (Highest Priority)
### 2. 🔵 FRRO Submitted (Local)
### 3. 🟠 Pending (Default)

---

## Detailed Status Conditions

### 1. Synced to FRRO (Green)

**Condition:**
```dart
guest.isSyncedToFRRO == true
```

**Which checks:**
```dart
bool get isSyncedToFRRO => passToFRRO == 1;
```

**API Field:**
```json
{
  "Guest_PassToFRRO": 1
}
```

**What it means:**
- Guest data has been **synced to the backend** via the Check-in API
- The `UpdateFRROStatusForChrome` API was called successfully
- Backend has updated `Guest_PassToFRRO` field to `1`

**Visual:**
```
┌────────────────────────────────────────────────┐
│  👤  Bob Johnson                ✅ Synced       │
│      Canada                      12/27/2024    │
│      Doc: P456789123                      ▼    │
│      ☁️ Synced to FRRO                         │
└────────────────────────────────────────────────┘
```

**Badge:** Green (#27AE60)  
**Icon:** ☁️ `Icons.cloud_done`  
**Text:** "Synced to FRRO"

---

### 2. FRRO Submitted (Blue)

**Condition:**
```dart
isFrroSubmittedLocally == true
```

**Which checks:**
```dart
frroSubmittedIds.contains(guest.guestdataId)
```

**Where it's set:**
- When FRRO form submission is detected (svnext.jsp or ext.jsp)
- `FrroSubmitted` event is dispatched
- Guest ID is added to `frroSubmittedIds` set in BLoC state

**What it means:**
- Guest has **submitted FRRO form** on the website
- Submission was **detected locally** by the app
- **Not yet synced** to backend (Check-in button not clicked)

**Visual:**
```
┌────────────────────────────────────────────────┐
│  👤  Jane Smith          🔵 FRRO Submitted     │
│      India                       12/26/2024    │
│      Doc: P987654321                      ▼    │
│      ✓ Submitted to FRRO                       │
└────────────────────────────────────────────────┘
```

**Badge:** Blue (#1976D2)  
**Icon:** ✓ `Icons.check_circle`  
**Text:** "Submitted to FRRO"

---

### 3. Pending (Orange)

**Condition:**
```dart
// Default when neither of the above is true
!guest.isSyncedToFRRO && !isFrroSubmittedLocally
```

**What it means:**
- Guest has **not submitted** FRRO form yet
- No local submission detected
- No backend sync

**Visual:**
```
┌────────────────────────────────────────────────┐
│  👤  John Doe                    ⚠️ Pending    │
│      United States               12/25/2024    │
│      Doc: P123456789                      ▼    │
│      Not submitted to FRRO                     │
└────────────────────────────────────────────────┘
```

**Badge:** Orange (#F57C00)  
**Icon:** ⏳ `Icons.pending_outlined`  
**Text:** "Not submitted to FRRO"

---

## Status Logic Flow

### Code Implementation

**Status Badge:**
```dart
final (label, bg, fg) = isCheckOutTab
    ? ('Checked In', green, green)
    : isFrroSubmittedLocally              // Check local flag first
    ? ('FRRO Submitted', blue, blue)
    : guest.isSyncedToFRRO                // Then check API field
    ? ('Synced', green, green)
    : ('Pending', orange, orange);        // Default
```

**Status Text:**
```dart
Icon(
  widget.guest.isSyncedToFRRO           // Check API field first
      ? Icons.cloud_done
      : widget.isFrroSubmittedLocally   // Then check local flag
      ? Icons.check_circle
      : Icons.pending_outlined,
)

Text(
  widget.guest.isSyncedToFRRO
      ? 'Synced to FRRO'
      : widget.isFrroSubmittedLocally
      ? 'Submitted to FRRO'
      : 'Not submitted to FRRO',
)
```

---

## Data Sources

### 1. API Data (Backend)

**Field:** `Guest_PassToFRRO`  
**Type:** `int`  
**Values:** `0` or `1`  
**Source:** Backend database  
**Updated by:** `UpdateFRROStatusForChrome` API

**Example API Response:**
```json
{
  "Guestdata_id": 123,
  "Guest_Firstname": "John",
  "Guest_Lastname": "Doe",
  "Guest_PassToFRRO": 1,  ← This field
  "IsCheckOut": 0,
  ...
}
```

---

### 2. Local App State

**Field:** `frroSubmittedIds`  
**Type:** `Set<int>`  
**Values:** Set of guest IDs  
**Source:** App memory (BLoC state)  
**Updated by:** `FrroSubmitted` event

**Example State:**
```dart
GuestListLoaded(
  guests: [...],
  frroSubmittedIds: {123, 456, 789},  ← Guest IDs who submitted
)
```

---

## Status Transition Flow

### Complete Lifecycle

```
┌─────────────────────────────────────────────────┐
│ 1. Guest Created                                │
│    passToFRRO = 0                               │
│    frroSubmittedIds = {}                        │
│    Status: Pending (Orange)                     │
└────────┬────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────┐
│ 2. FRRO Form Submitted                          │
│    passToFRRO = 0                               │
│    frroSubmittedIds = {123}  ← Added            │
│    Status: FRRO Submitted (Blue)                │
└────────┬────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────┐
│ 3. Check-in Button Clicked                      │
│    API: UpdateFRROStatusForChrome called        │
└────────┬────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────┐
│ 4. Backend Updates                              │
│    passToFRRO = 1  ← Updated by API             │
│    frroSubmittedIds = {123}  (still there)      │
│    Status: Synced (Green)  ← Priority!          │
└─────────────────────────────────────────────────┘
```

---

## Priority Examples

### Example 1: Only Local Submission
```
passToFRRO = 0
frroSubmittedIds = {123}

Result: "FRRO Submitted" (Blue)
```

### Example 2: Only Backend Sync
```
passToFRRO = 1
frroSubmittedIds = {}

Result: "Synced" (Green)
```

### Example 3: Both Set (Priority Test)
```
passToFRRO = 1
frroSubmittedIds = {123}

Result: "Synced" (Green)  ← API field has priority in status text
       "FRRO Submitted" (Blue)  ← Local flag has priority in badge
```

**Note:** There's a slight inconsistency here. Let me check the exact priority...

---

## Actual Priority in Code

### Status Badge Priority
```dart
isFrroSubmittedLocally     // 1st check (local)
  ? 'FRRO Submitted'
  : guest.isSyncedToFRRO   // 2nd check (API)
  ? 'Synced'
  : 'Pending'
```

### Status Text Priority
```dart
widget.guest.isSyncedToFRRO     // 1st check (API)
  ? 'Synced to FRRO'
  : widget.isFrroSubmittedLocally  // 2nd check (local)
  ? 'Submitted to FRRO'
  : 'Not submitted to FRRO'
```

**Inconsistency Found!**
- Badge checks local flag first
- Text checks API field first

---

## When Backend Updates `Guest_PassToFRRO`

### API Call
```
POST /api/UpdateFRROStatusForChrome
```

**Request Body:**
```json
{
  "Guestdata_id": 123,
  "Branch_ID": 5,
  "ApplicationId": "FRRO-2024-001234",
  "User_ID": 0
}
```

**Backend Action:**
```sql
UPDATE Guests 
SET Guest_PassToFRRO = 1 
WHERE Guestdata_id = 123
```

**Response:**
```json
{
  "Status": 1,
  "Message": "Success"
}
```

---

## Summary Table

| Status | Badge | Text | API Field | Local State | Priority |
|--------|-------|------|-----------|-------------|----------|
| **Synced** | Green | "Synced to FRRO" | `passToFRRO = 1` | Any | Highest (in text) |
| **Submitted** | Blue | "Submitted to FRRO" | `passToFRRO = 0` | `{guestId}` | Highest (in badge) |
| **Pending** | Orange | "Not submitted" | `passToFRRO = 0` | `{}` | Default |

---

## Key Points

### ✅ "Synced to FRRO" Shows When:
1. **API field** `Guest_PassToFRRO` equals `1`
2. This is set by the backend when `UpdateFRROStatusForChrome` API is called
3. Indicates guest data is in the backend database

### ✅ "Submitted to FRRO" Shows When:
1. **Local state** `frroSubmittedIds` contains the guest ID
2. This is set by the app when FRRO submission is detected
3. Indicates form was submitted but not yet synced to backend

### ✅ "Not submitted to FRRO" Shows When:
1. Neither of the above conditions is true
2. Default state for new guests

---

## Debugging Checklist

### Guest Shows "Pending" but Should Show "Synced"
- [ ] Check API response: Is `Guest_PassToFRRO` equal to `1`?
- [ ] Check backend database: Is the field updated?
- [ ] Check API call: Did `UpdateFRROStatusForChrome` succeed?

### Guest Shows "Pending" but Should Show "Submitted"
- [ ] Check BLoC state: Is guest ID in `frroSubmittedIds`?
- [ ] Check if `FrroSubmitted` event was dispatched
- [ ] Check if submission URL was detected (svnext.jsp or ext.jsp)
- [ ] Check if shared BLoC is being used (not separate instances)

### Guest Shows "Submitted" but Should Show "Synced"
- [ ] Check if Check-in button was clicked
- [ ] Check if API call succeeded
- [ ] Check if guest list was refreshed after API call
- [ ] Check API response: `Status` should be `1`
