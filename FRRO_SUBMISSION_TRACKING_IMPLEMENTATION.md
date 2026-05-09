# FRRO Submission Tracking Implementation

## Overview
This document describes how FRRO submission tracking works in the application, ensuring that the `UpdateFRROStatusForChrome` API is only called when the user explicitly clicks the Check-in button.

## Key Requirements
1. ✅ **Automatic Detection**: Detect when FRRO form submission is successful (on svnext.jsp or ext.jsp pages)
2. ✅ **Extract Application ID**: Automatically extract the application ID from the submission page
3. ✅ **Manual API Call**: Only call the `UpdateFRROStatusForChrome` API when user clicks Check-in button
4. ✅ **Visual Feedback**: Show user that submission was detected and prompt them to check in

## Implementation Details

### 1. Submission Detection URLs
The system monitors for these FRRO submission confirmation pages:
- `https://indianfrro.gov.in/frro/FormC/svnext.jsp` - Temporary Save and Exit
- `https://indianfrro.gov.in/frro/FormC/ext.jsp` - Save and Continue (contains application ID)

### 2. State Management
**File**: `lib/features/frro/presentation/pages/frro_list_page.dart`

Added state variables to track submission:
```dart
String? _detectedApplicationId;  // Stores extracted application ID
bool _submissionDetected;         // Tracks if submission was detected
```

### 3. Automatic Tracking (No API Call)
**Method**: `_trackSubmission(String url, Guest guest)`

When a submission URL is detected:
1. Extracts application ID from ext.jsp page using JavaScript
2. Updates state with `_submissionDetected = true`
3. Stores the application ID in `_detectedApplicationId`
4. Shows a SnackBar notification to user
5. **Does NOT call the API**

```dart
Future<void> _trackSubmission(String url, Guest guest) async {
  String applicationId = '';
  
  if (url.toLowerCase().contains('/ext.jsp')) {
    // Extract application ID from page
    final result = await _webCtrl.runJavaScriptReturningResult(
      _extractApplicationIdScript,
    );
    applicationId = (result as String?)?.replaceAll('"', '').trim() ?? '';
  }
  
  setState(() {
    _submissionDetected = true;
    _detectedApplicationId = applicationId.isNotEmpty ? applicationId : null;
  });
  
  // Show notification to user
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        applicationId.isNotEmpty
            ? 'FRRO submission detected! Application ID: $applicationId\nClick Check-in to sync.'
            : 'FRRO submission detected! Click Check-in to sync.',
      ),
      // ...
    ),
  );
}
```

### 4. Manual Check-in Button
**Location**: Floating Action Button area

When submission is detected (`_submissionDetected == true`), a Check-in button appears:

```dart
FloatingActionButton.extended(
  onPressed: () {
    if (_selectedGuest != null) {
      // THIS is where the API is called - only on button click
      context.read<GuestListBloc>().add(
        CheckInGuest(
          guestdataId: _selectedGuest!.guestdataId,
          branchId: 5,
          applicationId: _detectedApplicationId ?? '',
        ),
      );
      
      // Reset tracking after check-in
      setState(() {
        _submissionDetected = false;
        _detectedApplicationId = null;
      });
    }
  },
  icon: const Icon(Icons.check_circle_outline),
  label: const Text('Check-in'),
)
```

### 5. API Call Flow
```
User submits FRRO form
    ↓
WebView navigates to svnext.jsp or ext.jsp
    ↓
_trackSubmission() detects submission
    ↓
Extract application ID (if on ext.jsp)
    ↓
Update state: _submissionDetected = true
    ↓
Show SnackBar notification
    ↓
Check-in button appears
    ↓
User clicks Check-in button
    ↓
CheckInGuest event dispatched
    ↓
GuestListBloc calls CheckInGuestUseCase
    ↓
API: POST UpdateFRROStatusForChrome
    ↓
Success/Failure feedback shown
```

## User Experience

### Before Submission
- User sees only the guest list button (small FAB)
- User can select a guest and fill FRRO form

### After Submission Detection
1. SnackBar appears: "FRRO submission detected! Application ID: XXX. Click Check-in to sync."
2. Check-in button appears (large extended FAB with green color)
3. Guest list button moves below Check-in button

### After Check-in Click
1. Button shows loading state: "Checking in..."
2. API is called with guest ID and application ID
3. Success: "FRRO submitted successfully" + guest list refreshes
4. Failure: "FRRO submission failed: [error message]"
5. Check-in button disappears, back to normal state

## Key Differences from Previous Implementation

### ❌ Old Behavior (Automatic API Call)
```dart
if (_isSubmissionUrl(lower)) {
  if (_selectedGuest != null) {
    await _handleSubmissionDetected(url, _selectedGuest!);  // Called API automatically
  }
  return;
}
```

### ✅ New Behavior (Manual API Call)
```dart
if (_isSubmissionUrl(lower)) {
  if (_selectedGuest != null) {
    await _trackSubmission(url, _selectedGuest!);  // Only tracks, no API call
  }
  return;
}

// API is called only when user clicks Check-in button
FloatingActionButton.extended(
  onPressed: () {
    context.read<GuestListBloc>().add(CheckInGuest(...));  // API called here
  },
  label: const Text('Check-in'),
)
```

## Benefits

1. **User Control**: User decides when to sync with backend
2. **Verification**: User can verify submission was successful before syncing
3. **Error Recovery**: If submission fails, user doesn't have incorrect data synced
4. **Transparency**: Clear visual feedback about what's happening
5. **Flexibility**: User can choose not to sync if needed

## Testing Checklist

- [ ] Submit FRRO form and verify SnackBar appears
- [ ] Verify application ID is extracted from ext.jsp page
- [ ] Verify Check-in button appears after submission
- [ ] Click Check-in and verify API is called
- [ ] Verify success message and guest list refresh
- [ ] Test with svnext.jsp (no application ID)
- [ ] Test error handling when API fails
- [ ] Verify button disappears after check-in

## Related Files

- `lib/features/frro/presentation/pages/frro_list_page.dart` - Main implementation
- `lib/features/frro/presentation/bloc/guest_list_bloc.dart` - BLoC handling CheckInGuest event
- `lib/features/frro/domain/usecases/check_in_guest.dart` - Use case for API call
- `lib/core/config/api_constants.dart` - API endpoint definition
