# FRRO Status Text - Always Visible

## Overview
The FRRO status text now appears for **ALL guests** in the Check-in tab, showing their current submission status.

---

## Visual Examples

### 1. Not Submitted (Default State)
```
┌────────────────────────────────────────────────┐
│  👤  John Doe                    ⚠️ Pending    │
│      United States               12/25/2024    │
│      Doc: P123456789                      ▼    │
│      ⏳ Not submitted to FRRO                  │
└────────────────────────────────────────────────┘
```
**Icon**: ⏳ Pending (Orange)  
**Text**: "Not submitted to FRRO" (Gray)  
**When**: `frroSubmissionStatus = 0`, `passToFRRO = 0`

---

### 2. Submitted to FRRO
```
┌────────────────────────────────────────────────┐
│  👤  Jane Smith          🔵 FRRO Submitted     │
│      India                       12/26/2024    │
│      Doc: P987654321                      ▼    │
│      ✓ Submitted to FRRO                       │
└────────────────────────────────────────────────┘
```
**Icon**: ✓ Check circle (Blue)  
**Text**: "Submitted to FRRO" (Blue)  
**When**: `frroSubmissionStatus = 1`, `passToFRRO = 0`

---

### 3. Synced to FRRO
```
┌────────────────────────────────────────────────┐
│  👤  Bob Johnson                ✅ Synced       │
│      Canada                      12/27/2024    │
│      Doc: P456789123                      ▼    │
│      ☁️ Synced to FRRO                         │
└────────────────────────────────────────────────┘
```
**Icon**: ☁️ Cloud done (Green)  
**Text**: "Synced to FRRO" (Green)  
**When**: `passToFRRO = 1`

---

## Status Priority

The status text shows in this priority order:

```
1. isSyncedToFRRO (passToFRRO == 1)
   → "Synced to FRRO" (Green)

2. isFRROSubmitted (frroSubmissionStatus == 1)
   → "Submitted to FRRO" (Blue)

3. Default
   → "Not submitted to FRRO" (Gray)
```

---

## Color Scheme

| Status | Icon | Icon Color | Text | Text Color |
|--------|------|------------|------|------------|
| **Not Submitted** | `pending_outlined` | Orange (#F57C00) | "Not submitted to FRRO" | Gray (#757575) |
| **Submitted** | `check_circle` | Blue (#1976D2) | "Submitted to FRRO" | Blue (#1976D2) |
| **Synced** | `cloud_done` | Green (#27AE60) | "Synced to FRRO" | Green (#27AE60) |

---

## Display Logic

### Check-in Tab
✅ **Always shows status text** for all guests

### Check-out Tab
❌ **Never shows status text** (not relevant for checked-out guests)

---

## Code Implementation

```dart
// FRRO Submission Status Text - Always show in Check-in tab
if (!widget.isCheckOutTab)
  Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      children: [
        Icon(
          widget.guest.isSyncedToFRRO
              ? Icons.cloud_done
              : widget.guest.isFRROSubmitted
                  ? Icons.check_circle
                  : Icons.pending_outlined,
          size: 14,
          color: widget.guest.isSyncedToFRRO
              ? const Color(0xFF27AE60)
              : widget.guest.isFRROSubmitted
                  ? const Color(0xFF1976D2)
                  : const Color(0xFFF57C00),
        ),
        const SizedBox(width: 4),
        Text(
          widget.guest.isSyncedToFRRO
              ? 'Synced to FRRO'
              : widget.guest.isFRROSubmitted
                  ? 'Submitted to FRRO'
                  : 'Not submitted to FRRO',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: widget.guest.isSyncedToFRRO
                ? const Color(0xFF27AE60)
                : widget.guest.isFRROSubmitted
                    ? const Color(0xFF1976D2)
                    : Colors.grey[600],
          ),
        ),
      ],
    ),
  ),
```

---

## Complete Guest List View

### Check-in Tab
```
┌────────────────────────────────────────────────┐
│  👤  John Doe                    ⚠️ Pending    │
│      United States               12/25/2024    │
│      Doc: P123456789                      ▼    │
│      ⏳ Not submitted to FRRO                  │
└────────────────────────────────────────────────┘

┌────────────────────────────────────────────────┐
│  👤  Jane Smith          🔵 FRRO Submitted     │
│      India                       12/26/2024    │
│      Doc: P987654321                      ▼    │
│      ✓ Submitted to FRRO                       │
└────────────────────────────────────────────────┘

┌────────────────────────────────────────────────┐
│  👤  Bob Johnson                ✅ Synced       │
│      Canada                      12/27/2024    │
│      Doc: P456789123                      ▼    │
│      ☁️ Synced to FRRO                         │
└────────────────────────────────────────────────┘
```

---

## Benefits

### ✅ Always Visible
- Users can see FRRO status for every guest
- No need to expand cards or check badges
- Clear at-a-glance information

### ✅ Color-Coded
- Orange: Action needed (not submitted)
- Blue: In progress (submitted, needs check-in)
- Green: Complete (synced)

### ✅ Consistent
- Same information as status badge
- Reinforces status with text + icon
- Easy to understand

---

## User Experience

### What Users See Now

**Before (No Status Text):**
- Only badge shows status
- Need to understand badge colors
- Less explicit information

**After (With Status Text):**
- Badge + text both show status
- Clear text explanation
- Icon reinforces meaning
- Visible for all guests

---

## Testing

### Test Case 1: New Guest
```
Given: Guest with frroSubmissionStatus = 0, passToFRRO = 0
When: Guest list loads
Then: Shows "⏳ Not submitted to FRRO" (Gray)
```

### Test Case 2: Submitted Guest
```
Given: Guest with frroSubmissionStatus = 1, passToFRRO = 0
When: Guest list loads
Then: Shows "✓ Submitted to FRRO" (Blue)
```

### Test Case 3: Synced Guest
```
Given: Guest with passToFRRO = 1
When: Guest list loads
Then: Shows "☁️ Synced to FRRO" (Green)
```

### Test Case 4: Check-out Tab
```
Given: Any guest in Check-out tab
When: Guest list loads
Then: Status text is NOT shown
```

---

## Summary

### Changes Made
✅ Status text now shows for **ALL guests** in Check-in tab  
✅ Three status states: Not Submitted, Submitted, Synced  
✅ Color-coded icons and text  
✅ Always visible (no need to expand)  

### Files Modified
- `lib/features/guest_management/presentation/pages/guest_list_page.dart`

### What You'll See
- Every guest in Check-in tab shows their FRRO submission status
- Clear text with matching icon
- Color indicates status (Orange/Blue/Green)
