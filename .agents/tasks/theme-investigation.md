# Theme Investigation Report — ZerosnapProd

## Summary

The app has a well-structured, centralized theme system under `lib/core/theme/`. Both light and dark themes are fully defined via `AppTheme`, drawing all named colors from `AppColors`. However, a significant number of widget files bypass `AppColors` and hardcode raw hex/named color literals — most notably the old brand blue `0xFF29ABE2`, which is **not** the current `AppColors.primary` (Google-blue `0xFF1A73E8`). The new requested colors `#02132f` (dark navy) and `#b18d4f` (gold/bronze) require changes in **one file** for the centralized palette, plus targeted fixes in ~10 widget files for the scattered hardcodes.

---

## 1. Theme Architecture

### Primary Theme Files

| File | Role |
|------|------|
| `lib/core/theme/app_colors.dart` | Single source of truth for all named color constants |
| `lib/core/theme/app_theme.dart` | Defines `AppTheme.lightTheme` and `AppTheme.darkTheme` using Material 3 `ThemeData` |
| `lib/core/theme/app_text_styles.dart` | Centralized text styles (references `AppColors.textSecondaryLight`) |
| `lib/core/theme/cubit/theme_cubit.dart` | BLoC cubit that manages `ThemeMode` (light/dark/system) via `SharedPreferences` |
| `lib/main.dart` | Wires `AppTheme.lightTheme` and `AppTheme.darkTheme` into `MaterialApp.router`; **currently forces `ThemeMode.light`** regardless of cubit state |

---

## 2. Current Color Definitions (`app_colors.dart`)

```dart
// Primary
static const Color primary      = Color(0xFF1A73E8);  // Google Blue
static const Color primaryDark  = Color(0xFF1557B0);
static const Color primaryLight = Color(0xFF4A90E2);

// Accent
static const Color accent = Color(0xFF00BFA5);        // Teal

// Backgrounds
static const Color backgroundLight = Color(0xFFF5F7FA);
static const Color backgroundDark  = Color(0xFF121212);

// Surface
static const Color surfaceLight = Color(0xFFFFFFFF);
static const Color surfaceDark  = Color(0xFF1E1E1E);

// Card
static const Color cardLight = Color(0xFFFFFFFF);
static const Color cardDark  = Color(0xFF2C2C2C);

// Text
static const Color textPrimaryLight    = Color(0xFF1A1A2E);
static const Color textSecondaryLight  = Color(0xFF6B7280);
static const Color textPrimaryDark     = Color(0xFFF1F1F1);
static const Color textSecondaryDark   = Color(0xFFAAAAAA);

// Status
static const Color success = Color(0xFF34A853);
static const Color warning = Color(0xFFFBBC04);
static const Color error   = Color(0xFFEA4335);
static const Color info    = Color(0xFF4285F4);

// Border
static const Color borderLight = Color(0xFFE0E0E0);
static const Color borderDark  = Color(0xFF3A3A3A);

// Divider
static const Color dividerLight = Color(0xFFEEEEEE);
static const Color dividerDark  = Color(0xFF2E2E2E);
```

**New requested colors:**
- `#02132f` — deep navy blue (replaces current primary `#1A73E8`)
- `#b18d4f` — gold/bronze (replaces accent `#00BFA5` and the old hardcoded brand blue `#29ABE2`)

---

## 3. ThemeData Structure

### Light Theme (`AppTheme.lightTheme`)
- `colorScheme.primary` → `AppColors.primary`
- `colorScheme.secondary` → `AppColors.accent`
- `colorScheme.surface` → `AppColors.surfaceLight`
- `scaffoldBackgroundColor` → `AppColors.backgroundLight`
- `cardColor` → `AppColors.cardLight`
- `appBarTheme.backgroundColor` → `AppColors.surfaceLight`
- `elevatedButtonTheme.backgroundColor` → `AppColors.primary`
- `outlinedButtonTheme.foregroundColor` / `borderSide` → `AppColors.primary`
- `inputDecorationTheme.focusedBorder` → `AppColors.primary`
- `bottomNavigationBarTheme.selectedItemColor` → `AppColors.primary`
- **Hardcoded chip** `selectedColor: Color.fromRGBO(26, 115, 232, 0.15)` — uses raw RGBA of primary blue

