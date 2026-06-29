# FRRO Credentials Sync API Implementation Guide

## Overview
This guide provides instructions for implementing the Sync from Server feature once the backend API endpoint becomes available.

## Current Status
🟡 **Placeholder Implementation** - The sync button shows an info message
- Location: `lib/features/settings/presentation/pages/frro_credentials_page.dart`
- Method: `_syncCredentials()`
- Status: Ready for API integration

---

## API Requirements

### Expected Endpoint Details

#### Endpoint Path
```
[POST/GET] /api/frro/sync-credentials
or
[POST/GET] /api/frro/get-credentials
or
[POST/GET] /api/account/frro/update
```

#### Request Format (if POST)
```json
{
  "userId": "12345",
  "token": "auth_token_here",
  "branchId": 5
}
```

#### Response Format (Success)
```json
{
  "status": 1,
  "statusMessage": "Success",
  "data": {
    "frroUsername": "updated_username",
    "frroPassword": "updated_password",
    "frroDistrictId": "12345",
    "lastSyncedAt": "2024-06-01T10:30:00Z"
  }
}
```

#### Response Format (Error)
```json
{
  "status": 0,
  "statusMessage": "Failed to sync credentials"
}
```

---

## Implementation Steps

### Step 1: Create API Service Method

**File**: `lib/core/network/api_base_helper.dart` (or create new file)

```dart
class FrroApiService {
  final ApiBaseHelper _api;
  final SharedPreferencesProvider _prefs;

  FrroApiService({
    required ApiBaseHelper api,
    required SharedPreferencesProvider prefs,
  })
    : _api = api,
      _prefs = prefs;

  Future<FrroSyncResult> syncFrroCredentials() async {
    try {
      final session = await _prefs.getLoginSession();
      if (session == null) {
        return FrroSyncResult(
          success: false,
          message: 'No active session',
        );
      }

      final response = await _api.get(
        '/api/frro/sync-credentials',
        queryParameters: {
          'userId': session.username,
          'branchId': '5', // Or from session
        },
      ) as Map<String, dynamic>;

      return FrroSyncResult.fromJson(response);
    } catch (e) {
      return FrroSyncResult(
        success: false,
        message: 'Error syncing credentials: $e',
      );
    }
  }
}
```

### Step 2: Create Result Model

**File**: `lib/features/settings/data/models/frro_sync_result.dart`

```dart
class FrroSyncResult {
  final bool success;
  final String? message;
  final String? frroUsername;
  final String? frroPassword;
  final String? frroDistrictId;
  final String? lastSyncedAt;

  const FrroSyncResult({
    required this.success,
    this.message,
    this.frroUsername,
    this.frroPassword,
    this.frroDistrictId,
    this.lastSyncedAt,
  });

  factory FrroSyncResult.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as int? ?? 0;
    final data = json['data'] as Map<String, dynamic>? ?? {};

    return FrroSyncResult(
      success: status == 1,
      message: json['statusMessage'] as String? ?? json['message'] as String?,
      frroUsername: data['frroUsername'] as String?,
      frroPassword: data['frroPassword'] as String?,
      frroDistrictId: data['frroDistrictId'] as String?,
      lastSyncedAt: data['lastSyncedAt'] as String?,
    );
  }
}
```

### Step 3: Register in Dependency Injection

**File**: `lib/core/di/injection_container.dart`

```dart
void initDependencies() async {
  // ... existing code ...

  // FRRO Settings
  sl.registerLazySingleton<FrroApiService>(
    () => FrroApiService(
      api: sl<ApiBaseHelper>(),
      prefs: SharedPreferencesProvider(),
    ),
  );
}
```

### Step 4: Update FrroCredentialsPage

**File**: `lib/features/settings/presentation/pages/frro_credentials_page.dart`

```dart
class _FrroCredentialsPageState extends State<FrroCredentialsPage> {
  final _prefs = SharedPreferencesProvider();
  final _api = sl<FrroApiService>(); // Add this
  
  // ... existing code ...

  Future<void> _syncCredentials() async {
    if (!mounted) return;

    setState(() => _isSaving = true);

    try {
      // Call the API
      final result = await _api.syncFrroCredentials();

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (result.success && result.frroUsername != null) {
        // Update text fields with new values
        _usernameController.text = result.frroUsername!;
        _passwordController.text = result.frroPassword ?? '';

        // Save to local storage
        await _saveCredentials();

        _showSuccessSnackBar(
          'Credentials synced from server'
          '${result.lastSyncedAt != null ? ' at ${result.lastSyncedAt}' : ''}'
        );
      } else {
        _showErrorSnackBar(
          result.message ?? 'Failed to sync credentials'
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showErrorSnackBar('Error syncing credentials: $e');
      }
    }
  }
}
```

---

## Testing the Integration

### Unit Tests

```dart
test('syncFrroCredentials returns success with credentials', () async {
  // Arrange
  when(mockApi.get(any, queryParameters: anyNamed('queryParameters')))
    .thenAnswer((_) async => {
      'status': 1,
      'statusMessage': 'Success',
      'data': {
        'frroUsername': 'new_user',
        'frroPassword': 'new_pass',
        'frroDistrictId': '12345',
        'lastSyncedAt': '2024-06-01T10:30:00Z',
      }
    });

  // Act
  final result = await apiService.syncFrroCredentials();

  // Assert
  expect(result.success, isTrue);
  expect(result.frroUsername, equals('new_user'));
  expect(result.frroPassword, equals('new_pass'));
});

test('syncFrroCredentials returns error on failure', () async {
  // Arrange
  when(mockApi.get(any, queryParameters: anyNamed('queryParameters')))
    .thenAnswer((_) async => {
      'status': 0,
      'statusMessage': 'Failed to sync credentials'
    });

  // Act
  final result = await apiService.syncFrroCredentials();

  // Assert
  expect(result.success, isFalse);
  expect(result.message, equals('Failed to sync credentials'));
});
```

