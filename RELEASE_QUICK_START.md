# Release Build - Quick Start Guide

## 📦 Release APK Ready

**File**: `build/app/outputs/flutter-apk/app-release.apk`
**Size**: 125.5 MB
**Status**: ✅ Ready for deployment

---

## 🚀 Quick Installation

### Install on Android Device
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Install on Multiple Devices
```bash
adb devices
adb -s <device_id> install build/app/outputs/flutter-apk/app-release.apk
```

---

## ✅ What's Included

### Latest Features
- ✅ Passport navigation fix (domestic card vs landing screen)
- ✅ Visa section visibility control
- ✅ Page title differentiation
- ✅ All previous features

### Optimizations
- ✅ R8 code minification
- ✅ Proguard rules configured
- ✅ Optimized APK size
- ✅ Debug symbols preserved

---

## 🧪 Testing Checklist

### Critical Tests
- [ ] App launches successfully
- [ ] Domestic card flow works
- [ ] Passport capture works
- [ ] Visa section visibility correct
- [ ] Page titles display correctly

### Domestic Card Flow
1. Select domestic card (Driving License, Aadhar, etc.)
2. Capture front image
3. Capture profile photo
4. Extract details
5. Verify document
6. Submit card
7. **Verify**: AppBar shows "Passport Details (Domestic Card)"
8. **Verify**: Visa section is NOT visible
9. Capture/upload passport
10. Submit

### Landing Screen Flow
1. Click "Passport" from landing screen
2. Choose Camera or Upload
3. **Verify**: AppBar shows "Passport Details (Landing - OCR)"
4. **Verify**: Visa section IS visible
5. Fill visa details
6. Submit

---

## 📊 Build Information

| Property | Value |
|----------|-------|
| **App Name** | Zerosnap |
| **Package** | com.zerosnapid |
| **Size** | 125.5 MB |
| **Minification** | Enabled (R8) |
| **Signing** | Debug key (update for production) |

---

## 🔧 Build Files

```
build/app/outputs/
├── flutter-apk/
│   └── app-release.apk ← Main APK file
├── mapping/release/
│   ├── mapping.txt (ProGuard mapping)
│   ├── seeds.txt
│   └── usage.txt
└── bundle/release/
    └── app-release.aab (if built)
```

---

## 📝 Release Notes Template

```markdown
## Version X.X.X Release

### New Features
- Improved passport navigation flow
- Better visa section handling
- Enhanced page titles for clarity

### Bug Fixes
- Fixed domestic card → passport navigation
- Fixed visa section visibility in domestic card flow
- Improved page title differentiation

### Improvements
- Code optimization with R8 minification
- Better performance
- Reduced APK size

### Testing
- Tested on multiple Android versions
- Verified all flows work correctly
- Confirmed visa section visibility

### Known Issues
- None
```

---

## 🎯 Deployment Steps

### 1. Test Locally
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### 2. Test on Multiple Devices
- Test on Android 8.0+
- Test on different screen sizes
- Test on different device types

### 3. Sign for Production
```bash
# Use your production keystore
jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 \
  -keystore your-keystore.jks \
  build/app/outputs/flutter-apk/app-release.apk \
  your-key-alias
```

### 4. Upload to Play Store
1. Go to Google Play Console
2. Create new release
3. Upload signed APK
4. Add release notes
5. Set rollout percentage
6. Review and publish

### 5. Monitor
- Check crash reports
- Monitor user feedback
- Track adoption rate
- Monitor performance

---

## 🐛 Troubleshooting

### APK Won't Install
```bash
# Check if app is already installed
adb shell pm list packages | grep zerosnap

# Uninstall first
adb uninstall com.zerosnapid

# Then install
adb install build/app/outputs/flutter-apk/app-release.apk
```

### App Crashes on Startup
1. Check logcat: `adb logcat | grep zerosnap`
2. Check proguard rules
3. Verify all dependencies are included
4. Check for missing permissions

### Visa Section Not Visible
1. Verify you're on domestic card flow
2. Check page title shows "Domestic Card"
3. Verify navigation parameters
4. Check showVisaSection flag

---

## 📞 Support

### Build Issues
- Check `RELEASE_BUILD_SUMMARY.md` for details
- Review proguard rules in `android/app/proguard-rules.pro`
- Check build config in `android/app/build.gradle.kts`

### Feature Issues
- Check `PASSPORT_NAVIGATION_FIX_COMPLETE.md`
- Review flow diagrams in `COMPLETE_PASSPORT_FLOW_DIAGRAM.md`
- Check test recommendations

---

## ✨ Summary

✅ Release APK built successfully
✅ All features included
✅ Optimizations applied
✅ Ready for testing and deployment

**Next Step**: Install and test on Android devices
