# File Line Count Analysis - Zerosnap Smart Check-In

## Total Dart Files: 74

## Files Sorted by Line Count (Descending)

### 🔴 Large Files (>1000 lines) - Refactoring Recommended

| Lines | File |
|-------|------|
| **2574** | `features/scan/presentation/pages/passport_card_scan_page.dart` |
| **2154** | `features/scan/presentation/pages/passport_form_page.dart` |
| **1306** | `features/scan/presentation/pages/card_scan_page.dart` |

**Total Large Files**: 3  
**Combined Lines**: 6,034 lines

---

### 🟡 Medium Files (500-1000 lines) - Consider Refactoring

| Lines | File |
|-------|------|
| 973 | `features/frro/presentation/pages/frro_list_page.dart` |
| 932 | `features/guest_management/presentation/pages/guest_list_page.dart` |
| 693 | `features/scan/presentation/widgets/signature_pad.dart` |

**Total Medium Files**: 3  
**Combined Lines**: 2,598 lines

---

### 🟢 Standard Files (200-500 lines) - Acceptable Size

| Lines | File |
|-------|------|
| 476 | `features/settings/presentation/pages/frro_credentials_page.dart` |
| 474 | `features/settings/presentation/pages/settings_page.dart` |
| 463 | `features/dashboard/presentation/widgets/choose_card_dialog.dart` |
| 374 | `features/auth/presentation/pages/login_page.dart` |
| 249 | `features/scan/presentation/pages/mrz_scanner_page.dart` |
| 241 | `core/theme/app_theme.dart` |
| 236 | `features/scan/presentation/widgets/mrz_result_sheet.dart` |
| 205 | `core/network/shared_preferences_provider.dart` |

**Total Standard Files**: 8  
**Combined Lines**: 2,718 lines

---

### ⚪ Small Files (<200 lines) - Well-Sized

| Lines | File |
|-------|------|
| 198 | `features/splash/presentation/pages/splash_page.dart` |
| 195 | `features/frro/data/datasources/guest_remote_data_source.dart` |
| 188 | `features/frro/domain/entities/guest.dart` |
| 187 | `features/scan/data/repositories/passport_repository.dart` |
| 186 | `features/dashboard/presentation/pages/dashboard_page.dart` |
| 182 | `features/dashboard/presentation/widgets/scan_card_dialog.dart` |
| 178 | `features/frro/data/models/guest_model.dart` |
| 148 | `features/frro/presentation/bloc/guest_list_bloc.dart` |
| 148 | `features/scan/data/repositories/card_scan_repository.dart` |
| 144 | `features/scan/domain/entities/mrz_result.dart` |
| 132 | `core/widgets/image_source_dialog.dart` |
| 127 | `features/dashboard/presentation/widgets/card_input_dialog.dart` |
| 103 | `core/network/api_base_helper.dart` |
| 94 | `features/auth/data/auth_repository.dart` |
| 92 | `features/frro/data/repositories/guest_repository_impl.dart` |
| 88 | `features/scan/domain/entities/lookup_models.dart` |
| 85 | `core/utils/image_crop_helper.dart` |
| 83 | `features/scan/presentation/utils/date_validator.dart` |
| 78 | `features/scan/presentation/widgets/duplicate_guest_checker.dart` |
| 78 | `features/frro/domain/entities/branch.dart` |
| 77 | `features/frro/presentation/widgets/guest_filter_dialog.dart` |
| 75 | `core/router/app_router.dart` |
| 70 | `core/theme/app_text_styles.dart` |
| 69 | `core/network/api_logger.dart` |
| 66 | `features/frro/presentation/bloc/guest_list_state.dart` |
| 64 | `features/frro/presentation/bloc/guest_list_event.dart` |
| 63 | `features/scan/presentation/utils/request_body_logger.dart` |
| 51 | `main.dart` |
| 51 | `core/di/injection_container.dart` |
| 49 | `features/guest_management/domain/entities/guest.dart` |
| 47 | `features/scan/presentation/pages/profile_crop_page.dart` |
| 46 | `core/config/api_constants.dart` |
| 40 | `features/frro/domain/entities/frro_registration.dart` |
| 38 | `core/theme/cubit/theme_cubit.dart` |
| 35 | `core/theme/app_colors.dart` |
| 27 | `features/frro/domain/usecases/get_guest_list.dart` |
| 26 | `features/scan/presentation/pages/passport_card_scan_page_landing.dart` |
| 26 | `features/scan/presentation/pages/passport_card_scan_page_domestic.dart` |
| 26 | `features/scan/presentation/utils/image_converter.dart` |
| 25 | `core/utils/app_version.dart` |
| 24 | `features/frro/domain/repositories/guest_repository.dart` |
| 22 | `core/errors/failures.dart` |
| 21 | `features/scan/presentation/pages/passport_form_page_landing.dart` |
| 21 | `features/scan/presentation/pages/passport_form_page_domestic.dart` |
| 18 | `features/frro/domain/usecases/check_in_guest.dart` |
| 16 | `core/errors/exceptions.dart` |
| 16 | `features/frro/domain/usecases/check_out_guest.dart` |
| 16 | `core/widgets/version_text.dart` |
| 16 | `features/scan/domain/entities/ocr_result.dart` |
| 12 | `features/guest_management/domain/usecases/add_guest.dart` |
| 12 | `features/guest_management/presentation/pages/guest_detail_page.dart` |
| 12 | `core/usecases/usecase.dart` |
| 11 | `features/guest_management/domain/repositories/guest_repository.dart` |
| 11 | `features/frro/presentation/pages/frro_form_page.dart` |
| 11 | `features/guest_management/presentation/pages/add_guest_page.dart` |
| 11 | `features/guest_management/domain/usecases/get_guests.dart` |
| 10 | `features/frro/domain/repositories/frro_repository.dart` |
| 9 | `features/frro/domain/usecases/update_frro_submission_status.dart` |
| 7 | `core/config/app_config.dart` |
| 5 | `core/constants/app_constants.dart` |

