import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../router/app_router.dart';
import '../widgets/session_expired_sheet.dart';

/// A global [NavigatorKey] and session-expiry helpers.
///
/// Usage:
///   1. Pass [AppNavigator.navigatorKey] to [GoRouter]'s `navigatorKey`.
///   2. From a form page that catches [UnauthorisedException], call
///      [AppNavigator.handleUnauthorised] — it shows the re-login sheet and
///      returns `true` when the user logs in successfully so the caller can
///      immediately retry the failed operation.
///   3. Call [AppNavigator.redirectToLogin] when you need a hard redirect
///      (no context available, or the user dismissed the sheet and you want
///      to kick them out entirely).
class AppNavigator {
  AppNavigator._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  // ── In-place re-login (form pages) ───────────────────────────────────────

  /// Shows [SessionExpiredSheet] over the current route.
  ///
  /// Returns `true` when the user logs in successfully — the caller should
  /// retry the operation that triggered the 401.
  /// Returns `false` when the user dismisses the sheet without logging in.
  static Future<bool> handleUnauthorised(BuildContext context) {
    return SessionExpiredSheet.show(context);
  }

  // ── Hard redirect (non-form / context-free) ──────────────────────────────

  /// Clears the access token from shared preferences, then replaces the
  /// entire navigation stack with the login screen.
  ///
  /// Use this when there is no [BuildContext] available (e.g. background
  /// services) or when you want to force a full logout regardless.
  static Future<void> redirectToLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authorization_token');

    final router = navigatorKey.currentContext != null
        ? GoRouter.of(navigatorKey.currentContext!)
        : null;

    if (router == null) return;

    router.go(AppRoutes.login);
  }
}
