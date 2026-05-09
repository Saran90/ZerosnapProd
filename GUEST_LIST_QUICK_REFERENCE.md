# Guest List Page - Quick Reference

## 🚀 What Changed?

**Removed**: All dummy data (4 hardcoded "John Vieita" guests)  
**Added**: Live API integration with real guest data

## 📱 How to Use

### View Guests
1. Open the app
2. Navigate to "Guest List" from dashboard
3. Guests automatically load from API (Branch ID: 5)

### Search Guests
- Type in the search bar
- Searches: Name, Nationality, Document Number
- Results filter in real-time

### Refresh Data
- Tap the refresh icon (↻) in the app bar
- Data reloads from API

### Handle Errors
- If loading fails, error screen appears
- Tap "Retry" button to try again

## 🎨 UI States

| State | What You See |
|-------|--------------|
| **Loading** | Spinning progress indicator |
| **Success** | List of guest cards |
| **Error** | Error icon + message + Retry button |
| **Empty** | "No guests found" message |
| **Search Empty** | "No matching guests" message |

## 🏷️ Sync Status Badges

| Badge | Color | Meaning |
|-------|-------|---------|
| **Synced** | 🟢 Green | Guest synced to FRRO |
| **Not Synced** | ⚪ Gray | Guest not yet synced |
| **Form-C** | 🟠 Orange | Guest checked out |

## 🔧 Configuration

### Change Branch ID
**File**: `lib/features/guest_management/presentation/pages/guest_list_page.dart`  
**Line**: ~15

```dart
..add(const LoadGuestList(branchId: YOUR_BRANCH_ID))
```

### Change API URL
**File**: `lib/features/frro/data/datasources/guest_remote_data_source.dart`  
**Line**: ~18

```dart
static const String baseUrl = 'YOUR_API_URL/api/';
```

## 🐛 Troubleshooting

### Problem: No guests showing
**Solutions**:
1. Check internet connection
2. Verify API is accessible
3. Check branch ID exists (default: 5)
4. Look at console for errors

### Problem: Loading forever
**Solutions**:
1. Check network connectivity
2. Verify API endpoint is correct
3. Check API server is running

### Problem: Search not working
**Solutions**:
1. Ensure guests are loaded first
2. Check search query is updating
3. Try clearing search and retyping

### Problem: Wrong sync status
**Solutions**:
1. Refresh the data
2. Check API response fields
3. Verify guest status in database

## 📊 Guest Card Fields

| Field | Source | Example |
|-------|--------|---------|
| **Name** | `firstName + lastName` | "RODRIGO FARIAS DOS SANTOS" |
| **Nationality** | `nationalityText` | "BRAZIL" |
| **Document** | Always "Passport" | "Passport" |
| **Date** | `arrivalDate` | "25/04/2026" |
| **Status** | Calculated from API | "Synced" / "Not Synced" / "Form-C" |

## 🔄 Refresh Methods

### Manual Refresh
Tap refresh icon in app bar

### Programmatic Refresh
```dart
context.read<GuestListBloc>().add(
  const RefreshGuestList(branchId: 5),
);
```

## 📝 API Details

**Endpoint**: `POST /api/GuestDataForChrome`  
**Base URL**: `http://smartcheckindev.atintellilabs.live/api/`  
**Request Body**:
```json
{
  "Guestdata_id": 0,
  "Branch_ID": 5,
  "User_ID": 0,
  "btnStatusOfCheckINOUT": 0
}
```

## 🎯 Key Features

✅ Real-time data from API  
✅ Loading indicators  
✅ Error handling with retry  
✅ Empty state messages  
✅ Search across multiple fields  
✅ Manual refresh  
✅ Accurate sync status  
✅ Clean architecture  
✅ BLoC state management  

## 📚 Related Files

### Main File
- `lib/features/guest_management/presentation/pages/guest_list_page.dart`

### Dependencies
- `lib/features/frro/domain/entities/guest.dart`
- `lib/features/frro/presentation/bloc/guest_list_bloc.dart`
- `lib/features/frro/data/datasources/guest_remote_data_source.dart`
- `lib/core/di/injection_container.dart`

### Documentation
- `GUEST_LIST_API_INTEGRATION.md` - Detailed changes
- `BEFORE_AFTER_COMPARISON.md` - Visual comparison
- `lib/features/frro/README.md` - FRRO feature docs

## ✨ Quick Tips

1. **First Time Setup**: Run `flutter pub get` to ensure dependencies
2. **Testing**: Use Branch ID 5 (has sample data)
3. **Debugging**: Check console logs for API responses
4. **Performance**: Search is client-side (fast)
5. **Offline**: Shows error with retry option

## 🎉 Success!

The Guest List page now displays real guests from your Smart Check-in API instead of dummy data!
