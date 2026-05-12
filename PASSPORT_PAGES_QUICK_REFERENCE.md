# Passport Pages Quick Reference

## When to Use Which Page

### For Domestic Card Flow (No Visa)
Use: **PassportCardScanPageDomestic**
- When: After user completes domestic card (Driving License, Aadhar, Voters ID, PAN Card, Other ID)
- Visa Section: ❌ Hidden
- Example:
  ```dart
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(
      builder: (_) => const PassportCardScanPageDomestic(),
    ),
  );
  ```

### For Landing Screen - OCR Flow (With Visa)
Use: **PassportCardScanPageLanding**
- When: User selects Passport from landing screen and chooses OCR (Camera or Gallery)
- Visa Section: ✅ Visible
- Example:
  ```dart
  nav.push(
    MaterialPageRoute(
      builder: (_) => const PassportCardScanPageLanding(
        autoOpenCamera: true,
      ),
    ),
  );
  ```

### For Landing Screen - MRZ Flow (With Visa)
Use: **PassportFormPageLanding**
- When: User selects Passport from landing screen and chooses MRZ (Camera or Gallery)
- Visa Section: ✅ Visible
- Example:
  ```dart
  nav.push(
    MaterialPageRoute(
      builder: (_) => PassportFormPageLanding(
        scannedResult: result,
      ),
    ),
  );
  ```

## Page Hierarchy

```
PassportCardScanPage (base class with showVisaSection parameter)
├── PassportCardScanPageDomestic (wrapper, showVisaSection: false)
└── PassportCardScanPageLanding (wrapper, showVisaSection: true)

PassportFormPage (base class with showVisaSection parameter)
├── PassportFormPageDomestic (wrapper, showVisaSection: false)
└── PassportFormPageLanding (wrapper, showVisaSection: true)
```

## Navigation Sources

| Source | Page Used | Visa Section |
|--------|-----------|--------------|
| CardScanPage (after domestic card) | PassportCardScanPageDomestic | ❌ No |
| choose_card_dialog (Passport → Camera OCR) | PassportCardScanPageLanding | ✅ Yes |
| choose_card_dialog (Passport → Gallery OCR) | PassportCardScanPageLanding | ✅ Yes |
| choose_card_dialog (Passport → Camera MRZ) | PassportFormPageLanding | ✅ Yes |
| choose_card_dialog (Passport → Gallery MRZ) | PassportFormPageLanding | ✅ Yes |
| MrzScannerPage (passport mode) | PassportFormPageLanding | ✅ Yes |

## Key Differences

### PassportCardScanPageDomestic vs PassportCardScanPageLanding

| Feature | Domestic | Landing |
|---------|----------|---------|
| Visa Section | Hidden | Visible |
| Visa Fields in Submission | Not included | Included |
| Use Case | Domestic card flow | Foreign visitor flow |
| Visa Validation | Skipped | Required |

## Constructor Parameters

### PassportCardScanPageDomestic
```dart
const PassportCardScanPageDomestic({
  super.key,
  this.initialFrontImagePath,  // Optional: pre-fill front image
  this.autoOpenCamera = false,  // Optional: auto-open camera
});
```

### PassportCardScanPageLanding
```dart
const PassportCardScanPageLanding({
  super.key,
  this.initialFrontImagePath,  // Optional: pre-fill front image
  this.autoOpenCamera = false,  // Optional: auto-open camera
});
```

### PassportFormPageDomestic
```dart
const PassportFormPageDomestic({
  super.key,
  this.scannedResult,  // Optional: MRZ scan result
});
```

### PassportFormPageLanding
```dart
const PassportFormPageLanding({
  super.key,
  this.scannedResult,  // Optional: MRZ scan result
});
```

## Migration Guide

If you have existing code using the old approach:

### Old Way (Don't Use)
```dart
// ❌ Avoid this - confusing boolean flag
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => PassportCardScanPage(
      showVisaSection: false,  // What does this mean?
    ),
  ),
);
```

### New Way (Use This)
```dart
// ✅ Clear and explicit
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => const PassportCardScanPageDomestic(),
  ),
);
```

## Testing Checklist

- [ ] Domestic card flow: Visa section is hidden
- [ ] Domestic card flow: Submission works without visa fields
- [ ] Landing screen OCR: Visa section is visible
- [ ] Landing screen OCR: Can add visa details
- [ ] Landing screen MRZ: Visa section is visible
- [ ] Landing screen MRZ: Can add visa details
- [ ] All flows: Form validation works correctly
- [ ] All flows: Submission succeeds with correct data