**Total Small Files**: 60  
**Combined Lines**: ~4,500 lines

---

## Summary Statistics

### By File Size Category

| Category | Count | Combined Lines | Avg Lines/File | Percentage |
|----------|-------|----------------|----------------|------------|
| 🔴 Large (>1000) | 3 | 6,034 | 2,011 | 38.6% |
| 🟡 Medium (500-1000) | 3 | 2,598 | 866 | 16.6% |
| 🟢 Standard (200-500) | 8 | 2,718 | 340 | 17.4% |
| ⚪ Small (<200) | 60 | ~4,500 | ~75 | 28.8% |
| **Total** | **74** | **~15,650** | **211** | **100%** |

### Top 10 Largest Files

| Rank | Lines | File | Refactor Priority |
|------|-------|------|-------------------|
| 1 | 2,574 | `passport_card_scan_page.dart` | 🔴 Critical |
| 2 | 2,154 | `passport_form_page.dart` | 🔴 Critical |
| 3 | 1,306 | `card_scan_page.dart` | 🔴 High |
| 4 | 973 | `frro_list_page.dart` | 🟡 Medium |
| 5 | 932 | `guest_list_page.dart` | 🟡 Medium |
| 6 | 693 | `signature_pad.dart` | 🟡 Low |
| 7 | 476 | `frro_credentials_page.dart` | ✅ Acceptable |
| 8 | 474 | `settings_page.dart` | ✅ Acceptable |
| 9 | 463 | `choose_card_dialog.dart` | ✅ Acceptable |
| 10 | 374 | `login_page.dart` | ✅ Acceptable |

---

## Refactoring Impact Analysis

### Current State
- **Total Lines**: ~15,650 lines
- **Files >1000 lines**: 3 files (6,034 lines)
- **Code concentration**: 38.6% of code in 4% of files

### After Phase 2 Refactoring (Target)

#### Top 3 Files Target Reduction

| File | Current | Target | Reduction | % |
|------|---------|--------|-----------|---|
| passport_card_scan_page.dart | 2,574 | 800 | -1,774 | -69% |
| passport_form_page.dart | 2,154 | 800 | -1,354 | -63% |
| card_scan_page.dart | 1,306 | 600 | -706 | -54% |
| **Total** | **6,034** | **2,200** | **-3,834** | **-64%** |

#### New Utility/Service Files (Estimated)
- Form field widgets: ~600 lines
- API body builders: ~400 lines
- Image handling service: ~300 lines
- OCR/MRZ services: ~500 lines
- Additional validators: ~200 lines
- **Total new files**: ~2,000 lines

#### Net Result
- **Before**: 15,650 lines total
- **After**: ~13,816 lines total
- **Net Reduction**: ~1,834 lines (11.7%)
- **Largest file after refactoring**: 800 lines (vs 2,574 now)

---

## Architecture Distribution

### By Feature Module

| Module | Files | Approx Lines | % of Total |
|--------|-------|--------------|------------|
| **scan** (Card scanning) | 18 | ~7,500 | 48% |
| **frro** (FRRO integration) | 15 | ~2,800 | 18% |
| **dashboard** | 4 | ~1,200 | 8% |
| **auth** | 2 | ~470 | 3% |
| **settings** | 2 | ~950 | 6% |
| **guest_management** | 6 | ~300 | 2% |
| **splash** | 1 | ~200 | 1% |
| **core** (shared utilities) | 20 | ~1,800 | 12% |
| **main** | 1 | ~50 | <1% |
| **Total** | **74** | **~15,650** | **100%** |

---

## Code Quality Metrics

### Maintainability Index

| Category | Metric | Value | Rating |
|----------|--------|-------|--------|
| Average file size | Lines/file | 211 | ✅ Good |
| Files >1000 lines | Count | 3 | ⚠️ Needs attention |
| Files <100 lines | Count | 42 | ✅ Excellent |
| Feature separation | Modules | 7 | ✅ Good |
| Shared utilities | Core files | 20 | ✅ Good |
| Code concentration | Top 3 files | 38.6% | ⚠️ Too high |

### Recommendations Priority

1. **🔴 Critical** - Refactor top 3 files (6,034 lines → 2,200 lines)
2. **🟡 Medium** - Review medium files for potential extraction
3. **✅ Monitor** - Keep small files focused and maintainable
4. **✅ Maintain** - Continue creating focused utility files

---

## Refactoring Progress

### Phase 1: ✅ Complete
- Created 3 utility files (~170 lines)
- Integrated into passport_form_page
- Reduced code duplication

### Phase 2: 🔲 Pending
- Extract form field widgets
- Create API body builders
- Extract image handling service
- Create OCR/MRZ services
- Expected reduction: 3,834 lines across top 3 files

---

**Analysis Date**: January 7, 2025  
**Total Dart Files**: 74  
**Total Lines**: ~15,650  
**Largest File**: passport_card_scan_page.dart (2,574 lines)  
**Smallest File**: app_constants.dart (5 lines)  
**Average File Size**: 211 lines
