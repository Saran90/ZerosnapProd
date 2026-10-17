class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Server error occurred']);

  @override
  String toString() => message;
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Cache error occurred']);

  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'No internet connection']);

  @override
  String toString() => message;
}

class ValidationException implements Exception {
  final String message;
  const ValidationException(this.message);

  @override
  String toString() => message;
}

/// Thrown when the server returns HTTP 401 (Unauthorised).
/// Handled centrally by [ApiBaseHelper] — triggers an automatic redirect
/// to the login screen via [AppNavigator.redirectToLogin].
class UnauthorisedException implements Exception {
  const UnauthorisedException();

  @override
  String toString() => 'Session expired. Please log in again.';
}
