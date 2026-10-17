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
    await FirebaseCrashlytics.instance
        .setCustomKey('login_email', _context.userEmail);
    await FirebaseCrashlytics.instance
        .setCustomKey('login_username', _context.username);
    await FirebaseCrashlytics.instance
        .setCustomKey('journey_name', _context.journeyName);
    await FirebaseCrashlytics.instance
        .setCustomKey('screen_name', _context.screenName);

    await FirebaseAnalytics.instance
        .setUserProperty(name: 'login_email', value: _context.userEmail);
    await FirebaseAnalytics.instance
        .setUserProperty(name: 'login_username', value: _context.username);
    await FirebaseAnalytics.instance
        .setUserProperty(name: 'journey_name', value: _context.journeyName);
    await FirebaseAnalytics.instance
        .setUserProperty(name: 'screen_name', value: _context.screenName);
  }

  /// Clear all context (call on logout).
  Future<void> clearContext() async {
    _context = const LogContext();
    await FirebaseCrashlytics.instance.setUserIdentifier('');
    await FirebaseCrashlytics.instance.setCustomKey('login_email', '');
    await FirebaseCrashlytics.instance.setCustomKey('login_username', '');
    await FirebaseCrashlytics.instance.setCustomKey('journey_name', '');
    await FirebaseCrashlytics.instance.setCustomKey('screen_name', '');

    await FirebaseAnalytics.instance
        .setUserProperty(name: 'login_email', value: null);
    await FirebaseAnalytics.instance
        .setUserProperty(name: 'login_username', value: null);
    await FirebaseAnalytics.instance
        .setUserProperty(name: 'journey_name', value: null);
    await FirebaseAnalytics.instance
        .setUserProperty(name: 'screen_name', value: null);
  }

  /// Log a non-fatal error to Crashlytics and Analytics.
  Future<void> logError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? hint,
  }) async {
    final timestamp = DateTime.now().toUtc().toIso8601String();
    await FirebaseCrashlytics.instance
        .setCustomKey('login_email', _context.userEmail);
    await FirebaseCrashlytics.instance
        .setCustomKey('login_username', _context.username);
    await FirebaseCrashlytics.instance
        .setCustomKey('journey_name', _context.journeyName);
    await FirebaseCrashlytics.instance
        .setCustomKey('screen_name', _context.screenName);
    await FirebaseCrashlytics.instance
        .setCustomKey('timestamp', timestamp);
    if (hint != null) {
      await FirebaseCrashlytics.instance.setCustomKey('hint', hint);
    }

    await FirebaseCrashlytics.instance.recordError(
      exception,
      stackTrace,
      reason: hint,
      fatal: false,
    );

    await FirebaseAnalytics.instance.logEvent(
      name: 'server_error',
      parameters: {
        'login_email': _context.userEmail,
        'login_username': _context.username,
        'journey_name': _context.journeyName,
        'screen_name': _context.screenName,
        'timestamp': timestamp,
        if (hint != null) 'hint': hint,
      },
    );
  }

  /// Log a fatal error to Crashlytics and Analytics.
  Future<void> logFatal(
    dynamic exception,
    StackTrace? stackTrace, {
    String? hint,
  }) async {
    final timestamp = DateTime.now().toUtc().toIso8601String();
    await FirebaseCrashlytics.instance
        .setCustomKey('login_email', _context.userEmail);
    await FirebaseCrashlytics.instance
        .setCustomKey('login_username', _context.username);
    await FirebaseCrashlytics.instance
        .setCustomKey('journey_name', _context.journeyName);
    await FirebaseCrashlytics.instance
        .setCustomKey('screen_name', _context.screenName);
    await FirebaseCrashlytics.instance
        .setCustomKey('timestamp', timestamp);
    if (hint != null) {
      await FirebaseCrashlytics.instance.setCustomKey('hint', hint);
    }

    await FirebaseCrashlytics.instance.recordError(
      exception,
      stackTrace,
      reason: hint,
      fatal: true,
    );

    await FirebaseAnalytics.instance.logEvent(
      name: 'server_error',
      parameters: {
        'login_email': _context.userEmail,
        'login_username': _context.username,
        'journey_name': _context.journeyName,
        'screen_name': _context.screenName,
        'timestamp': timestamp,
        if (hint != null) 'hint': hint,
      },
    );
  }
}
