# Quick Start Guide - FRRO Guest List API

## 🚀 Getting Started in 3 Steps

### Step 1: Install Dependencies
```bash
flutter pub get
```

### Step 2: Run the App
```bash
flutter run
```

### Step 3: Navigate to FRRO List
The FRRO list page will automatically load guests from the API.

## 📱 Using the Feature

### View Guest List
1. Navigate to the FRRO List page
2. Tap the floating action button (person icon) at the bottom right
3. A bottom sheet will appear with all guests from the API

### Select a Guest for FRRO Form
1. Open the guest list (tap FAB)
2. Tap on any guest card
3. The guest data will be auto-filled in the FRRO Form-C when you navigate to it

### Understanding Sync Status
- **Green "Synced"**: Guest data has been passed to FRRO
- **Gray "Not Synced"**: Guest not yet synced to FRRO
- **Orange "Form-C"**: Guest has checked out

## 🔧 Configuration

### Change Branch ID
Edit `lib/features/frro/presentation/pages/frro_list_page.dart`:
```dart
..add(const LoadGuestList(branchId: YOUR_BRANCH_ID))
```

### Change API Base URL
Edit `lib/features/frro/data/datasources/guest_remote_data_source.dart`:
```dart
static const String baseUrl = 'YOUR_API_URL/api/';
```

## 🐛 Troubleshooting

### No Guests Showing
- Check internet connection
- Verify the branch ID exists in the API
- Check console for error messages

### API Error
- Verify the API URL is correct
- Check if the API server is running
- Ensure the request format matches the API requirements

### Loading Forever
- Check network connectivity
- Verify API endpoint is accessible
- Check for CORS issues (if testing on web)

## 📊 API Details

**Endpoint**: `POST http://smartcheckindev.atintellilabs.live/api/GuestDataForChrome`

**Request**:
```json
{
  "Guestdata_id": 0,
  "Branch_ID": 5,
  "User_ID": 0,
  "btnStatusOfCheckINOUT": 0
}
```

**Response**: Array of guest objects

## 🎯 Key Files

- **Page**: `lib/features/frro/presentation/pages/frro_list_page.dart`
- **BLoC**: `lib/features/frro/presentation/bloc/guest_list_bloc.dart`
- **Entity**: `lib/features/frro/domain/entities/guest.dart`
- **API**: `lib/features/frro/data/datasources/guest_remote_data_source.dart`
- **DI**: `lib/core/di/injection_container.dart`

## ✅ Verification Checklist

- [ ] Dependencies installed (`flutter pub get`)
- [ ] No compilation errors (`flutter analyze`)
- [ ] App runs successfully (`flutter run`)
- [ ] Guest list loads from API
- [ ] Loading indicator appears while fetching
- [ ] Guest cards display correctly
- [ ] Sync status badges show correct colors
- [ ] Selecting a guest works
- [ ] Error messages appear when API fails

## 📚 Additional Resources

- Full documentation: `lib/features/frro/README.md`
- Integration summary: `FRRO_API_INTEGRATION_SUMMARY.md`
- Architecture details: See README files in each layer

## 🎉 You're Ready!

The FRRO guest list API is now fully integrated. Tap the FAB on the FRRO List page to see your guests!
