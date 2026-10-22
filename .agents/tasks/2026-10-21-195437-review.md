# Passport portrait auto-extraction

Adds automatic extraction of the passport portrait photo from captured passport front pages, pre-populating the profile photo section in PassportCardScanPage. The extraction uses a fixed region heuristic based on ICAO 9303 standard positioning (left side: 5-25% horizontal, 25-75% vertical). Manual crop via `cropProfileFromCard` remains available as a fallback when auto-extraction produces a poor result.

The integration happens immediately after front OCR in both domestic and foreign scan flows. When extraction succeeds, the cropped portrait path is passed to PassportCardScanPage via the new `initialProfileImagePath` parameter. When extraction fails (returns null), the form falls back to showing the full front page as the profile image, and users can manually crop.

**Watch for:** Retake flow loses the auto-extracted profile (confirmed), no test coverage for the extractor (confirmed), silent error swallowing obscures decode and I/O failures (confirmed), orphaned profile files accumulate with no cleanup strategy (likely).

**Verdict**: CHANGES_REQUESTED

---

## High-level view

The extractor uses `img.copyCrop` with percentage-based coordinates derived from ICAO standards. The crop region is clamped to image bounds, encoded as JPEG at quality 90, and saved with a timestamp filename in the same directory as the source. Any failure in the pipeline returns null.

Integration happens in `_runFrontOcr` and `_runPassportFrontOcr` after OCR completes. The extracted path is stored in a new `_profileImagePath` state field and passed forward to PassportCardScanPage's `initialProfileImagePath` parameter, which pre-populates the profile section on mount.

The retake flow constructs `ScanRetakeResult` without including the auto-extracted profile path, so when a user retakes the front page from the form, the new extraction is discarded and the form reverts to showing the full front image. This breaks the feature in a common use case.

Manual crop remains intact: tapping the profile photo tile opens a bottom sheet with "Crop from Passport" and "Pick New Photo" options. The crop option calls `cropProfileFromCard`, which lets users interactively select the portrait region.

Error handling is a catch-all that silently returns null. File I/O errors, decode failures, and encoding issues are indistinguishable to the caller. The form has no indication whether extraction failed due to a corrupted image, missing file, or out-of-memory condition.

Multiple extractions (initial capture, then retake, then another retake) write `profile_<timestamp>.jpg` files to the same directory with no cleanup. Each extraction orphans the prior file. Over time, the app's image directory fills with unused portrait crops.

---

<details>
<summary>Issues (4)</summary>

1. **Retake flow discards auto-extracted profile** — `ScanRetakeResult` doesn't carry the extracted profile path, so retaking the front page loses the new extraction. Either add a `profileImagePath` field to `ScanRetakeResult` or re-run extraction in `_retakeWithScanner` when the result comes back.

2. **No test coverage for extractor** — `passport_portrait_extractor.dart` has no unit tests. Add tests covering: successful extraction with valid passport image, null return on decode failure, null return on I/O error, bounds clamping edge cases, output file creation.

3. **Silent error swallowing** — The catch-all `catch (_)` hides decode failures, I/O errors, and encoding issues from logs. Log the exception type and message before returning null so failures can be diagnosed in production.

4. **Orphaned profile files accumulate** — Each extraction writes `profile_<timestamp>.jpg` with no cleanup of prior extractions. When a user retakes the front page multiple times, the directory fills with unused files. Either reuse a fixed filename (`profile_latest.jpg`) or delete the old file before writing a new one.

</details>

---

<details>
<summary>Details</summary>

## Region-based extraction with fixed ICAO heuristic

The extractor reads the passport front image, decodes it, and crops a fixed rectangular region corresponding to the left-side portrait location in ICAO 9303 standard passports. The region is defined as percentages of image dimensions:

```dart
final x = (imageWidth * 0.05).round(); // 5% from left
final y = (imageHeight * 0.25).round(); // 25% from top
final width = (imageWidth * 0.20).round(); // 20% of image width
final height = (imageHeight * 0.50).round(); // 50% of image height
```

Values are clamped to stay within image bounds to prevent `copyCrop` from throwing. The cropped region is encoded as JPEG at quality 90 and written to `profile_<timestamp>.jpg` in the same directory as the source.

