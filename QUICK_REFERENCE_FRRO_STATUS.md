# Quick Reference: FRRO Status Field

## New Field

```dart
final int frroSubmissionStatus;  // 0 = Not Submitted, 1 = Submitted
```

## API Field Name

```json
"FRRO_SubmissionStatus": 0 or 1
```

## Helper Method

```dart
bool get isFRROSubmitted => frroSubmissionStatus == 1;
```

## Status Display (Check-in Tab)

| Condition | Badge Text | Color | Hex |
|-----------|------------|-------|-----|
| `isFRROSubmitted == true` | FRRO Submitted | 🔵 Blue | #1976D2 |
| `isSyncedToFRRO == true` | Synced | 🟢 Green | #27AE60 |
| Default | Pending | 🟠 Orange | #F57C00 |

## Status Flow

```
Pending → FRRO Submitted → Synced
(Orange)     (Blue)        (Green)
```

## Files Changed

1. `lib/features/frro/domain/entities/guest.dart`
2. `lib/features/frro/data/models/guest_model.dart`
3. `lib/features/guest_management/presentation/pages/guest_list_page.dart`

## Backend Action Required

Update `UpdateFRROStatusForChrome` API to set:
```sql
FRRO_SubmissionStatus = 1
```

## Testing

```dart
// Test 1: Pending
frroSubmissionStatus = 0, passToFRRO = 0 → "Pending" (Orange)

// Test 2: FRRO Submitted
frroSubmissionStatus = 1, passToFRRO = 0 → "FRRO Submitted" (Blue)

// Test 3: Synced
frroSubmissionStatus = 0, passToFRRO = 1 → "Synced" (Green)

// Test 4: Both set (priority test)
frroSubmissionStatus = 1, passToFRRO = 1 → "FRRO Submitted" (Blue)
```

## Backward Compatible

✅ Default value: `0`  
✅ Missing field handled gracefully  
✅ Existing fields unchanged  
✅ No migration needed