### Dark Theme (`AppTheme.darkTheme`)
- `colorScheme.primary` → `AppColors.primaryLight`
- `elevatedButtonTheme.backgroundColor` → `AppColors.primaryLight`
- `outlinedButtonTheme` → `AppColors.primaryLight`
- `bottomNavigationBarTheme.selectedItemColor` → `AppColors.primaryLight`
- **Hardcoded chip** `selectedColor: Color.fromRGBO(74, 144, 226, 0.2)` — raw RGBA of primaryLight

### Dark Mode Note
The cubit + `darkTheme` are fully wired, but `main.dart` line 49 forces `themeMode: ThemeMode.light` (ignores the cubit state). Dark theme exists but is never activated.

---

## 4. Files Using `AppColors` (Properly)

These files reference `AppColors.*` correctly and will automatically pick up changes to `app_colors.dart`:

1. `lib/core/theme/app_text_styles.dart`
2. `lib/core/theme/app_theme.dart`
3. `lib/core/utils/image_crop_helper.dart`
4. `lib/core/widgets/session_expired_sheet.dart`
5. `lib/features/auth/presentation/pages/login_page.dart` *(partial — also has hardcodes)*
6. `lib/features/dashboard/presentation/pages/dashboard_page.dart` *(partial)*
7. `lib/features/frro/presentation/pages/frro_list_page.dart`
8. `lib/features/frro/presentation/widgets/guest_filter_dialog.dart`
9. `lib/features/guest_management/presentation/pages/guest_list_page.dart` *(partial)*
10. `lib/features/scan/presentation/pages/card_scan_page.dart` *(partial)*
11. `lib/features/scan/presentation/pages/foreign_passport_scan_page.dart` *(partial)*
12. `lib/features/scan/presentation/pages/passport_card_scan_page.dart` *(partial)*
13. `lib/features/scan/presentation/pages/passport_form_page.dart`
14. `lib/features/scan/presentation/pages/profile_crop_page.dart`
15. `lib/features/scan/presentation/widgets/duplicate_guest_checker.dart`
16. `lib/features/scan/presentation/widgets/signature_pad.dart` *(partial)*
17. `lib/features/settings/presentation/pages/frro_credentials_page.dart` *(partial)*
18. `lib/features/settings/presentation/pages/settings_page.dart` *(partial)*

---

## 5. Hardcoded Colors in Widget Files

### Category A: Old Brand Blue `0xFF29ABE2` — **Must Change**
This is an old brand color (sky blue) not mapped to any `AppColors` constant. It appears in the splash screen's fallback logo widget and throughout dashboard/scan dialogs. With the new theme, this should become `AppColors.primary` (`#02132f`) or `AppColors.accent` (`#b18d4f`) depending on context.

| File | Lines | Usage |
|------|-------|-------|
| `lib/features/splash/presentation/pages/splash_page.dart` | 172, 184, 225 | Fallback `_ZeroSnapLogoWidget` text colors and `_ZIconPainter` blue fill |
| `lib/features/dashboard/presentation/pages/dashboard_page.dart` | 206, 210 | Scan button fill color + glow |
| `lib/features/dashboard/presentation/widgets/card_input_dialog.dart` | 113, 117, 121 | Button filled state and border |
| `lib/features/dashboard/presentation/widgets/choose_card_dialog.dart` | 462, 466, 470 | Button filled state and border |
| `lib/features/dashboard/presentation/widgets/scan_card_dialog.dart` | 83, 184, 188 | `_color` constant used throughout widget |
| `lib/features/guest_management/presentation/pages/guest_list_page.dart` | 588 | Icon color |
| `lib/features/scan/presentation/pages/mrz_scanner_page.dart` | 254 | `CircularProgressIndicator` color |
| `lib/features/scan/presentation/widgets/mrz_result_sheet.dart` | 50, 145, 146, 161, 202 | Sheet header, buttons, border |
| `lib/core/widgets/image_source_dialog.dart` | 95, 99, 103 | Button filled + border (also has `0xFF2C3E50`) |