This approach works when the passport is well-aligned and the portrait is in the expected position. It breaks when:
- The passport is rotated or skewed
- The portrait is in a non-standard position (some older passport formats)
- The captured image is cropped or zoomed in a way that shifts the percentages

When extraction produces a poor crop, the user can manually re-crop via the "Crop from Passport" option in the profile photo bottom sheet.

## Retake flow loses auto-extracted profile

When a user taps the front image tile in PassportCardScanPage to retake the passport front, the form calls `_retakeWithScanner`, which opens the scan page in retake mode. After the user captures and confirms the new front image, the scan page pops back with a `ScanRetakeResult` containing:

```dart
Navigator.of(context).pop(
  ScanRetakeResult(
    target: ScanRetakeTarget.passportFront,
    imagePath: path,
    ocrData: _passportOcrData,
  ),
);
```

The scan page runs extraction and stores the new profile path in its local `_profileImagePath` state, but this path is never included in the `ScanRetakeResult`. The form receives the new front image path and OCR data, but the profile path is lost. The form's retake handler doesn't re-run extraction:

```dart
case ScanRetakeTarget.passportFront:
  setState(() {
    _frontImagePath = result.imagePath;
    if (_profileImagePath.isEmpty) {
      _profileImagePath = result.imagePath;
    }
  });
```

If `_profileImagePath` is already populated (from the initial capture), it stays unchanged and now points to a portrait cropped from the *old* front image. If it's empty (edge case), it falls back to showing the full new front image, which is correct but bypasses the auto-extraction that just ran.

**Confirmed** — The retake flow does not carry the extracted profile path, breaking the feature when users retake the front page.

## Error handling swallows all failures silently

The extractor wraps the entire extraction pipeline in a try-catch that returns null on any exception:

```dart
try {
  // ... read, decode, crop, encode, write ...
  return outputPath;
} catch (_) {
  return null;
}
```

This catch-all swallows:
- File I/O errors (file not found, permission denied)
- Decode failures (corrupted image, unsupported format)
- Out-of-memory errors during crop or encode
- Directory access failures when writing the output

The form receives null and falls back to showing the full front image. From the user's perspective, auto-extraction appears to have failed, but no diagnostic information is available. In production logs, there's no way to distinguish between "image was corrupted" and "disk was full" or "image format unsupported."

**Confirmed** — Silent catch-all prevents diagnosis of extraction failures.

## File cleanup gap leaves orphaned extractions

Each extraction writes a new file with a timestamp-based name:

```dart
final outputPath =
    '${directory.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
await File(outputPath).writeAsBytes(croppedBytes);
```

When a user:
1. Captures passport front → writes `profile_1729522794000.jpg`
2. Retakes passport front → writes `profile_1729522810000.jpg`
3. Retakes again → writes `profile_1729522825000.jpg`

The first two files remain on disk, unused. Each retake adds another orphan. Over the app's lifetime, the image directory accumulates these files, consuming storage and potentially causing performance degradation when the OS scans the directory.

The app never deletes old profile extractions. There's no cleanup in the extractor, no lifecycle hook in the form, and no background task to prune unused files.

**Likely** — The timestamp pattern guarantees new files on every extraction, and there's no cleanup code visible in the diff or the scan page state management. The only uncertainty is whether some other part of the app (not touched by this diff) already implements a directory cleanup strategy for temporary images.

## Test coverage missing for extractor

`passport_portrait_extractor.dart` has no test file. **Confirmed** — The grep search for `extractPassportPortrait` in `test/**/*.dart` returned no matches.

</details>

---

## File map

<details>
<summary>4 files changed</summary>

- `lib/core/utils/passport_portrait_extractor.dart` — New utility function for extracting passport portrait using ICAO-based region heuristic
- `lib/features/scan/presentation/pages/domestic_passport_scan_page.dart` — Auto-extract profile after front OCR, pass to form via `initialProfileImagePath`
- `lib/features/scan/presentation/pages/foreign_passport_scan_page.dart` — Auto-extract profile after front OCR, pass to form via `initialProfileImagePath`
- `lib/features/scan/presentation/pages/passport_card_scan_page.dart` — Accept `initialProfileImagePath` parameter, pre-populate profile photo section on mount

Full diff: `git diff HEAD~1 HEAD`

</details>
