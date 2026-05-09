# Shared BLoC Fix - FRRO Status Now Persists!

## Problem Identified

### The Issue
When you submitted FRRO for a guest, the status didn't show in the Guest List page because **each page was creating its own BLoC instance**.

```
FRRO Page:
  BlocProvider(create: () => GuestListBloc())  ← Instance A
  
Guest List Page:
  BlocProvider(create: () => GuestListBloc())  ← Instance B
  
Result: Instance A and Instance B don't share state! ❌
```

---

## Solution

### Provide BLoC at App Level
Move the `GuestListBloc` to the app level so both pages share the same instance.

```
App Level:
  BlocProvider(create: () => GuestListBloc())  ← Single shared instance
  
FRRO Page:
  context.read<GuestListBloc>()  ← Uses shared instance
  
Guest List Page:
  context.read<GuestListBloc>()  ← Uses shared instance
  
Result: Both pages share the same state! ✅
```

---

## Implementation

### 1. Main App (`lib/main.dart`)

**Before:**
```dart
class ZerosnapApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<ThemeCubit>(
      create: (_) => sl<ThemeCubit>(),
      child: MaterialApp.router(...),
    );
  }
}
```

**After:**
```dart
class ZerosnapApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(
          create: (_) => sl<ThemeCubit>(),
        ),
        BlocProvider<GuestListBloc>(  // ← Added shared BLoC
          create: (_) => sl<GuestListBloc>(),
        ),
      ],
      child: MaterialApp.router(...),
    );
  }
}
```

---

### 2. FRRO Page (`lib/features/frro/presentation/pages/frro_list_page.dart`)

**Before:**
```dart
class FrroListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(  // ← Created new instance
      create: (_) => sl<GuestListBloc>()..add(LoadGuestList(...)),
      child: const _FrroListPageContent(),
    );
  }
}
```

**After:**
```dart
class FrroListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Use shared BLoC instance
    context.read<GuestListBloc>().add(const LoadGuestList(branchId: 5));
    return const _FrroListPageContent();
  }
}
```

---

### 3. Guest List Page (`lib/features/guest_management/presentation/pages/guest_list_page.dart`)

**Before:**
```dart
class GuestListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(  // ← Created new instance
      create: (_) => sl<GuestListBloc>()..add(LoadGuestList(...)),
      child: const _GuestListPageContent(),
    );
  }
}
```

**After:**
```dart
class GuestListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Use shared BLoC instance
    context.read<GuestListBloc>().add(
      const LoadGuestList(branchId: 5, btnStatusOfCheckINOUT: 0),
    );
    return const _GuestListPageContent();
  }
}
```

---

## How It Works Now

### Complete Flow

```
1. App Starts
   ↓
   GuestListBloc created at app level (single instance)

2. User Opens FRRO Page
   ↓
   FRRO page uses shared GuestListBloc
   ↓
   Loads guest list

3. User Selects Guest A
   ↓
   FRRO form fills with Guest A's data

4. User Submits FRRO Form
   ↓
   Submission detected
   ↓
   FrroSubmitted event dispatched to shared BLoC
   ↓
   Guest A's ID added to frroSubmittedIds set in shared BLoC

5. User Navigates to Guest List Page
   ↓
   Guest List page uses same shared GuestListBloc
   ↓
   frroSubmittedIds still contains Guest A's ID
   ↓
   Guest A shows "✓ Submitted to FRRO" (Blue) ✅
```

---

## State Sharing Diagram

### Before (Separate Instances)
```
┌─────────────────────────────────────────────┐
│  FRRO Page                                  │
│  ┌───────────────────────────────────────┐  │
│  │ GuestListBloc Instance A              │  │
│  │ frroSubmittedIds = {123}              │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│  Guest List Page                            │
│  ┌───────────────────────────────────────┐  │
│  │ GuestListBloc Instance B              │  │
│  │ frroSubmittedIds = {}  ❌ Empty!      │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

### After (Shared Instance)
```
┌─────────────────────────────────────────────┐
│  App Level                                  │
│  ┌───────────────────────────────────────┐  │
│  │ GuestListBloc (Shared)                │  │
│  │ frroSubmittedIds = {123}              │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
         ↑                    ↑
         │                    │
    ┌────┴────┐         ┌────┴────┐
    │ FRRO    │         │ Guest   │
    │ Page    │         │ List    │
    └─────────┘         └─────────┘
    Both use same instance ✅
```

---

## Benefits

### ✅ State Persists Across Pages
- FRRO submission status is maintained when navigating between pages
- Both pages see the same data

### ✅ Single Source of Truth
- Only one BLoC instance manages guest list state
- No synchronization issues

### ✅ Memory Efficient
- Only one BLoC instance instead of multiple
- Shared state reduces memory usage

### ✅ Consistent Behavior
- Both pages always show the same status
- No confusion about which guest is submitted

---

## Files Modified

| File | Change |
|------|--------|
| `lib/main.dart` | Added `GuestListBloc` to `MultiBlocProvider` |
| `lib/features/frro/presentation/pages/frro_list_page.dart` | Removed `BlocProvider`, use shared instance |
| `lib/features/guest_management/presentation/pages/guest_list_page.dart` | Removed `BlocProvider`, use shared instance |

---

## Testing

### Test Case 1: Submit and Navigate
```
1. Open FRRO page
2. Select Guest A
3. Submit FRRO form
4. See notification: "FRRO submission detected for Guest A!"
5. Navigate to Guest List page
Expected: Guest A shows "✓ Submitted to FRRO" (Blue) ✅
```

### Test Case 2: Multiple Submissions
```
1. Submit FRRO for Guest A
2. Navigate to Guest List
3. Verify Guest A shows "Submitted"
4. Navigate back to FRRO page
5. Submit FRRO for Guest B
6. Navigate to Guest List
Expected: 
  - Guest A shows "Submitted" ✅
  - Guest B shows "Submitted" ✅
```

### Test Case 3: Refresh List
```
1. Submit FRRO for Guest A
2. Navigate to Guest List
3. Pull to refresh
Expected: Guest A still shows "Submitted" ✅
```

---

## Important Notes

### BLoC Lifecycle
- The shared `GuestListBloc` is created when the app starts
- It persists for the entire app session
- State is maintained across page navigation
- State is lost when app is closed/restarted

### When State is Cleared
- App restart: State is lost (expected)
- Hot reload: State is preserved (development only)
- Check-in: Guest moves from "Submitted" to "Synced"

---

## Summary

### Problem
❌ Each page created its own BLoC instance  
❌ State didn't persist across pages  
❌ FRRO submission status not visible in Guest List  

### Solution
✅ Provide BLoC at app level  
✅ Both pages share same instance  
✅ State persists across navigation  

### Result
🎉 FRRO submission status now shows correctly in Guest List page!

---

## What You'll See Now

### After Submitting FRRO

**FRRO Page:**
```
Notification: "FRRO submission detected for John Doe!"
Check-in button appears
```

**Guest List Page:**
```
┌────────────────────────────────────────────────┐
│  👤  John Doe            🔵 FRRO Submitted     │
│      United States               12/25/2024    │
│      Doc: P123456789                      ▼    │
│      ✓ Submitted to FRRO                       │
└────────────────────────────────────────────────┘
```

The status is now visible! ✅