### Category B: Golden/Amber `0xFFC8941A` — Relates to Accent
This appears exclusively in scan page image-cropping UI (active controls, crop frame, progress indicator). It is a partial match to the new `#b18d4f` gold accent.

| File | Lines | Usage |
|------|-------|-------|
| `lib/features/scan/presentation/pages/domestic_card_scan_page.dart` | 246, 258, 473, 792 | Crop frame, active controls, step indicator |
| `lib/features/scan/presentation/pages/domestic_passport_scan_page.dart` | 224, 236, 452, 644 | Same as above |
| `lib/features/scan/presentation/pages/foreign_passport_scan_page.dart` | 267, 281, 598, 926, 1341 | Crop frame, next button, step indicator |
| `lib/features/scan/presentation/pages/profile_photo_camera_page.dart` | 367, 370 | Capture button fill and glow |

### Category C: Dark Navy `0xFF2C3E50` — Potentially Map to New Primary
Used as a dark text/foreground color in many widgets. The new primary `#02132f` is also a very dark navy — these could be unified.

| File | Lines |
|------|-------|
| `lib/core/widgets/image_source_dialog.dart` | 37, 117, 127 |
| `lib/features/auth/presentation/pages/login_page.dart` | 166, 376 |
| `lib/features/dashboard/presentation/widgets/card_input_dialog.dart` | 134 |
| `lib/features/dashboard/presentation/widgets/choose_card_dialog.dart` | 318, 430, 483 |
| `lib/features/guest_management/presentation/pages/guest_list_page.dart` | 300, 602, 917 |
| `lib/features/scan/presentation/pages/mrz_scanner_page.dart` | 262 |
| `lib/features/scan/presentation/widgets/mrz_result_sheet.dart` | 243 |
| `lib/features/settings/presentation/pages/settings_page.dart` | 201, 412, 483 |

### Category D: Various Semantic Colors (Green, Red, Orange, etc.)
These are status/semantic colors (`Colors.green`, `Colors.red`, etc.) in scan confirmation UIs and settings. These are intentional and semantic — they should not be changed with the brand theme update.

| File | Usage |
|------|-------|
| `lib/features/scan/presentation/pages/passport_card_scan_page.dart` | `Colors.red[700]`, `Colors.green[700]` (scan result status) |
| `lib/features/settings/presentation/pages/frro_credentials_page.dart` | `Colors.green`, `Colors.blue` (connection status badges) |
| `lib/features/settings/presentation/pages/settings_page.dart` | `Colors.orange`, `Colors.purple`, `Colors.red` (settings icon tints) |

### Category E: Splash Screen Gold Gradient `0xFFE8C96A / 0xFFB8860B`
The fallback `_ZIconPainter` uses a gold gradient for the diagonal Z slash. The new accent `#b18d4f` is close to `0xFFB8860B` (dark goldenrod). If the image asset is in use (`_useImageAssets = true`), this code path is never reached.

| File | Lines |
|------|-------|
| `lib/features/splash/presentation/pages/splash_page.dart` | 207 |

### Category F: Light Blue Tints in `login_page.dart` and `dashboard_page.dart`
| File | Color | Usage |
|------|-------|-------|
| `lib/features/auth/presentation/pages/login_page.dart` | `0xFFEAF7FD` | Domain-verified info box background |
| `lib/features/dashboard/presentation/pages/dashboard_page.dart` | `0xFFD6EAF8`, `0xFFAED6F1`, `0xFF5DADE2` | Profile photo placeholder gradient |
| `lib/features/guest_management/presentation/pages/guest_list_page.dart` | `0xFFDEEFF8`, `0xFFCDE8F6` | Empty-state and badge backgrounds (light blue tints) |

---

## 6. Is There a Dark Theme?

Yes. `AppTheme.darkTheme` is fully defined and wired into `MaterialApp.router`. However, `main.dart` line 49 hardcodes `themeMode: ThemeMode.light` instead of using the cubit-emitted value. The `ThemeCubit` exists and persists the user's choice to `SharedPreferences`, but the app never reads it because `themeMode` ignores the `BlocBuilder`'s `themeMode` parameter. This is a **bug** — the fix is one line in `main.dart` (change `themeMode: ThemeMode.light` to `themeMode: themeMode`).

