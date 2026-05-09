# FRRO Check-in Flow Diagram

## Visual Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    FRRO SUBMISSION TRACKING                      │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────┐
│  User Actions    │
└────────┬─────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 1. User selects guest from guest list                           │
└────────┬─────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. FRRO form auto-fills with guest data                         │
└────────┬─────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. User submits form on FRRO website                            │
│    (clicks "Save and Continue" or "Temporary Save and Exit")    │
└────────┬─────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. WebView navigates to submission page                         │
│    • svnext.jsp (Temporary Save)                                │
│    • ext.jsp (Save and Continue - has Application ID)           │
└────────┬─────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. _trackSubmission() AUTOMATICALLY DETECTS submission          │
│    ✓ Extracts Application ID (if on ext.jsp)                    │
│    ✓ Sets _submissionDetected = true                            │
│    ✓ Stores _detectedApplicationId                              │
│    ✗ DOES NOT CALL API                                          │
└────────┬─────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 6. SnackBar notification appears                                │
│    "FRRO submission detected! Application ID: XXX               │
│     Click Check-in to sync."                                    │
└────────┬─────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 7. Check-in button appears (green extended FAB)                 │
│    [✓ Check-in]  ← User must click this                         │
└────────┬─────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 8. User clicks Check-in button                                  │
└────────┬─────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 9. CheckInGuest event dispatched to BLoC                        │
│    • guestdataId: selected guest ID                             │
│    • branchId: 5                                                │
│    • applicationId: detected application ID (or "")             │
└────────┬─────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 10. API CALL: POST UpdateFRROStatusForChrome                    │
│     ← THIS IS THE ONLY TIME API IS CALLED                       │
└────────┬─────────────────────────────────────────────────────────┘
         │
         ├─────────────────┬─────────────────┐
         ▼                 ▼                 ▼
    ┌─────────┐      ┌─────────┐      ┌─────────┐
    │ Success │      │ Failure │      │ Loading │
    └────┬────┘      └────┬────┘      └────┬────┘
         │                │                │
         ▼                ▼                ▼
┌─────────────────────────────────────────────────────────────────┐
│ 11. Feedback to user                                            │
│     Success: "FRRO submitted successfully" (green)              │
│     Failure: "FRRO submission failed: [error]" (red)            │
│     Loading: "Checking in..." (button disabled)                 │
└────────┬─────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 12. Reset state & refresh guest list                            │
│     • _submissionDetected = false                               │
│     • _detectedApplicationId = null                             │
│     • Check-in button disappears                                │
│     • Guest list reloads with updated status                    │
└─────────────────────────────────────────────────────────────────┘
```

## State Transitions

```
┌─────────────────┐
│  Initial State  │
│  • No guest     │
│  • No detection │
└────────┬────────┘
         │ User selects guest
         ▼
┌─────────────────┐
│  Guest Selected │
│  • Form fills   │
│  • No detection │
└────────┬────────┘
         │ Form submitted
         ▼
┌─────────────────┐
│ Submission      │
│ Detected        │
│ • Show SnackBar │
│ • Show Check-in │
│   button        │
└────────┬────────┘
         │ User clicks Check-in
         ▼
┌─────────────────┐
│ Checking In     │
│ • API call      │
│ • Loading state │
└────────┬────────┘
         │ API response
         ▼
┌─────────────────┐
│ Complete        │
│ • Show result   │
│ • Reset state   │
│ • Refresh list  │
└─────────────────┘
```

## UI States

### State 1: Normal (No Submission)
```
┌──────────────────────────────────┐
│  FRRO Guest List            ⚙️   │
├──────────────────────────────────┤
│                                  │
│  [WebView showing FRRO form]     │
│                                  │
│                                  │
│                            👥    │ ← Guest list button only
└──────────────────────────────────┘
```

### State 2: Submission Detected
```
┌──────────────────────────────────┐
│  FRRO Guest List            ⚙️   │
├──────────────────────────────────┤
│  ┌────────────────────────────┐  │
│  │ 📸 FRRO submission detected│  │ ← SnackBar notification
│  │ Application ID: FRRO-2024  │  │
│  │ Click Check-in to sync.    │  │
│  └────────────────────────────┘  │
│                                  │
│  [WebView showing confirmation]  │
│                                  │
│                  ✓ Check-in      │ ← Check-in button (green)
│                            👥    │ ← Guest list button
└──────────────────────────────────┘
```

### State 3: Checking In
```
┌──────────────────────────────────┐
│  FRRO Guest List            ⚙️   │
├──────────────────────────────────┤
│                                  │
│  [WebView showing confirmation]  │
│                                  │
│                                  │
│              ⏳ Checking in...   │ ← Loading state
│                            👥    │
└──────────────────────────────────┘
```

### State 4: Success
```
┌──────────────────────────────────┐
│  FRRO Guest List            ⚙️   │
├──────────────────────────────────┤
│  ┌────────────────────────────┐  │
│  │ ✅ FRRO submitted          │  │ ← Success message
│  │    successfully            │  │
│  └────────────────────────────┘  │
│                                  │
│  [WebView - guest list refreshed]│
│                                  │
│                            👥    │ ← Back to normal
└──────────────────────────────────┘
```

## Key Points

### ✅ What Happens Automatically
- Submission detection on svnext.jsp and ext.jsp
- Application ID extraction from ext.jsp
- SnackBar notification
- Check-in button appearance

### 🔘 What Requires User Action
- **Clicking the Check-in button** ← THIS IS THE ONLY WAY API IS CALLED
- Selecting a guest from the list
- Submitting the FRRO form

### 🚫 What Does NOT Happen Automatically
- **API call to UpdateFRROStatusForChrome** ← NEVER automatic
- Guest list refresh (only after successful check-in)
- State reset (only after check-in attempt)

## Code Locations

| Component | File | Line/Method |
|-----------|------|-------------|
| Submission Detection | `frro_list_page.dart` | `_trackSubmission()` |
| Check-in Button | `frro_list_page.dart` | `FloatingActionButton.extended` |
| API Call Trigger | `frro_list_page.dart` | `CheckInGuest` event dispatch |
| API Implementation | `guest_list_bloc.dart` | `_onCheckInGuest()` |
| API Endpoint | `api_constants.dart` | `updateFrroStatus` |
