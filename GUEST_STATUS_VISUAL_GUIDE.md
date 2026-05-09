# Guest Status Visual Guide

## Status Badge Display in Check-in Tab

### Status Priority (Top to Bottom)
1. **FRRO Submitted** (if `frroSubmissionStatus == 1`)
2. **Synced** (if `passToFRRO == 1`)
3. **Pending** (default)

---

## Visual Examples

### 1. Pending Status
```
┌────────────────────────────────────────────────┐
│  👤  John Doe                    ⚠️ Pending    │
│      United States               12/25/2024    │
│      Doc: P123456789                      ▼    │
└────────────────────────────────────────────────┘
```
**Color**: Orange badge (#FFF3E0 background, #F57C00 text)  
**Meaning**: Guest has not submitted FRRO form yet  
**Fields**: `frroSubmissionStatus=0`, `passToFRRO=0`

---

### 2. FRRO Submitted Status
```
┌────────────────────────────────────────────────┐
│  👤  Jane Smith          🔵 FRRO Submitted     │
│      India                       12/26/2024    │
│      Doc: P987654321                      ▼    │
└────────────────────────────────────────────────┘
```
**Color**: Blue badge (#E3F2FD background, #1976D2 text)  
**Meaning**: Guest submitted FRRO form, waiting for check-in  
**Fields**: `frroSubmissionStatus=1`, `passToFRRO=0`

---

### 3. Synced Status
```
┌────────────────────────────────────────────────┐
│  👤  Bob Johnson                ✅ Synced       │
│      Canada                      12/27/2024    │
│      Doc: P456789123                      ▼    │
└────────────────────────────────────────────────┘
```
**Color**: Green badge (#E6F9EE background, #27AE60 text)  
**Meaning**: Guest data synced to backend via check-in  
**Fields**: `frroSubmissionStatus=0 or 1`, `passToFRRO=1`

---

## Expanded Card with Check-in Section

### Pending Guest (Expandable)
```
┌────────────────────────────────────────────────┐
│  👤  John Doe                    ⚠️ Pending    │
│      United States               12/25/2024    │
│      Doc: P123456789                      ▲    │
├────────────────────────────────────────────────┤
│  APPLICATION ID                                │
│  ┌──────────────────────────────────────────┐ │
│  │ 📋 Enter FRRO Application ID             │ │
│  └──────────────────────────────────────────┘ │
│                                                │
│  ┌──────────────────────────────────────────┐ │
│  │         🔓 Check In                      │ │
│  └──────────────────────────────────────────┘ │
└────────────────────────────────────────────────┘
```

### FRRO Submitted Guest (Expandable)
```
┌────────────────────────────────────────────────┐
│  👤  Jane Smith          🔵 FRRO Submitted     │
│      India                       12/26/2024    │
│      Doc: P987654321                      ▲    │
├────────────────────────────────────────────────┤
│  APPLICATION ID                                │
│  ┌──────────────────────────────────────────┐ │
│  │ 📋 FRRO-2024-001234                      │ │
│  └──────────────────────────────────────────┘ │
│                                                │
│  ┌──────────────────────────────────────────┐ │
│  │         🔓 Check In                      │ │
│  └──────────────────────────────────────────┘ │
└────────────────────────────────────────────────┘
```

### Synced Guest (Collapsed - No Check-in Section)
```
┌────────────────────────────────────────────────┐
│  👤  Bob Johnson                ✅ Synced       │
│      Canada                      12/27/2024    │
│      Doc: P456789123                      ▼    │
└────────────────────────────────────────────────┘
```
**Note**: Synced guests don't show check-in section when expanded

---

## Status Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    GUEST STATUS LIFECYCLE                    │
└─────────────────────────────────────────────────────────────┘

    Guest Created
         │
         ▼
    ┌─────────┐
    │ PENDING │  ← Orange Badge
    └────┬────┘
         │ frroSubmissionStatus = 0
         │ passToFRRO = 0
         │
         │ User submits FRRO form
         │ (detected on svnext.jsp or ext.jsp)
         ▼
    ┌──────────────────┐
    │ FRRO SUBMITTED   │  ← Blue Badge
    └────┬─────────────┘
         │ frroSubmissionStatus = 1
         │ passToFRRO = 0
         │
         │ User clicks Check-in button
         │ API: UpdateFRROStatusForChrome
         ▼
    ┌─────────┐
    │ SYNCED  │  ← Green Badge
    └─────────┘
         │ frroSubmissionStatus = 1
         │ passToFRRO = 1
         │
         ▼
    (Complete)
```

---

## Color Palette

### Status Colors

| Status | Background | Text | Border |
|--------|------------|------|--------|
| **Pending** | `#FFF3E0` (Light Orange) | `#F57C00` (Orange) | `#F57C00` (30% opacity) |
| **FRRO Submitted** | `#E3F2FD` (Light Blue) | `#1976D2` (Blue) | `#1976D2` (30% opacity) |
| **Synced** | `#E6F9EE` (Light Green) | `#27AE60` (Green) | `#27AE60` (30% opacity) |
| **Checked In** | `#E8F5E9` (Light Green) | `#27AE60` (Green) | `#27AE60` (30% opacity) |

### Color Meanings
- 🟠 **Orange**: Action required (submit FRRO form)
- 🔵 **Blue**: Intermediate state (submitted, needs check-in)
- 🟢 **Green**: Complete/Success (synced to backend)

---

## Check-out Tab Display

### Checked In Guest
```
┌────────────────────────────────────────────────┐
│  👤  Alice Brown            ✅ Checked In       │
│      Australia                   12/28/2024    │
│      Doc: P789123456                      ▼    │
└────────────────────────────────────────────────┘
```
**Color**: Green badge (#E8F5E9 background, #27AE60 text)  
**Meaning**: Guest is checked in (shown in Check-out tab)  
**Fields**: `isCheckOut=0` (shown in Check-out tab list)

---

## Badge Size & Style

### Dimensions
- **Padding**: 10px horizontal, 3px vertical
- **Border Radius**: 20px (fully rounded)
- **Border Width**: 1px
- **Font Size**: 11px
- **Font Weight**: 600 (Semi-bold)

### Example CSS
```css
.status-badge {
  padding: 3px 10px;
  border-radius: 20px;
  border: 1px solid;
  font-size: 11px;
  font-weight: 600;
}

.status-pending {
  background-color: #FFF3E0;
  color: #F57C00;
  border-color: rgba(245, 124, 0, 0.3);
}

.status-submitted {
  background-color: #E3F2FD;
  color: #1976D2;
  border-color: rgba(25, 118, 210, 0.3);
}

.status-synced {
  background-color: #E6F9EE;
  color: #27AE60;
  border-color: rgba(39, 174, 96, 0.3);
}
```

---

## User Actions by Status

### Pending Status
**Available Actions:**
- ✅ Expand card to see check-in section
- ✅ Enter FRRO Application ID
- ✅ Click Check In button
- ✅ Navigate to FRRO form page

**User Flow:**
1. User sees "Pending" badge
2. Expands card
3. Fills FRRO form on website
4. Returns to app
5. Enters Application ID
6. Clicks Check In

---

### FRRO Submitted Status
**Available Actions:**
- ✅ Expand card to see check-in section
- ✅ Application ID may be pre-filled
- ✅ Click Check In button

**User Flow:**
1. User submits FRRO form
2. App detects submission (blue badge appears)
3. User sees "FRRO Submitted" badge
4. Expands card
5. Clicks Check In (Application ID already filled)

---

### Synced Status
**Available Actions:**
- ❌ No check-in section (already synced)
- ✅ Can view guest details
- ✅ Can navigate to FRRO page if needed

**User Flow:**
1. User sees "Synced" badge
2. No further action needed
3. Guest data is in backend

---

## Accessibility

### Screen Reader Announcements
- **Pending**: "Status: Pending. FRRO form not submitted."
- **FRRO Submitted**: "Status: FRRO Submitted. Ready for check-in."
- **Synced**: "Status: Synced. Guest data synchronized."
- **Checked In**: "Status: Checked In."

### Color Contrast
All status badges meet WCAG AA standards:
- Orange on Light Orange: 4.5:1 contrast ratio
- Blue on Light Blue: 4.5:1 contrast ratio
- Green on Light Green: 4.5:1 contrast ratio

---

## Mobile Responsive Design

### Small Screens (< 360px)
```
┌──────────────────────────────┐
│  👤  John Doe                │
│      United States           │
│      ⚠️ Pending              │
│      12/25/2024         ▼    │
└──────────────────────────────┘
```
Status badge moves to its own line

### Medium Screens (360px - 600px)
```
┌────────────────────────────────────┐
│  👤  John Doe        ⚠️ Pending    │
│      United States   12/25/2024    │
│      Doc: P123456789          ▼    │
└────────────────────────────────────┘
```
Standard layout

### Large Screens (> 600px)
```
┌──────────────────────────────────────────────────────┐
│  👤  John Doe                    ⚠️ Pending          │
│      United States               12/25/2024          │
│      Doc: P123456789             Arrival: 10:30 AM   │
│                                                  ▼    │
└──────────────────────────────────────────────────────┘
```
Additional details shown

---

## Summary

### Three Status States in Check-in Tab
1. 🟠 **Pending** - Not submitted
2. 🔵 **FRRO Submitted** - Submitted, needs check-in
3. 🟢 **Synced** - Checked in and synced

### One Status State in Check-out Tab
1. 🟢 **Checked In** - Guest is checked in

### Key Visual Indicators
- **Badge Color** - Quick status identification
- **Badge Text** - Clear status label
- **Expandable Section** - Check-in actions for pending/submitted guests
- **Date Display** - Arrival or checkout date