### Widget Tests

```dart
testWidgets('sync button calls API and updates fields', (tester) async {
  // Arrange
  await tester.pumpWidget(testApp);
  
  // Mock successful sync
  when(mockApi.syncFrroCredentials()).thenAnswer((_) async => 
    FrroSyncResult(
      success: true,
      frroUsername: 'synced_user',
      frroPassword: 'synced_pass',
    )
  );

  // Act
  await tester.tap(find.byIcon(Icons.refresh));
  await tester.pumpAndSettle();

  // Assert
  expect(find.text('synced_user'), findsOneWidget);
  expect(find.byType(SnackBar), findsOneWidget);
});
```

### Manual Testing Checklist

- [ ] API endpoint returns valid credentials
- [ ] Fields update with synced values
- [ ] Success message shows with timestamp (if available)
- [ ] Credentials persist after sync
- [ ] Page reload shows synced values
- [ ] Error handling works if API fails
- [ ] Loading state shows during sync
- [ ] Button disabled while syncing

---

## Integration with Existing Flow

### Auto-fill with Synced Credentials

Once synced, the credentials will automatically be used in FRRO form auto-fill:

```dart
// In FrroListPage - credentials auto-fill script
// (no changes needed - already reads from SharedPreferences)

String get _credentialsScript => """
  (function() {
    // These will now include synced credentials
    var username = '${_frroUsername}';
    var password = '${_frroPassword}';
    // ... fill form ...
  })();
""";
```

---

## Error Handling Scenarios

### Scenario 1: Network Error
```
User taps "Sync from Server"
  ↓
Network request fails (no internet)
  ↓
catch (e) block captures error
  ↓
Red SnackBar: "Error syncing credentials: SocketException: ..."
  ↓
User can retry or edit manually
```

### Scenario 2: Auth Error
```
API returns 401 Unauthorized
  ↓
Status != 1
  ↓
Red SnackBar: "Failed to sync credentials"
  ↓
Recommend: User re-login
```

### Scenario 3: No Session
```
User clicks sync without active session
  ↓
getLoginSession() returns null
  ↓
Red SnackBar: "No active session"
  ↓
User navigates back and logs in again
```

---

## Optional Enhancements

### 1. Add Timestamp Display

```dart
DateTime? _lastSynced;

void _updateLastSyncedTime() {
  setState(() => _lastSynced = DateTime.now());
  // Optional: persist to SharedPreferences
}

// In UI:
if (_lastSynced != null)
  Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(
      'Last synced: ${DateFormat('MMM dd, yyyy HH:mm').format(_lastSynced!)}',
      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
    ),
  ),
```

### 2. Add Auto-Sync on App Startup

```dart
// In LoginPage or DashboardPage
@override
void initState() {
  super.initState();
  _autoSyncFrroCredentials();
}

Future<void> _autoSyncFrroCredentials() async {
  final result = await sl<FrroApiService>().syncFrroCredentials();
  // Log result but don't show UI (silent sync)
  if (result.success) {
    debugPrint('FRRO credentials auto-synced');
  }
}
```

### 3. Add Periodic Sync

```dart
import 'dart:async';

class _FrroCredentialsPageState extends State<FrroCredentialsPage> {
  Timer? _syncTimer;
  
  @override
  void initState() {
    super.initState();
    _loadCredentials();
    // Auto-sync every 24 hours (optional)
    _syncTimer = Timer.periodic(
      const Duration(hours: 24),
      (_) => _syncCredentials(),
    );
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}
```

### 4. Add Sync History

```dart
// Track sync attempts
List<SyncAttempt> _syncHistory = [];

class SyncAttempt {
  final DateTime timestamp;
  final bool success;
  final String? message;
  
  SyncAttempt({
    required this.timestamp,
    required this.success,
    this.message,
  });
}
```

---

## Troubleshooting

### Issue: Sync button shows "API will be available in a future update"
**Solution**: Remove the TODO block and implement the actual API call

### Issue: Credentials not persisting after sync
**Solution**: Verify `_saveCredentials()` is called after updating text fields

### Issue: Fields not updating with synced values
**Solution**: Check that API response contains frroUsername and frroPassword fields

### Issue: Error "No active session"
**Solution**: Verify user is logged in and session is valid

---

## API Endpoint Recommendation

### Suggested Implementation

**Endpoint**: `GET /api/frro/credentials`

**Request**:
```
Headers:
  Authorization: Bearer {token}
  X-Branch-ID: 5
```

**Response**:
```json
{
  "status": 1,
  "statusMessage": "Credentials retrieved successfully",
  "data": {
    "frroUsername": "current_username",
    "frroPassword": "current_password",
    "frroDistrictId": "12345",
    "lastUpdatedAt": "2024-06-01T10:30:00Z",
    "expiresAt": "2024-07-01T10:30:00Z"
  }
}
```

---

## References

- API Base Helper: `lib/core/network/api_base_helper.dart`
- SharedPreferences Provider: `lib/core/network/shared_preferences_provider.dart`
- Existing API Integration: `lib/features/auth/data/auth_repository.dart`
- Dependency Injection: `lib/core/di/injection_container.dart`

---

## Support

For questions or issues with implementation:
1. Check existing API patterns in the codebase
2. Review unit/widget tests for similar features
3. Verify API endpoint returns expected format
4. Check debug logs for network requests
5. Test with mock API response first
