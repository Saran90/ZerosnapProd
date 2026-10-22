import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Holds contextual metadata attached to every logged error.
class LogContext {
  final String userEmail;
  final String username;
  final String journeyName;
  final String screenName;

  const LogContext({
    this.userEmail = '',
    this.username = '',
    this.journeyName = '',
    this.screenName = '',
  });

  LogContext copyWith({
    String? userEmail,
    String? username,
    String? journeyName,
    String? screenName,
  }) {
    return LogContext(
      userEmail: userEmail ?? this.userEmail,
      username: username ?? this.username,
      journeyName: journeyName ?? this.journeyName,
      screenName: screenName ?? this.screenName,
    );
  }
}

/// Central Firebase logging service.
/// Use [FirebaseLogger.instance] everywhere.
class FirebaseLogger {
  FirebaseLogger._();
  static final FirebaseLogger instance = FirebaseLogger._();

  LogContext _context = const LogContext();

  /// Update the stored context and push it to Crashlytics + Analytics.
  Future<void> setContext({
    String? userEmail,
    String? username,
    String? journeyName,
    String? screenName,
  }) async {
    _context = _context.copyWith(
      userEmail: userEmail,
      username: username,
      journeyName: journeyName,
      screenName: screenName,
    );

    await FirebaseCrashlytics.instance.setUserIdentifier(_context.userEmail);
    await FirebaseCrashlytics.instance.setCustomKey(
      'login_email',
      _context.userEmail,
    );
    await FirebaseCrashlytics.instance.setCustomKey(
      'login_username',
      _context.username,
    );
    await FirebaseCrashlytics.instance.setCustomKey(
      'journey_name',
      _context.journeyName,
    );
    await FirebaseCrashlytics.instance.setCustomKey(
      'screen_name',
      _context.screenName,
    );

    await FirebaseAnalytics.instance.setUserProperty(
      name: 'login_email',
      value: _context.userEmail,
    );
    await FirebaseAnalytics.instance.setUserProperty(
      name: 'login_username',
      value: _context.username,
    );
    await FirebaseAnalytics.instance.setUserProperty(
      name: 'journey_name',
      value: _context.journeyName,
    );
    await FirebaseAnalytics.instance.setUserProperty(
      name: 'screen_name',
      value: _context.screenName,
    );
  }

  /// Clear all context (call on logout).
  Future<void> clearContext() async {
    _context = const LogContext();
    await FirebaseCrashlytics.instance.setUserIdentifier('');
    await FirebaseCrashlytics.instance.setCustomKey('login_email', '');
    await FirebaseCrashlytics.instance.setCustomKey('login_username', '');
    await FirebaseCrashlytics.instance.setCustomKey('journey_name', '');
    await FirebaseCrashlytics.instance.setCustomKey('screen_name', '');

    await FirebaseAnalytics.instance.setUserProperty(
      name: 'login_email',
      value: null,
    );
    await FirebaseAnalytics.instance.setUserProperty(
      name: 'login_username',
      value: null,
    );
    await FirebaseAnalytics.instance.setUserProperty(
      name: 'journey_name',
      value: null,
    );
    await FirebaseAnalytics.instance.setUserProperty(
      name: 'screen_name',
      value: null,
    );
  }

