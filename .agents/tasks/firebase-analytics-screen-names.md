# Firebase Analytics Screen Names — Investigation Report

## Summary

Firebase Analytics is already integrated (`firebase_analytics: ^11.4.4`), but **no screen tracking is wired up**. The app uses **GoRouter** (`go_router: ^14.6.2`) with `MaterialApp.router`, and there is no `FirebaseAnalyticsObserver` attached to the router. Firebase's automatic `screen_view` events therefore fire using the native Android activity name (`MainActivity`) instead of Flutter screen names. The only analytics calls in the codebase set `screen_name` as a **user property** — not as a `screen_view` event — and that property is only ever set to `'login_page'` once, on successful login.

---

## Evidence

### 1. `firebase_analytics` version

**File:** `pubspec.yaml`

```yaml
firebase_analytics: ^11.4.4
```

Version is current and compatible with `firebase_core: ^3.13.1`.

---

### 2. Root widget and router setup

**File:** `lib/main.dart`

```dart
return MaterialApp.router(
  title: 'Zerosnap',
  routerConfig: appRouter,    // ← GoRouter; no observers attached here
  ...
);
```

`MaterialApp.router` does not expose a `navigatorObservers` parameter directly. Screen tracking with GoRouter requires either:
- A `GoRouter(observers: [FirebaseAnalyticsObserver(...)])` in the GoRouter constructor, **or**
- A `redirect` / `onRoute` listener that calls `FirebaseAnalytics.instance.logScreenView(...)` manually.

Neither is present.

---

### 3. GoRouter definition — no observer

**File:** `lib/core/router/app_router.dart`

```dart
final appRouter = GoRouter(
  navigatorKey: AppNavigator.navigatorKey,
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(path: '/',          builder: (_, __) => const SplashPage()),
    GoRoute(path: '/login',     builder: (_, __) => const LoginPage()),
    GoRoute(path: '/dashboard', builder: (_, __) => const DashboardPage()),
    GoRoute(path: '/guests',    builder: ...),
    GoRoute(path: '/frro',      builder: ...),
    GoRoute(path: '/settings',  builder: ...),
  ],
);
```

No `observers:` key. `FirebaseAnalyticsObserver` is never instantiated anywhere in the codebase.

---

### 4. Existing analytics code

**File:** `lib/core/services/firebase_logger.dart`

- `FirebaseLogger` is a singleton that wraps `FirebaseAnalytics.instance`.
- `setContext(screenName: ...)` sets `screen_name` as a **user property** (`setUserProperty`), not a screen-view event.
- `logError` / `logFatal` log a custom `server_error` event with `screen_name` as a parameter.
- **No `logScreenView` or `screen_view` event is ever called.**

**File:** `lib/features/auth/data/auth_repository.dart`

```dart
FirebaseLogger.instance.setContext(
  userEmail: result.session!.userEmail,
  username: result.session!.username,
  journeyName: 'login',
  screenName: 'login_page',
);
```

This is the **only place** `setContext` is called with a `screenName`. It fires once on login success. No other screen sets the context — the user property stays `'login_page'` for the entire app session after login.

---

### 5. No `logScreenView` calls anywhere

A full search across all `.dart` files found zero calls to:
- `logScreenView`
- `screen_view`
- `FirebaseAnalyticsObserver`
- `setCurrentScreen` (deprecated API)

---

### 6. Route names defined

**File:** `lib/core/router/app_router.dart` — `AppRoutes` class

| Constant            | Path                    |
|---------------------|-------------------------|
| `splash`            | `/`                     |
| `login`             | `/login`                |
| `dashboard`         | `/dashboard`            |
| `guestList`         | `/guests`               |
| `addGuest`          | `/guests/add`           |
| `guestDetail`       | `/guests/:id`           |
| `frroList`          | `/frro`                 |
| `frroForm`          | `/frro/form`            |
| `settings`          | `/settings`             |
| `frroCredentials`   | `/settings/frro-credentials` |

No `name:` property is set on any `GoRoute`; only `path:` is used.

---

## Root Cause

Firebase Analytics on Android auto-fires a `screen_view` event when the foreground activity changes. In a Flutter app built on a single `FlutterActivity`, that activity never changes, so Analytics never sees a new screen — it just keeps re-reporting `MainActivity`. Flutter's screen changes are pure widget transitions inside a single Activity and are invisible to the native SDK unless you explicitly call `logScreenView` from Dart.

The fix is to hook Flutter's navigation events and call `FirebaseAnalytics.instance.logScreenView(...)` on every route change.

---

## Recommendations

### Option A — GoRouter `observers` (recommended for this codebase)

Add `FirebaseAnalyticsObserver` to the GoRouter constructor. Note: `FirebaseAnalyticsObserver` is a `NavigatorObserver` and works with GoRouter when passed via `observers:`.

**`lib/core/router/app_router.dart`** — changes needed:

```dart
import 'package:firebase_analytics/firebase_analytics.dart';

final _analytics = FirebaseAnalytics.instance;

final appRouter = GoRouter(
  navigatorKey: AppNavigator.navigatorKey,
  initialLocation: AppRoutes.splash,
  observers: [FirebaseAnalyticsObserver(analytics: _analytics)],
  routes: [ ... ],
);
```

`FirebaseAnalyticsObserver` calls `logScreenView` automatically on every `Navigator.push/pop`, using the route name. Because GoRoute uses `path` (not `name`), the path (e.g. `/dashboard`) will be used as the screen name — which is readable and meaningful.

> **Caveat:** `FirebaseAnalyticsObserver` requires routes to have a `RouteSettings.name`. GoRouter sets this from the route `path` when building routes with `GoRoute.path`, so this works out of the box. If GoRouter sub-routes ever return blank names, add an explicit `name:` to those `GoRoute` entries.

### Option B — GoRouter `redirect` / `onEnter` listener (manual, more control)

Add a `GoRouter.routeInformationParser` listener or use the `GoRouter.routerDelegate.addListener` pattern to call `FirebaseAnalytics.instance.logScreenView` manually on every navigation. This gives full control over screen names and screen classes but requires more boilerplate.

### Also fix: `setContext` screen name

Currently `FirebaseLogger.setContext(screenName: ...)` is only called once (on login). The `screen_name` user property stays stale throughout the session. Once Option A is in place, consider calling `FirebaseLogger.instance.setContext(screenName: currentPath)` inside a GoRouter listener so the user property stays in sync for error events.

---

## Relevant Files

| File | Role |
|------|------|
| `lib/main.dart` | Root widget; `MaterialApp.router` with `routerConfig: appRouter` |
| `lib/core/router/app_router.dart` | GoRouter definition, `AppRoutes` constants — **primary fix location** |
| `lib/core/navigation/app_navigator.dart` | Global navigator key; could host a GoRouter listener |
| `lib/core/services/firebase_logger.dart` | All Firebase Analytics calls; needs `logScreenView` integration |
| `lib/features/auth/data/auth_repository.dart` | Only existing `setContext` call |
| `pubspec.yaml` | Dependency versions |