---

## 7. Recommendations

### Required for the new `#02132f` / `#b18d4f` theme change

**Step 1 — Update `lib/core/theme/app_colors.dart`** (single source of truth):
- `primary` → `Color(0xFF02132F)` (new dark navy, replaces Google-blue `0xFF1A73E8`)
- `primaryDark` → `Color(0xFF010C1E)` (darker shade of navy, for pressed states)
- `primaryLight` → `Color(0xFF0A2550)` (lighter shade of navy, for dark theme use)
- `accent` → `Color(0xFFB18D4F)` (new gold, replaces teal `0xFF00BFA5`)
- Consider adding: `accentLight: Color(0xFFCFAD74)` and `accentDark: Color(0xFF8A6A38)` for hover/pressed states

**Step 2 — Fix hardcoded `0xFF29ABE2` (old brand sky-blue)** in these 9 files — replace with `AppColors.primary` or `AppColors.accent` as contextually appropriate:
- `lib/core/widgets/image_source_dialog.dart`
- `lib/features/splash/presentation/pages/splash_page.dart`
- `lib/features/dashboard/presentation/pages/dashboard_page.dart`
- `lib/features/dashboard/presentation/widgets/card_input_dialog.dart`
- `lib/features/dashboard/presentation/widgets/choose_card_dialog.dart`
- `lib/features/dashboard/presentation/widgets/scan_card_dialog.dart`
- `lib/features/guest_management/presentation/pages/guest_list_page.dart`
- `lib/features/scan/presentation/pages/mrz_scanner_page.dart`
- `lib/features/scan/presentation/widgets/mrz_result_sheet.dart`

**Step 3 — Update scan page golden `0xFFC8941A`** to `AppColors.accent` (`0xFFB18D4F`) in 4 files:
- `lib/features/scan/presentation/pages/domestic_card_scan_page.dart`
- `lib/features/scan/presentation/pages/domestic_passport_scan_page.dart`
- `lib/features/scan/presentation/pages/foreign_passport_scan_page.dart`
- `lib/features/scan/presentation/pages/profile_photo_camera_page.dart`

**Step 4 — Fix chip `selectedColor` hardcodes** in `app_theme.dart`:
- Light: `Color.fromRGBO(26, 115, 232, 0.15)` → `AppColors.primary.withValues(alpha: 0.15)`
- Dark: `Color.fromRGBO(74, 144, 226, 0.2)` → `AppColors.primaryLight.withValues(alpha: 0.20)`

**Step 5 (Optional) — Unify `0xFF2C3E50` with new primary**:  
The dark navy `0xFF2C3E50` used for text in multiple widgets is semantically close to the new `#02132f`. Consider mapping `0xFF2C3E50` → `AppColors.textPrimaryLight` or directly to `AppColors.primary` where it's used as a foreground/label color.

**Step 6 (Optional / Bug Fix) — Fix dark mode in `main.dart`**:
- Line 49: change `themeMode: ThemeMode.light` → `themeMode: themeMode` to actually use the cubit state.

**Step 7 — Background/surface tints**:
The light-blue tints (`0xFFEAF7FD`, `0xFFD6EAF8`, `0xFFDEEFF8`, etc.) used as subtle container backgrounds in the login, dashboard, and guest list pages will look out of place with a dark navy primary. These should be updated to navy-tinted versions (e.g., `AppColors.primary.withValues(alpha: 0.08)`) as part of the theme change.

---

## 8. Files NOT Needing Changes

- `lib/core/theme/app_text_styles.dart` — only references `AppColors.textSecondaryLight`, no primary colors
- `lib/features/splash/presentation/pages/splash_page.dart` (image path) — `_useImageAssets = true`, so `_ZeroSnapLogoWidget` is never rendered
- Status/semantic colors (`Colors.green`, `Colors.red`, `Colors.orange`) in scan and settings pages — intentional, should not be changed
