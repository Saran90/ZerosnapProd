# Simplified FRRO Status Logic

## Overview
The FRRO status now only shows **two states** based on local app tracking, ignoring the `Guest_PassToFRRO` API field.

---

## Status States (Simplified)

### 1. 🔵 FRRO Submitted (Blue)
**When:** Guest has submitted FRRO form (detected locally)

### 2. 🟠 Pending (Orange)
**When:** Guest has not submitted FRRO form yet

---

## Removed Status

### ❌ Synced to FRRO (Removed)
- No longer checks `Guest_PassToFRRO` field
- No longer shows "Synced to FRRO" status
- Simplified to only track local submission state

---

## Visual Examples

### Submitted Guest
```
┌────────────────────────────────────────────────┐
│  👤  Jane Smith          🔵 FRRO Submitted     │
│      India                       12/26/2024    │
│      Doc: P987654321                      ▼    │
│      ✓ Submitted to FRRO                       │
└────────────────────────────────────────────────┘
```
**Badge:** Blue (#1976D2)  
**Icon:** ✓ Check circle  
**Text:** "Submitted to FRRO"

---

### Not Submitted Guest
```
┌────────────────────────────────────────────────┐
│  👤  John Doe                    ⚠️ Pending    │
│      United States               12/25/2024    │
│      Doc: P123456789                      ▼    │
│      ⏳ Not submitted to FRRO                  │
└────────────────────────────────────────────────┘
```
**Badge:** Orange (#F57C00)  
**Icon:** ⏳ Pending  
**Text:** "Not submitted to FRRO"

---

## Status Logic

### Status Badge
```dart
final (label, bg, fg) = isCheckOutTab
    ? ('Checked In', green, green)
    : isFrroSubmittedLocally
    ? ('FRRO Submitted', blue, blue)
    : ('Pending', orange, orange);
```

### Status Text
```dart
Icon(
  widget.isFrroSubmittedLocally
      ? Icons.check_circle
      : Icons.pending_outlined,
  color: widget.isFrroSubmittedLocally ? blue : orange,
)

Text(
  widget.isFrroSubmittedLocally
      ? 'Submitted to FRRO'
      : 'Not submitted to FRRO',
)
```

---

## What Was Removed

### Before (3 States)
1. 🟢 Synced to FRRO (Green) - Based on `Guest_PassToFRRO == 1`
2. 🔵 FRRO Submitted (Blue) - Based on local state
3. 🟠 Pending (Orange) - Default

### After (2 States)
1. 🔵 FRRO Submitted (Blue) - Based on local state
2. 🟠 Pending (Orange) - Default

---

## Status Determination

### Only Checks Local State
```dart
isFrroSubmittedLocally = frroSubmittedIds.contains(guest.guestdataId)
```

**Set when:**
- FRRO form submission is detected (svnext.jsp or ext.jsp)
- `FrroSubmitted` event is dispatched
- Guest ID is added to `frroSubmittedIds` set

**Does NOT check:**
- ❌ `Guest_PassToFRRO` field from API
- ❌ Backend sync status
- ❌ Check-in API response

---

## Status Flow

```
1. Guest Created
   frroSubmittedIds = {}
   → Status: "Pending" (Orange)

2. Submit FRRO Form
   Submission detected
   frroSubmittedIds = {123}
   → Status: "Submitted to FRRO" (Blue)

3. Click Check-in Button
   API called (but status doesn't change)
   → Status: Still "Submitted to FRRO" (Blue)

4. App Restart
   frroSubmittedIds = {}  (state lost)
   → Status: Back to "Pending" (Orange)
```

---

## Persistence

### ✅ Persists Across:
- Page navigation (FRRO page ↔ Guest List page)
- Guest list refresh
- App running in background

### ❌ Does NOT Persist:
- App restart
- App force close
- Device reboot

**Reason:** Stored in memory (BLoC state), not in database

---

## Color Scheme

| Status | Badge BG | Badge Text | Icon | Text Color |
|--------|----------|------------|------|------------|
| **Submitted** | Light Blue (#E3F2FD) | Blue (#1976D2) | ✓ Blue | Blue (#1976D2) |
| **Pending** | Light Orange (#FFF3E0) | Orange (#F57C00) | ⏳ Orange | Gray (#757575) |

---

## Benefits of Simplification

### ✅ Clearer Logic
- Only two states to understand
- No confusion about "Synced" vs "Submitted"
- Easier to debug

### ✅ Consistent Behavior
- Status based purely on local detection
- No dependency on backend API field
- Predictable state changes

### ✅ Simpler Code
- Removed `guest.isSyncedToFRRO` checks
- Removed green "Synced" status
- Less conditional logic

---

## What Happens to Check-in API?

### API Still Works
- Check-in button still calls `UpdateFRROStatusForChrome`
- Backend still updates `Guest_PassToFRRO` to `1`
- API response still handled

### Just Not Shown in UI
- UI doesn't display "Synced" status
- UI only shows local submission state
- Backend sync status is tracked but not displayed

---

## Files Modified

| File | Change |
|------|--------|
| `lib/features/guest_management/presentation/pages/guest_list_page.dart` | Removed `guest.isSyncedToFRRO` checks |

**Lines Changed:** ~20 lines

---

## Summary

### Before
- 3 status states (Synced, Submitted, Pending)
- Checked both API field and local state
- Green/Blue/Orange colors

### After
- 2 status states (Submitted, Pending)
- Only checks local state
- Blue/Orange colors

### Result
✅ Simpler, clearer status logic  
✅ Only shows what the app detects locally  
✅ No dependency on backend API field
