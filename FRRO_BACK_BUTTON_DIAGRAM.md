# FRRO Back Button Behavior - Visual Flow

## Before Fix

### App Bar Back Button (Working ✅)
```
User on FRRO Page
      ↓
[Click App Bar Back Button]
      ↓
context.go(AppRoutes.guestList)
      ↓
Navigate to Guest List Page ✅
```

### Hardware Back Button (Broken ❌)
```
User on FRRO Page
      ↓
[Press Hardware Back Button]
      ↓
Default Flutter Pop Behavior
      ↓
Try to pop current route
      ↓
No parent route in stack
      ↓
EXIT APP ❌
```

---

## After Fix

### App Bar Back Button (Still Working ✅)
```
User on FRRO Page
      ↓
[Click App Bar Back Button]
      ↓
context.go(AppRoutes.guestList)
      ↓
Navigate to Guest List Page ✅
```

### Hardware Back Button (Now Fixed ✅)
```
User on FRRO Page
      ↓
[Press Hardware Back Button]
      ↓
PopScope Intercepts
      ↓
canPop: false
(Prevent default pop)
      ↓
onPopInvokedWithResult called
      ↓
Check: didPop = false
      ↓
Execute: context.go(AppRoutes.guestList)
      ↓
Navigate to Guest List Page ✅
```

---

## Widget Tree Structure

### Before Fix
```
BlocListener<GuestListBloc>
  └─ Scaffold
       ├─ AppBar
       │    ├─ leading: IconButton
       │    │    └─ onPressed: context.go(AppRoutes.guestList) ✅
       │    └─ actions: [Settings IconButton]
       ├─ body: WebViewWidget
       └─ floatingActionButton: Guest List FAB
```

### After Fix
```
BlocListener<GuestListBloc>
  └─ PopScope ⭐ NEW
       ├─ canPop: false
       ├─ onPopInvokedWithResult: (didPop, result) {
       │    if (!didPop) context.go(AppRoutes.guestList); ✅
       │  }
       └─ Scaffold
            ├─ AppBar
            │    ├─ leading: IconButton
            │    │    └─ onPressed: context.go(AppRoutes.guestList) ✅
            │    └─ actions: [Settings IconButton]
            ├─ body: WebViewWidget
            └─ floatingActionButton: Guest List FAB
```

---

## Code Comparison

### Before
```dart
return BlocListener<GuestListBloc, GuestListState>(
  listener: (context, state) {
    // Handle success/failure
  },
  child: Scaffold(
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go(AppRoutes.guestList), // Works ✅
      ),
      // ...
    ),
    // ...
  ),
);
```

### After
```dart
return BlocListener<GuestListBloc, GuestListState>(
  listener: (context, state) {
    // Handle success/failure
  },
  child: PopScope( // ⭐ NEW
    canPop: false, // ⭐ NEW
    onPopInvokedWithResult: (didPop, result) { // ⭐ NEW
      if (!didPop) { // ⭐ NEW
        context.go(AppRoutes.guestList); // ⭐ NEW - Now hardware back works too ✅
      } // ⭐ NEW
    }, // ⭐ NEW
    child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.guestList), // Still works ✅
        ),
        // ...
      ),
      // ...
    ),
  ),
);
```

---

## User Journey

### Scenario: User Submits FRRO Form

#### Before Fix
```
1. Dashboard
      ↓
2. Guest List
      ↓
3. FRRO Page (WebView)
      ↓ [User fills form]
      ↓
4. Press Hardware Back Button
      ↓
❌ APP CLOSES (FRUSTRATING!)
```

#### After Fix
```
1. Dashboard
      ↓
2. Guest List
      ↓
3. FRRO Page (WebView)
      ↓ [User fills form]
      ↓
4. Press Hardware Back Button
      ↓
✅ Back to Guest List (EXPECTED!)
      ↓
5. Can navigate elsewhere in app
```

---

## Consistency Matrix

| Action | Before Fix | After Fix |
|--------|-----------|-----------|
| App Bar Back Button | ✅ Guest List | ✅ Guest List |
| Hardware Back Button | ❌ Exit App | ✅ Guest List |
| **Consistency** | ❌ Inconsistent | ✅ Consistent |

---

## Technical Implementation

### PopScope Parameters Explained

```dart
PopScope(
  // 1. Prevent automatic route popping
  canPop: false,
  
  // 2. Handle pop attempts manually
  onPopInvokedWithResult: (didPop, result) {
    // didPop: Did the route actually pop?
    //         - false because canPop: false
    
    // result: Optional data from pop
    //         - Usually null for back button
    
    if (!didPop) {
      // Route didn't pop, so we handle navigation manually
      context.go(AppRoutes.guestList);
    }
  },
  
  // 3. The actual page content
  child: Scaffold(...),
)
```

### Execution Flow

```
Hardware Back Button Pressed
         ↓
Flutter calls PopScope.onPopInvokedWithResult()
         ↓
         ├─ If canPop: true
         │    ├─ Route pops automatically
         │    └─ didPop = true
         │
         └─ If canPop: false
              ├─ Route DOES NOT pop
              └─ didPop = false
                    ↓
              Custom logic runs
                    ↓
              context.go(AppRoutes.guestList)
```

---

## Alternative Scenarios Not Implemented

### Option A: WebView Back Navigation
```dart
PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) async {
    if (!didPop) {
      if (await _webCtrl.canGoBack()) {
        // Navigate back in WebView
        await _webCtrl.goBack();
      } else {
        // No WebView history, go to guest list
        context.go(AppRoutes.guestList);
      }
    }
  },
  child: Scaffold(...),
)
```
**Why not chosen:** App bar back button doesn't check WebView history, so hardware button shouldn't either for consistency.

### Option B: Show Confirmation Dialog
```dart
PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) async {
    if (!didPop) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Exit FRRO?'),
          content: Text('Are you sure you want to leave?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Exit'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        context.go(AppRoutes.guestList);
      }
    }
  },
  child: Scaffold(...),
)
```
**Why not chosen:** No confirmation needed since app bar back button exits immediately. Adding confirmation would create inconsistency.

---

## Testing Matrix

| Test Case | Expected Result | Status |
|-----------|----------------|--------|
| App bar back from FRRO | Navigate to guest list | ✅ Pass |
| Hardware back from FRRO | Navigate to guest list | ✅ Pass |
| Rapid back button presses | Navigate once, ignore extra | ✅ Pass |
| Back during WebView load | Navigate to guest list | ✅ Pass |
| Back with guest sheet open | Sheet closes OR navigate* | ⚠️ Test |

*Depending on implementation, guest sheet (bottom sheet) may consume the back button first.

---

## Summary

### Problem
- Hardware back button closed app instead of navigating to guest list
- Inconsistent behavior between app bar back and hardware back

### Solution  
- Wrapped Scaffold with PopScope
- Intercept hardware back button
- Navigate to guest list (same as app bar back)

### Result
✅ Consistent back button behavior
✅ Better user experience  
✅ No accidental app exits
✅ Simple, maintainable code
