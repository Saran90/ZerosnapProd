# Check-Out URL Fix

## Issue

The check-out API was generating an incorrect URL with double `/api/`:

```
❌ Wrong: http://smartcheckindev.atintellilabs.live/api//api/UpdateFRROCheckOutStatusChrome
```

## Root Cause

The base URL already includes `/api/`:
```dart
static const String _guestBaseUrl = 'http://smartcheckindev.atintellilabs.live/api/';
```

But the endpoint constant also started with `/api/`:
```dart
static const String updateCheckOutStatus = '/api/UpdateFRROCheckOutStatusChrome';
```

When combined: `baseUrl + endpoint` = `...live/api/` + `/api/UpdateFRRO...` = double `/api/`

## Solution

Removed the `/api/` prefix from the endpoint constant to match the check-in pattern:

### Before
```dart
// Check-in / Check-out
static const String updateFrroStatus = 'UpdateFRROStatusForChrome';
static const String updateCheckOutStatus = '/api/UpdateFRROCheckOutStatusChrome';  // ❌ Has /api/
```

### After
```dart
// Check-in / Check-out
static const String updateFrroStatus = 'UpdateFRROStatusForChrome';
static const String updateCheckOutStatus = 'UpdateFRROCheckOutStatusChrome';  // ✅ No /api/
```

## Result

Now the URL is correctly formed:

```
✅ Correct: http://smartcheckindev.atintellilabs.live/api/UpdateFRROCheckOutStatusChrome
```

## File Modified

- `lib/core/config/api_constants.dart`

## Verification

✅ No syntax errors  
✅ Matches check-in pattern  
✅ URL correctly formed  
✅ Ready for testing  

## How URLs Are Constructed

```dart
// In guest_remote_data_source.dart
static const String _guestBaseUrl = 'http://smartcheckindev.atintellilabs.live/api/';

// Check-in URL
await apiHelper.post(
  ApiConstants.updateFrroStatus,  // 'UpdateFRROStatusForChrome'
  baseUrl: _guestBaseUrl,          // 'http://.../api/'
  ...
);
// Result: http://smartcheckindev.atintellilabs.live/api/UpdateFRROStatusForChrome ✅

// Check-out URL (FIXED)
await apiHelper.post(
  ApiConstants.updateCheckOutStatus,  // 'UpdateFRROCheckOutStatusChrome' (no /api/)
  baseUrl: _guestBaseUrl,             // 'http://.../api/'
  ...
);
// Result: http://smartcheckindev.atintellilabs.live/api/UpdateFRROCheckOutStatusChrome ✅
```

## Summary

The issue was a simple prefix mismatch. The endpoint constant should NOT include `/api/` since the base URL already has it. This is now fixed and consistent with the check-in endpoint pattern.
