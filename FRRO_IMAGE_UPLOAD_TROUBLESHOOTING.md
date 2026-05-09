# FRRO Image Upload - Troubleshooting Guide

## 🔍 Error: "Failed to fetch" / CSP Violation

### Symptoms
```
❌ Image conversion failed: Failed to fetch
Fetch API cannot load data:image/jpeg;base64,...
Refused to connect because it violates CSP
```

### Root Cause
The error occurs when old cached code tries to use `fetch()` API, which is blocked by Content Security Policy.

### ✅ Solution
The code has been updated to use `atob()` instead of `fetch()`. Follow these steps:

#### Step 1: Verify Code is Updated
```bash
# Check for atob() usage (should find it)
grep "atob" lib/features/frro/presentation/pages/frro_list_page.dart

# Check for fetch() usage (should find nothing)
grep "fetch(" lib/features/frro/presentation/pages/frro_list_page.dart
```

#### Step 2: Clean Build
```bash
flutter clean
flutter pub get
```

#### Step 3: Rebuild App
```bash
# Debug mode
flutter run

# Release mode (recommended for testing)
flutter run --release
```

#### Step 4: Clear WebView Cache (if needed)
Add this code before loading FRRO page:
```dart
await _webCtrl.clearCache();
await _webCtrl.clearLocalStorage();
```

#### Step 5: Test Again
1. Open app
2. Select guest with profile picture
3. Navigate to FRRO form
4. Check console for success messages

### Expected Output After Fix
```
📸 Starting image upload to Personal Details section...
✅ Image preview set successfully: #photoPreview
✅ Image data set in hidden field: #photo_data
🔄 Converting base64 to File object...
✅ File created: guest_photo.jpg (152847 bytes)
✅ Image file set successfully: #photo
📸 Profile image upload to Personal Details section completed
```

## 🎯 Quick Fixes

### Fix 1: Rebuild App
```bash
flutter clean && flutter pub get && flutter run --release
```

### Fix 2: Uninstall and Reinstall
```bash
# Uninstall from device
adb uninstall com.zerosnap.app

# Reinstall
flutter run --release
```

### Fix 3: Clear All Caches
```bash
# Flutter cache
flutter clean

# Gradle cache (Android)
cd android
./gradlew clean
cd ..

# Rebuild
flutter pub get
flutter run
```

## 📊 Verification Checklist

- [ ] Code uses `atob()` not `fetch()`
- [ ] No `fetch(` found in frro_list_page.dart
- [ ] App rebuilt after code update
- [ ] WebView cache cleared
- [ ] Console shows success messages
- [ ] No CSP errors in console
- [ ] Image appears in form
- [ ] Form validates successfully

## 🎉 Success Indicators

✅ Console shows: `✅ File created: guest_photo.jpg`  
✅ Console shows: `✅ Image file set successfully`  
✅ No CSP errors  
✅ Image visible in Personal Details section  
✅ Form accepts the image  

## 📝 Summary

**Problem**: CSP blocks `fetch()` API  
**Solution**: Use `atob()` for base64 decoding  
**Action**: Rebuild app to use updated code  
**Result**: Image uploads successfully without CSP errors  

The fix is already in the code - just rebuild your app! 🚀
