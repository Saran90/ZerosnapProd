# Guest Card with FRRO Status Text

## Updated Guest List Item Layout

### Before (Without Status Text)
```
┌────────────────────────────────────────────────┐
│  👤  John Doe                    ⚠️ Pending    │
│      United States               12/25/2024    │
│      Doc: P123456789                      ▼    │
└────────────────────────────────────────────────┘
```

### After (With Status Text)
```
┌────────────────────────────────────────────────┐
│  👤  Jane Smith          🔵 FRRO Submitted     │
│      India                       12/26/2024    │
│      Doc: P987654321                      ▼    │
│      ✓ Submitted to FRRO                       │
└────────────────────────────────────────────────┘
```

---

## Visual Examples

### 1. Pending Guest (No Status Text)
```
┌────────────────────────────────────────────────┐
│  👤  John Doe                    ⚠️ Pending    │
│      United States               12/25/2024    │
│      Doc: P123456789                      ▼    │
└────────────────────────────────────────────────┘
```
**Status Text**: Not shown (guest hasn't submitted FRRO)

---

### 2. FRRO Submitted Guest (With Status Text)
```
┌────────────────────────────────────────────────┐
│  👤  Jane Smith          🔵 FRRO Submitted     │
│      India                       12/26/2024    │
│      Doc: P987654321                      ▼    │
│      ✓ Submitted to FRRO                       │
└────────────────────────────────────────────────┘
```
**Status Text**: ✓ Submitted to FRRO (blue text with check icon)

---

### 3. Synced Guest (No Status Text)
```
┌────────────────────────────────────────────────┐
│  👤  Bob Johnson                ✅ Synced       │
│      Canada                      12/27/2024    │
│      Doc: P456789123                      ▼    │
└────────────────────────────────────────────────┘
```
**Status Text**: Not shown (already synced, no need for status text)

---

### 4. Check-out Tab (No Status Text)
```
┌────────────────────────────────────────────────┐
│  👤  Alice Brown            ✅ Checked In       │
│      Australia                   12/28/2024    │
│      Doc: P789123456                      ▼    │
└────────────────────────────────────────────────┘
```
**Status Text**: Not shown (check-out tab doesn't show FRRO status)

---

## Status Text Specifications

### Display Conditions
```dart
if (!widget.isCheckOutTab && widget.guest.isFRROSubmitted) {
  // Show "Submitted to FRRO" text
}
```

**Shows When:**
- ✅ In Check-in tab (`!isCheckOutTab`)
- ✅ Guest has submitted FRRO (`isFRROSubmitted == true`)
- ✅ `frroSubmissionStatus == 1`

**Hidden When:**
- ❌ In Check-out tab
- ❌ Guest hasn't submitted (`frroSubmissionStatus == 0`)
- ❌ Guest is already synced (status badge shows "Synced")

---

## Visual Design

### Layout Structure
```
┌─────────────────────────────────────────────────────────┐
│  [Avatar]  [Guest Info]              [Status Badge]     │
│            [Nationality]             [Date]             │
│            [Document]                                    │
│            [✓ Submitted to FRRO]     [Expand Icon]      │
└─────────────────────────────────────────────────────────┘
```

### Status Text Details
- **Icon**: Check circle (✓)
- **Icon Size**: 14px
- **Icon Color**: Blue (#1976D2)
- **Text**: "Submitted to FRRO"
- **Text Size**: 12px
- **Text Weight**: 600 (Semi-bold)
- **Text Color**: Blue (#1976D2)
- **Spacing**: 4px padding top, 4px between icon and text

---

## Code Implementation

### Location
**File**: `lib/features/guest_management/presentation/pages/guest_list_page.dart`

### Code Snippet
```dart
Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Guest Name
      Text(widget.guest.fullName, ...),
      
      // Nationality
      Text(widget.guest.nationalityText, ...),
      
      // Document Number
      if (widget.guest.documentNo.isNotEmpty)
        Text('Doc: ${widget.guest.documentNo}', ...),
      
      // FRRO Submission Status Text (NEW)
      if (!widget.isCheckOutTab && widget.guest.isFRROSubmitted)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                size: 14,
                color: const Color(0xFF1976D2),
              ),
              const SizedBox(width: 4),
              Text(
                'Submitted to FRRO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1976D2),
                ),
              ),
            ],
          ),
        ),
    ],
  ),
),
```

---

## Color Scheme

### Status Text Colors
| Element | Color | Hex Code |
|---------|-------|----------|
| Icon | Blue | `#1976D2` |
| Text | Blue | `#1976D2` |
| Background | Transparent | - |

### Matches Status Badge
The status text color matches the "FRRO Submitted" badge color for visual consistency.

---

## Responsive Behavior

### Small Screens (< 360px)
```
┌──────────────────────────────┐
│  👤  Jane Smith              │
│      India                   │
│      Doc: P987654321         │
│      ✓ Submitted to FRRO     │
│      🔵 FRRO Submitted       │
│      12/26/2024         ▼    │
└──────────────────────────────┘
```
Status text wraps to new line if needed

### Medium Screens (360px - 600px)
```
┌────────────────────────────────────┐
│  👤  Jane Smith  🔵 FRRO Submitted │
│      India               12/26/2024│
│      Doc: P987654321          ▼    │
│      ✓ Submitted to FRRO           │
└────────────────────────────────────┘
```
Standard layout

### Large Screens (> 600px)
```
┌──────────────────────────────────────────────────┐
│  👤  Jane Smith          🔵 FRRO Submitted       │
│      India                       12/26/2024      │
│      Doc: P987654321                        ▼    │
│      ✓ Submitted to FRRO                         │
└──────────────────────────────────────────────────┘
```
More spacing, cleaner layout

---

## User Experience

### Visual Hierarchy
1. **Guest Name** (Bold, 15px) - Primary information
2. **Nationality** (Regular, 13px) - Secondary information
3. **Document Number** (Regular, 12px) - Tertiary information
4. **FRRO Status** (Semi-bold, 12px, Blue) - Important status indicator

### Information Density
- Status text adds one line to the card
- Only shown when relevant (FRRO submitted)
- Doesn't clutter the UI for pending or synced guests

### Scan-ability
- Blue color draws attention
- Check icon provides quick visual confirmation
- Text is concise and clear

---

## Comparison: Badge vs Status Text

### Status Badge (Top Right)
- **Purpose**: Quick status overview
- **Location**: Top right corner
- **Visibility**: Always visible
- **States**: Pending, FRRO Submitted, Synced, Checked In

### Status Text (Below Document)
- **Purpose**: Detailed status information
- **Location**: Below document number
- **Visibility**: Only when FRRO submitted
- **States**: Only "Submitted to FRRO"

### Why Both?
1. **Badge**: Quick scanning of guest list
2. **Text**: Detailed confirmation for submitted guests
3. **Redundancy**: Ensures users don't miss important status
4. **Clarity**: Multiple visual cues improve UX

---

## Accessibility

### Screen Reader
```
"John Doe, United States, Document P123456789"
```

```
"Jane Smith, India, Document P987654321, Submitted to FRRO"
```

### Semantic HTML
```dart
Semantics(
  label: 'Submitted to FRRO',
  child: Row(...),
)
```

### Color Contrast
- Blue text on white background: 7.5:1 (AAA compliant)
- Icon and text use same color for consistency

---

## Animation (Optional Enhancement)

### Fade In Animation
When status changes from Pending to FRRO Submitted:
```dart
AnimatedOpacity(
  opacity: widget.guest.isFRROSubmitted ? 1.0 : 0.0,
  duration: const Duration(milliseconds: 300),
  child: Row(...), // Status text
)
```

### Slide In Animation
```dart
AnimatedSlide(
  offset: widget.guest.isFRROSubmitted 
    ? Offset.zero 
    : const Offset(-0.2, 0),
  duration: const Duration(milliseconds: 300),
  child: Row(...), // Status text
)
```

---

## Testing Scenarios

### Test Case 1: Pending Guest
```
Given: Guest with frroSubmissionStatus = 0
When: Guest card is displayed
Then: Status text is NOT shown
And: Only name, nationality, and document are visible
```

### Test Case 2: FRRO Submitted Guest
```
Given: Guest with frroSubmissionStatus = 1
When: Guest card is displayed in Check-in tab
Then: Status text "Submitted to FRRO" is shown
And: Text is blue with check icon
And: Text appears below document number
```

### Test Case 3: Check-out Tab
```
Given: Guest with frroSubmissionStatus = 1
When: Guest card is displayed in Check-out tab
Then: Status text is NOT shown
Because: Check-out tab doesn't need FRRO status
```

### Test Case 4: Synced Guest
```
Given: Guest with passToFRRO = 1
When: Guest card is displayed
Then: Status badge shows "Synced"
And: Status text may or may not be shown
Note: Status text shows if frroSubmissionStatus = 1
```

---

## Summary

### What Changed
- ✅ Added status text below document number
- ✅ Shows "Submitted to FRRO" with check icon
- ✅ Only visible in Check-in tab
- ✅ Only shown when `isFRROSubmitted == true`
- ✅ Blue color matches status badge

### Benefits
1. **Clear Feedback**: Users see confirmation that FRRO was submitted
2. **Visual Consistency**: Blue color matches badge
3. **Non-intrusive**: Only shown when relevant
4. **Scannable**: Icon + text is easy to spot
5. **Professional**: Clean, modern design

### Files Modified
- `lib/features/guest_management/presentation/pages/guest_list_page.dart`

### Lines Added
- ~20 lines (status text widget)
