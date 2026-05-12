# Passport Page Titles - Quick Reference

## The 4 Scenarios and Their Titles

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    SCENARIO 1: Domestic Card → OCR                      │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Page: PassportCardScanPageDomestic                                     │
│  Title: "Passport Details (Domestic Card)"                              │
│  Visa: ❌ Hidden                                                         │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ Passport Details (Domestic Card)                                 │  │
│  ├──────────────────────────────────────────────────────────────────┤  │
│  │                                                                  │  │
│  │  Passport form WITHOUT visa section                             │  │
│  │                                                                  │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                  SCENARIO 2: Landing Screen → OCR                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Page: PassportCardScanPageLanding                                      │
│  Title: "Passport Details (Landing - OCR)"                              │
│  Visa: ✅ Visible                                                        │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ Passport Details (Landing - OCR)                                 │  │
│  ├──────────────────────────────────────────────────────────────────┤  │
│  │                                                                  │  │
│  │  Passport form WITH visa section                                │  │
│  │                                                                  │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                  SCENARIO 3: Landing Screen → MRZ                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Page: PassportFormPageLanding                                          │
│  Title: "Passport Details (Landing - MRZ)"                              │
│  Visa: ✅ Visible                                                        │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ Passport Details (Landing - MRZ)                                 │  │
│  ├──────────────────────────────────────────────────────────────────┤  │
│  │                                                                  │  │
│  │  Passport form WITH visa section                                │  │
│  │  (Pre-filled from MRZ scan)                                     │  │
│  │                                                                  │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│              SCENARIO 4: Domestic Card → MRZ (NOT SUPPORTED)            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Page: PassportFormPageDomestic                                         │
│  Title: "Passport Details (Domestic Card)"                              │
│  Visa: ❌ Hidden                                                         │
│  Status: ❌ NOT CURRENTLY USED                                           │
│                                                                          │
│  (Reserved for future use if MRZ support is added to domestic flow)    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Title Mapping

| Scenario | Page | Title |
|----------|------|-------|
| Domestic → OCR | PassportCardScanPageDomestic | **Passport Details (Domestic Card)** |
| Landing → OCR | PassportCardScanPageLanding | **Passport Details (Landing - OCR)** |
| Landing → MRZ | PassportFormPageLanding | **Passport Details (Landing - MRZ)** |
| Domestic → MRZ | PassportFormPageDomestic | **Passport Details (Domestic Card)** |

---

## How to Identify Which Page is Active

When you see the AppBar title, you immediately know:

### "Passport Details (Domestic Card)"
- ✅ User is in domestic card flow
- ✅ Visa section is hidden
- ✅ No visa fields will be submitted
- ✅ For Indian residents

### "Passport Details (Landing - OCR)"
- ✅ User is in landing screen flow
- ✅ Using OCR (image capture/upload)
- ✅ Visa section is visible
- ✅ For foreign visitors

### "Passport Details (Landing - MRZ)"
- ✅ User is in landing screen flow
- ✅ Using MRZ (passport scan)
- ✅ Visa section is visible
- ✅ For foreign visitors

---

## Code Reference

### Domestic Card Flow
```dart
// In card_scan_page.dart
Navigator.of(context).pushReplacement(
  MaterialPageRoute(
    builder: (_) => const PassportCardScanPageDomestic(),
  ),
);
// Shows: "Passport Details (Domestic Card)"
```

### Landing Screen - OCR Flow
```dart
// In choose_card_dialog.dart
nav.push(
  MaterialPageRoute(
    builder: (_) => const PassportCardScanPageLanding(
      autoOpenCamera: true,
    ),
  ),
);
// Shows: "Passport Details (Landing - OCR)"
```

### Landing Screen - MRZ Flow
```dart
// In mrz_scanner_page.dart
Navigator.of(context).pushReplacement(
  MaterialPageRoute(
    builder: (_) => PassportFormPageLanding(scannedResult: result),
  ),
);
// Shows: "Passport Details (Landing - MRZ)"
```

---

## User Experience

Users will see clear titles that help them understand:

1. **Which flow they're in** (Domestic vs Landing)
2. **Which method is being used** (OCR vs MRZ)
3. **What to expect** (Visa section or not)

Example user journey:

```
User: "I'm filling out a passport form"
     ↓
Sees: "Passport Details (Landing - OCR)"
     ↓
Understands: "I'm on the landing screen, using OCR, and I'll need to add visa details"
```

---

## Developer Experience

Developers can quickly identify:

1. **Which page is active** by looking at the AppBar
2. **Which scenario is being tested** during debugging
3. **Which flow the user is in** when troubleshooting issues

Example debugging:

```
Developer: "Why is the visa section hidden?"
     ↓
Checks AppBar: "Passport Details (Domestic Card)"
     ↓
Understands: "This is the domestic card flow, visa section should be hidden"
```

---

## Testing Checklist

- [ ] Domestic Card flow shows: **"Passport Details (Domestic Card)"**
- [ ] Landing OCR flow shows: **"Passport Details (Landing - OCR)"**
- [ ] Landing MRZ flow shows: **"Passport Details (Landing - MRZ)"**
- [ ] Visa section visibility matches the title
- [ ] All forms work correctly

---

## Summary

✅ **Clear, descriptive titles** for all four scenarios
✅ **Easy to identify** which page is active
✅ **Better user experience** with context-aware titles
✅ **Easier debugging** for developers
✅ **Backward compatible** with default titles

The titles make it immediately obvious which scenario is being used!
