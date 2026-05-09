# FRRO Check-Out API Integration

## Summary

Successfully integrated the FRRO Check-Out API into the application. The check-out functionality follows the same architecture pattern as the existing check-in feature.

---

## API Details

**Endpoint**: `POST /api/UpdateFRROCheckOutStatusChrome`

**Base URL**: `http://smartcheckindev.atintellilabs.live`

**Request Body**:
```json
{
  "Guestdata_id": 191,
  "Branch_ID": 5,
  "User_ID": 10
}
```

**Response**: 
```json
{
  "Status": 1  // 1 = success, 0 = failure
}
```

---

## Implementation Details

### 1. API Constants
**File**: `lib/core/config/api_constants.dart`

Added:
```dart
static const String updateCheckOutStatus = '/api/UpdateFRROCheckOutStatusChrome';
```

---

### 2. Domain Layer

#### Repository Interface
**File**: `lib/features/frro/domain/repositories/guest_repository.dart`

Added method:
```dart
Future<Either<Failure, bool>> checkOut({
  required int guestdataId,
  required int branchId,
  int userId = 0,
});
```

#### Use Case
**File**: `lib/features/frro/domain/usecases/check_out_guest.dart` (NEW)

```dart
class CheckOutGuestUseCase {
  final GuestRepository repository;
  CheckOutGuestUseCase(this.repository);

  Future<Either<Failure, bool>> call({
    required int guestdataId,
    required int branchId,
    int userId = 0,
  }) => repository.checkOut(
    guestdataId: guestdataId,
    branchId: branchId,
    userId: userId,
  );
}
```

---

### 3. Data Layer

#### Remote Data Source Interface
**File**: `lib/features/frro/data/datasources/guest_remote_data_source.dart`

Added method:
```dart
Future<bool> checkOut({
  required int guestdataId,
  required int branchId,
  int userId = 0,
});
```

#### Remote Data Source Implementation
**File**: `lib/features/frro/data/datasources/guest_remote_data_source.dart`

```dart
@override
Future<bool> checkOut({
  required int guestdataId,
  required int branchId,
  int userId = 0,
}) async {
  try {
    final token = await _token;
    final response = await apiHelper.post(
      ApiConstants.updateCheckOutStatus,
      baseUrl: _guestBaseUrl,
      body: {
        'Guestdata_id': guestdataId,
        'Branch_ID': branchId,
        'User_ID': userId,
      },
      headers: {'Authorization': 'Bearer $token'},
    ) as Map<String, dynamic>;

    final status = response['Status'] as int? ?? response['status'] as int? ?? 0;
    return status == 1;
  } catch (e) {
    if (e is ServerException || e is NetworkException) rethrow;
    throw ServerException('Check-out failed: $e');
  }
}
```

#### Repository Implementation
**File**: `lib/features/frro/data/repositories/guest_repository_impl.dart`

```dart
@override
Future<Either<Failure, bool>> checkOut({
  required int guestdataId,
  required int branchId,
  int userId = 0,
}) async {
  try {
    final success = await remoteDataSource.checkOut(
      guestdataId: guestdataId,
      branchId: branchId,
      userId: userId,
    );
    return Right(success);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message));
  } on NetworkException {
    return const Left(NetworkFailure());
  } catch (e) {
    return Left(ServerFailure('Unexpected error: $e'));
  }
}
```

---

### 4. Presentation Layer

#### Events
**File**: `lib/features/frro/presentation/bloc/guest_list_event.dart`

Added event:
```dart
class CheckOutGuest extends GuestListEvent {
  final int guestdataId;
  final int branchId;
  final int userId;

  const CheckOutGuest({
    required this.guestdataId,
    required this.branchId,
    this.userId = 0,
  });

  @override
  List<Object?> get props => [guestdataId, branchId, userId];
}
```

#### States
**File**: `lib/features/frro/presentation/bloc/guest_list_state.dart`

Added states:
```dart
class GuestCheckOutProgress extends GuestListState {
  final int guestdataId;
  const GuestCheckOutProgress(this.guestdataId);

  @override
  List<Object?> get props => [guestdataId];
}

class GuestCheckOutSuccess extends GuestListState {
  final int guestdataId;
  const GuestCheckOutSuccess(this.guestdataId);

  @override
  List<Object?> get props => [guestdataId];
}

class GuestCheckOutFailure extends GuestListState {
  final int guestdataId;
  final String message;
  const GuestCheckOutFailure(this.guestdataId, this.message);

  @override
  List<Object?> get props => [guestdataId, message];
}
```

#### BLoC
**File**: `lib/features/frro/presentation/bloc/guest_list_bloc.dart`

Added:
- Import for `CheckOutGuestUseCase`
- Constructor parameter for `checkOutGuest`
- Event handler `_onCheckOutGuest`

