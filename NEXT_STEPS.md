# Next Steps

## Implementation Complete ✅

The separate passport pages have been successfully created and all navigation has been updated. Here's what you need to do next:

## 1. Rebuild the App

Since constructor parameters have changed, you need a **complete rebuild** (not hot reload):

```bash
flutter clean
flutter pub get
flutter run
```

**Important:** Hot reload will NOT work for constructor parameter changes. You must do a full rebuild.

## 2. Test All Flows

### Test Domestic Card Flow
1. From dashboard, select "Choose Card"
2. Select any domestic card (Driving License, Aadhar, Voters ID, PAN Card, Other ID)
3. Complete the card scanning/form
4. Verify:
   - ✅ Visa section is NOT visible in the passport form
   - ✅ Can fill passport details
   - ✅ Can sign
   - ✅ Submission works without visa fields

### Test Landing Screen - OCR Flow
1. From dashboard, select "Choose Card"
2. Select "Passport"
3. Choose "Open Camera" or "Upload"
4. Verify:
   - ✅ Visa section IS visible in the passport form
   - ✅ Can add visa details
   - ✅ Can select visa type
   - ✅ Can upload visa images (for e-Visa, OCI, Diplomat)
   - ✅ Submission includes visa fields

### Test Landing Screen - MRZ Flow
1. From dashboard, select "Choose Card"
2. Select "Passport"
3. Choose "Open Camera" or "Upload"
4. If MRZ is enabled, MRZ scanner will open
5. Verify:
   - ✅ Visa section IS visible in the passport form
   - ✅ Can add visa details
   - ✅ Can select visa type
   - ✅ Can upload visa images (for e-Visa, OCI, Diplomat)
   - ✅ Submission includes visa fields

## 3. Verify No Regressions

- [ ] All existing flows still work
- [ ] No crashes or errors
- [ ] Form validation works correctly
- [ ] Data submission succeeds
- [ ] Images are captured and uploaded correctly
- [ ] Signatures are captured correctly

## 4. Code Review Checklist

When reviewing the changes:

- [ ] New pages are simple wrappers (no logic duplication)
- [ ] All imports are correct
- [ ] All navigation points updated
- [ ] No references to old boolean flag approach
- [ ] Class names clearly indicate the flow
- [ ] No breaking changes to existing code

## 5. Optional: Future Improvements

### Remove showVisaSection Parameter (After Migration)
Once all code uses the new dedicated pages, you can remove the `showVisaSection` parameter from the base classes:

```dart
// Before
class PassportFormPage extends StatefulWidget {
  final bool showVisaSection;  // ← Remove this
  const PassportFormPage({
    super.key,
    this.scannedResult,
    this.showVisaSection = true,  // ← Remove this
  });
}

// After
class PassportFormPage extends StatefulWidget {
  const PassportFormPage({
    super.key,
    this.scannedResult,
  });
}
```

Then remove all conditional rendering based on `showVisaSection`:

```dart
// Before
if (widget.showVisaSection) ...[
  _buildVisaCard(),
  const SizedBox(height: 16),
],

// After
_buildVisaCard(),
const SizedBox(height: 16),
```

### Add Flow-Specific Logic
If domestic and landing flows need different behavior in the future:

```dart
// PassportCardScanPageDomestic
class PassportCardScanPageDomestic extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PassportCardScanPage(
      initialFrontImagePath: initialFrontImagePath,
      autoOpenCamera: autoOpenCamera,
      showVisaSection: false,
    );
  }
  
  // Can add domestic-specific methods here
  void _domesticSpecificLogic() {
    // ...
  }
}
```

### Add Unit Tests
Create tests for the new pages:

```dart
// test/features/scan/presentation/pages/passport_card_scan_page_domestic_test.dart
void main() {
  testWidgets('PassportCardScanPageDomestic hides visa section', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PassportCardScanPageDomestic(),
      ),
    );
    
    expect(find.byType(VisaSection), findsNothing);
  });
}
```

## 6. Documentation

The following documentation has been created:

1. **SEPARATE_PASSPORT_PAGES_IMPLEMENTATION.md** - Detailed implementation guide
2. **PASSPORT_PAGES_QUICK_REFERENCE.md** - Quick reference for developers
3. **PASSPORT_PAGES_ARCHITECTURE.md** - Architecture diagrams and flows
4. **TASK_COMPLETION_SUMMARY.md** - Summary of what was done
5. **NEXT_STEPS.md** - This file

Share these with your team for reference.

## 7. Commit and Push

After testing, commit the changes:

```bash
git add .
git commit -m "feat: Create separate dedicated passport pages for domestic and landing flows

- Create PassportCardScanPageDomestic for domestic card flow (no visa)
- Create PassportCardScanPageLanding for landing screen OCR flow (with visa)
- Create PassportFormPageDomestic for domestic card MRZ flow (no visa)
- Create PassportFormPageLanding for landing screen MRZ flow (with visa)
- Update navigation in card_scan_page.dart
- Update navigation in mrz_scanner_page.dart
- Update navigation in choose_card_dialog.dart

Benefits:
- Type-safe navigation (no boolean flag confusion)
- Clear intent in class names
- Easier to maintain and extend
- Self-documenting code"
```

## 8. Troubleshooting

### Issue: Visa section still visible in domestic flow
**Solution:** Make sure you did a full rebuild (`flutter clean && flutter pub get && flutter run`), not just hot reload.

### Issue: Visa section not visible in landing flow
**Solution:** Check that you're using `PassportCardScanPageLanding` or `PassportFormPageLanding`, not the base classes.

### Issue: Import errors
**Solution:** Make sure all imports are correct:
- `card_scan_page.dart` imports `passport_card_scan_page_domestic.dart`
- `mrz_scanner_page.dart` imports `passport_form_page_landing.dart`
- `choose_card_dialog.dart` imports both landing pages

### Issue: Navigation not working
**Solution:** Check that all navigation calls use the correct page class names (with `Domestic` or `Landing` suffix).

## 9. Questions?

Refer to:
- **PASSPORT_PAGES_QUICK_REFERENCE.md** - For quick answers
- **PASSPORT_PAGES_ARCHITECTURE.md** - For understanding the design
- **SEPARATE_PASSPORT_PAGES_IMPLEMENTATION.md** - For detailed information

## Summary

✅ **What's Done:**
- 4 new wrapper pages created
- 3 files updated with new navigation
- All imports verified
- No compilation errors
- Documentation created

🔄 **What You Need to Do:**
1. Rebuild the app (`flutter clean && flutter pub get && flutter run`)
2. Test all flows (domestic, landing OCR, landing MRZ)
3. Verify no regressions
4. Commit and push changes
5. Share documentation with team

🎉 **Result:**
- Type-safe navigation
- Clear, self-documenting code
- Easier to maintain and extend
- Better separation of concerns
