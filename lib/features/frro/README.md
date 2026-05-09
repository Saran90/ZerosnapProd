# FRRO Guest List API Integration

## Overview
This module integrates the guest listing API from the Smart Check-in system into the Flutter app, following clean architecture principles.

## API Details

### Endpoint
```
POST http://smartcheckindev.atintellilabs.live/api/GuestDataForChrome
```

### Request Body
```json
{
  "Guestdata_id": 0,
  "Branch_ID": 5,
  "User_ID": 0,
  "btnStatusOfCheckINOUT": 0
}
```

### Response
Returns an array of guest objects with comprehensive guest information including:
- Personal details (name, DOB, gender, nationality)
- Document details (passport number, issue/expiry dates)
- Visa information
- Arrival/checkout dates and times
- FRRO sync status
- Profile picture (base64 encoded)

## Architecture

### Domain Layer
- **Entities**: `Guest` - Core business model
- **Repositories**: `GuestRepository` - Abstract repository interface
- **Use Cases**: `GetGuestList` - Business logic for fetching guests

### Data Layer
- **Models**: `GuestModel` - Data transfer object with JSON serialization
- **Data Sources**: `GuestRemoteDataSource` - API communication
- **Repository Implementation**: `GuestRepositoryImpl` - Concrete repository

### Presentation Layer
- **BLoC**: `GuestListBloc` - State management
  - Events: `LoadGuestList`, `RefreshGuestList`
  - States: `GuestListInitial`, `GuestListLoading`, `GuestListLoaded`, `GuestListError`
- **Pages**: `FrroListPage` - UI with WebView and guest list

## Features

### Guest List Display
- Fetches guests from API on page load
- Shows guest cards with:
  - Full name
  - Nationality
  - Document type
  - Arrival date
  - Sync status badge (Synced/Not Synced/Form-C)
- Loading indicator while fetching
- Error handling with user feedback

### FRRO Form Auto-fill
- Select a guest from the list
- WebView automatically fills FRRO Form-C with guest data:
  - Surname and given name
  - Passport number
  - Issue and expiry dates
  - Date of birth
  - Gender
  - Nationality

### Sync Status
- **Synced**: Guest data passed to FRRO (`Guest_PassToFRRO == 1`)
- **Not Synced**: Guest not yet synced to FRRO
- **Form-C**: Guest checked out (`IsCheckOut == 1`)

## Usage

### Basic Implementation
```dart
// The page automatically loads guests on initialization
BlocProvider(
  create: (_) => sl<GuestListBloc>()
    ..add(const LoadGuestList(branchId: 5)),
  child: const FrroListPage(),
)
```

### Refresh Guest List
```dart
context.read<GuestListBloc>().add(
  const RefreshGuestList(branchId: 5),
);
```

### Custom Branch ID
```dart
context.read<GuestListBloc>().add(
  const LoadGuestList(
    branchId: 10,
    userId: 123,
    btnStatusOfCheckINOUT: 1,
  ),
);
```

## Dependency Injection

All dependencies are registered in `lib/core/di/injection_container.dart`:

```dart
// Data sources
sl.registerLazySingleton<GuestRemoteDataSource>(
  () => GuestRemoteDataSourceImpl(apiHelper: sl()),
);

// Repositories
sl.registerLazySingleton<GuestRepository>(
  () => GuestRepositoryImpl(remoteDataSource: sl()),
);

// Use cases
sl.registerLazySingleton(() => GetGuestList(sl()));

// BLoC
sl.registerFactory(() => GuestListBloc(getGuestList: sl()));
```

## Error Handling

The implementation handles three types of errors:
1. **Network Errors**: No internet connection
2. **Server Errors**: API failures or invalid responses
3. **Validation Errors**: Invalid data format

Errors are displayed to users via SnackBar messages.

## Testing

### Unit Tests
Test the use case, repository, and data source independently:
```dart
test('should return list of guests when API call is successful', () async {
  // Arrange
  when(mockRemoteDataSource.getGuestList(branchId: 5))
    .thenAnswer((_) async => [testGuestModel]);
  
  // Act
  final result = await repository.getGuestList(branchId: 5);
  
  // Assert
  expect(result, Right([testGuest]));
});
```

### Widget Tests
Test the UI and BLoC integration:
```dart
testWidgets('should display guests when loaded', (tester) async {
  // Arrange
  when(mockBloc.state).thenReturn(GuestListLoaded([testGuest]));
  
  // Act
  await tester.pumpWidget(testWidget);
  
  // Assert
  expect(find.text('RODRIGO FARIAS DOS SANTOS'), findsOneWidget);
});
```

## Configuration

### Change Base URL
Update the base URL in `guest_remote_data_source.dart`:
```dart
static const String baseUrl = 'https://your-api-url.com/api/';
```

### Change Default Branch ID
Update the default branch ID in `frro_list_page.dart`:
```dart
..add(const LoadGuestList(branchId: YOUR_BRANCH_ID))
```

## Future Enhancements

1. **Caching**: Store guest data locally for offline access
2. **Search & Filter**: Add search by name, nationality, or date
3. **Sorting**: Sort by arrival date, name, or sync status
4. **Pull-to-Refresh**: Add swipe-down gesture to refresh list
5. **Pagination**: Load guests in batches for better performance
6. **Guest Details**: Show full guest information in a detail page
7. **Sync to FRRO**: Add button to sync selected guests to FRRO

## Dependencies

- `flutter_bloc`: State management
- `equatable`: Value equality
- `dartz`: Functional programming (Either type)
- `get_it`: Dependency injection
- `http`: HTTP client
- `webview_flutter`: WebView for FRRO form