  /// Log a non-fatal error to Crashlytics and Analytics.
  ///
  /// In addition to [recordError] (which files the issue in Crashlytics) this
  /// also calls [FirebaseCrashlytics.log] so the full context — user, screen,
  /// journey, and the error message — appears as a breadcrumb inside the
  /// Crashlytics issue. GA4 only surfaces the event name in its standard UI,
  /// so the breadcrumb is the reliable way to see the detail.
  Future<void> logError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? hint,
  }) async {
    final timestamp = DateTime.now().toUtc().toIso8601String();
    // Truncate to 100 chars — Analytics param values have a 100-char limit.
    final errorMessage = _truncate(exception?.toString() ?? 'unknown error');

    // --- Crashlytics custom keys (visible in the issue's Keys tab) ----------
    await FirebaseCrashlytics.instance.setCustomKey(
      'login_email',
      _context.userEmail,
    );
    await FirebaseCrashlytics.instance.setCustomKey(
      'login_username',
      _context.username,
    );
    await FirebaseCrashlytics.instance.setCustomKey(
      'journey_name',
      _context.journeyName,
    );
    await FirebaseCrashlytics.instance.setCustomKey(
      'screen_name',
      _context.screenName,
    );
    await FirebaseCrashlytics.instance.setCustomKey('timestamp', timestamp);
    await FirebaseCrashlytics.instance.setCustomKey(
      'error_message',
      errorMessage,
    );
    if (hint != null) {
      await FirebaseCrashlytics.instance.setCustomKey('hint', hint);
    }

    // --- Crashlytics breadcrumb log (visible in the issue's Logs tab) -------
    // This is the human-readable line that shows full detail in Crashlytics,
    // since GA4 only shows the event name in its dashboard.
    await FirebaseCrashlytics.instance.log(
      '[server_error] '
      'user=${_context.userEmail} (${_context.username}) | '
      'screen=${_context.screenName} | '
      'journey=${_context.journeyName} | '
      'fatal=false | '
      'ts=$timestamp | '
      '${hint != null ? 'hint=$hint | ' : ''}'
      'error=$errorMessage',
    );

    // --- Crashlytics non-fatal record ---------------------------------------
    await FirebaseCrashlytics.instance.recordError(
      exception,
      stackTrace,
      reason: hint,
      fatal: false,
    );

    // --- GA4 event (event name visible; params visible in DebugView / BQ) --
    await FirebaseAnalytics.instance.logEvent(
      name: 'server_error',
      parameters: {
        'login_email': _context.userEmail,
        'login_username': _context.username,
        'journey_name': _context.journeyName,
        'screen_name': _context.screenName,
        'timestamp': timestamp,
        'error_message': errorMessage,
        'is_fatal': 'false',
        // ignore: use_null_aware_elements — logEvent requires non-nullable values
        if (hint != null) 'hint': hint,
      },
    );
  }

  /// Log a fatal error to Crashlytics and Analytics.
  ///
  /// Mirrors [logError] but marks the Crashlytics record as fatal and sets
  /// [is_fatal] to `'true'` in the GA4 event.
  Future<void> logFatal(
    dynamic exception,
    StackTrace? stackTrace, {
    String? hint,
  }) async {
    final timestamp = DateTime.now().toUtc().toIso8601String();
    final errorMessage = _truncate(exception?.toString() ?? 'unknown error');

    // --- Crashlytics custom keys --------------------------------------------
    await FirebaseCrashlytics.instance.setCustomKey(
      'login_email',
      _context.userEmail,
    );
    await FirebaseCrashlytics.instance.setCustomKey(
      'login_username',
      _context.username,
    );
    await FirebaseCrashlytics.instance.setCustomKey(
      'journey_name',
      _context.journeyName,
    );
    await FirebaseCrashlytics.instance.setCustomKey(
      'screen_name',
      _context.screenName,
    );
    await FirebaseCrashlytics.instance.setCustomKey('timestamp', timestamp);
    await FirebaseCrashlytics.instance.setCustomKey(
      'error_message',
      errorMessage,
    );
    if (hint != null) {
      await FirebaseCrashlytics.instance.setCustomKey('hint', hint);
    }

    // --- Crashlytics breadcrumb log -----------------------------------------
    await FirebaseCrashlytics.instance.log(
      '[server_error] '
      'user=${_context.userEmail} (${_context.username}) | '
      'screen=${_context.screenName} | '
      'journey=${_context.journeyName} | '
      'fatal=true | '
      'ts=$timestamp | '
      '${hint != null ? 'hint=$hint | ' : ''}'
      'error=$errorMessage',
    );

    // --- Crashlytics fatal record -------------------------------------------
    await FirebaseCrashlytics.instance.recordError(
      exception,
      stackTrace,
      reason: hint,
      fatal: true,
    );

    // --- GA4 event ----------------------------------------------------------
    await FirebaseAnalytics.instance.logEvent(
      name: 'server_error',
      parameters: {
        'login_email': _context.userEmail,
        'login_username': _context.username,
        'journey_name': _context.journeyName,
        'screen_name': _context.screenName,
        'timestamp': timestamp,
        'error_message': errorMessage,
        'is_fatal': 'true',
        // ignore: use_null_aware_elements — logEvent requires non-nullable values
        if (hint != null) 'hint': hint,
      },
    );
  }

  /// Truncates a string to 100 characters — the Firebase Analytics
  /// parameter value limit.
  String _truncate(String value, [int maxLength = 100]) =>
      value.length <= maxLength
      ? value
      : '${value.substring(0, maxLength - 1)}…';
}