```dart
Future<void> _onCheckOutGuest(
  CheckOutGuest event,
  Emitter<GuestListState> emit,
) async {
  final currentState = state;
  emit(GuestCheckOutProgress(event.guestdataId));

  final result = await checkOutGuest(
    guestdataId: event.guestdataId,
    branchId: event.branchId,
    userId: event.userId,
  );

  result.fold(
    (failure) =>
        emit(GuestCheckOutFailure(event.guestdataId, failure.message)),
    (success) {
      if (success) {
        emit(GuestCheckOutSuccess(event.guestdataId));
      } else {
        emit(
          GuestCheckOutFailure(
            event.guestdataId,
            'Check-out failed. Please try again.',
          ),
        );
      }
    },
  );

  // Restore previous list state so the UI doesn't go blank
  if (currentState is GuestListLoaded) {
    emit(currentState);
  }
}
```

---

### 5. Dependency Injection
**File**: `lib/core/di/injection_container.dart`

Added:
```dart
// Import
import '../../features/frro/domain/usecases/check_out_guest.dart';

// Use case registration
sl.registerLazySingleton(() => CheckOutGuestUseCase(sl()));

// BLoC registration (updated)
sl.registerFactory(
  () => GuestListBloc(
    getGuestList: sl(),
    checkInGuest: sl<CheckInGuestUseCase>(),
    checkOutGuest: sl<CheckOutGuestUseCase>(),  // NEW
  ),
);
```

---

## Architecture Pattern

The check-out feature follows Clean Architecture principles:

```
Presentation Layer (BLoC)
    ↓
Domain Layer (Use Case)
    ↓
Domain Layer (Repository Interface)
    ↓
Data Layer (Repository Implementation)
    ↓
Data Layer (Remote Data Source)
    ↓
API
```

---

## How to Use

### From UI (Example)

```dart
// Dispatch check-out event
context.read<GuestListBloc>().add(
  CheckOutGuest(
    guestdataId: 191,
    branchId: 5,
    userId: 10,
  ),
);

// Listen to state changes
BlocListener<GuestListBloc, GuestListState>(
  listener: (context, state) {
    if (state is GuestCheckOutSuccess) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Guest checked out successfully')),
      );
      // Reload guest list
      context.read<GuestListBloc>().add(
        LoadGuestList(branchId: 5),
      );
    } else if (state is GuestCheckOutFailure) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Check-out failed: ${state.message}')),
      );
    }
  },
  child: YourWidget(),
)
```

---

## State Flow

1. **User triggers check-out** → `CheckOutGuest` event dispatched
2. **BLoC emits** → `GuestCheckOutProgress` (show loading)
3. **API call made** → Check-out use case executes
4. **Success** → `GuestCheckOutSuccess` emitted
5. **Failure** → `GuestCheckOutFailure` emitted with error message
6. **Previous state restored** → Guest list remains visible

---

## Error Handling

The implementation handles:
- ✅ Network errors (`NetworkException`)
- ✅ Server errors (`ServerException`)
- ✅ Unexpected errors (generic exception)
- ✅ API response validation (checks `Status` field)

All errors are converted to user-friendly messages via the `Failure` classes.

---

## Testing

### Manual Testing Steps

1. **Successful Check-Out**:
   - Select a checked-in guest
   - Trigger check-out
   - Verify API call with correct parameters
   - Verify success state and message

2. **Failed Check-Out**:
   - Trigger check-out with invalid data
   - Verify error state and message
   - Verify guest list remains visible

3. **Network Error**:
   - Disable network
   - Trigger check-out
   - Verify network error message

---

## Files Created

1. `lib/features/frro/domain/usecases/check_out_guest.dart`

---

## Files Modified

1. `lib/core/config/api_constants.dart`
2. `lib/features/frro/domain/repositories/guest_repository.dart`
3. `lib/features/frro/data/repositories/guest_repository_impl.dart`
4. `lib/features/frro/data/datasources/guest_remote_data_source.dart`
5. `lib/features/frro/presentation/bloc/guest_list_event.dart`
6. `lib/features/frro/presentation/bloc/guest_list_state.dart`
7. `lib/features/frro/presentation/bloc/guest_list_bloc.dart`
8. `lib/core/di/injection_container.dart`

---

## Verification

✅ No syntax errors  
✅ All diagnostics passed  
✅ Follows existing architecture pattern  
✅ Consistent with check-in implementation  
✅ Proper error handling  
✅ Dependency injection configured  

---

## Next Steps

To complete the feature, you need to:

1. **Add UI Button** - Add a check-out button in the guest list or detail page
2. **Add BLoC Listener** - Listen to check-out states and show appropriate messages
3. **Reload Guest List** - After successful check-out, reload the guest list
4. **Add Confirmation Dialog** - Optional: Ask user to confirm before check-out
5. **Test with Real API** - Test with actual backend to verify integration

---

## Example UI Integration

```dart
// In guest list page
ElevatedButton(
  onPressed: () {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Check-Out'),
        content: Text('Are you sure you want to check out ${guest.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Dispatch check-out event
              context.read<GuestListBloc>().add(
                CheckOutGuest(
                  guestdataId: guest.guestdataId,
                  branchId: 5,
                  userId: 10,
                ),
              );
            },
            child: Text('Check Out'),
          ),
        ],
      ),
    );
  },
  child: Text('Check Out'),
)
```

---

## Summary

The FRRO Check-Out API has been fully integrated following Clean Architecture principles. The implementation mirrors the existing check-in feature for consistency and maintainability. All layers (domain, data, presentation) have been updated, and dependency injection is configured. The feature is ready for UI integration and testing.
