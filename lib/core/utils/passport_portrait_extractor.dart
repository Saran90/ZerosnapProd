import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

/// Automatically extracts the passport portrait photo from a captured passport
/// front page image using ML Kit face detection.
///
/// This function uses Google ML Kit to detect faces in the passport image and
/// intelligently crops around the detected face with proper margins to match
/// passport photo standards (35mm × 45mm, aspect ratio 0.778:1).
///
/// **Fallback strategy**: If face detection fails or no face is found, falls
/// back to region-based heuristic using ICAO 9303 standard layout positions.
///
/// The extracted portrait is saved next to the source image using a
/// **timestamp-based filename** (`profile_<ms>.jpg`). The caller is
/// responsible for deleting [previousProfilePath] when calling during a
/// retake so old extractions don't accumulate.
///
/// Returns the file path to the cropped portrait image, or null if extraction
/// fails for any reason (file I/O error, decode failure, etc.).
Future<String?> extractPassportPortrait(
  String passportFrontImagePath, {
  String? previousProfilePath,
}) async {
  try {
    // ── Delete previous extraction before writing a new one ─────────────────
    if (previousProfilePath != null && previousProfilePath.isNotEmpty) {
      try {
        final prev = File(previousProfilePath);
        if (await prev.exists()) {
          await prev.delete();
          debugPrint(
            'PassportPortraitExtractor: Deleted previous extraction: $previousProfilePath',
          );
        }
      } catch (e) {
        debugPrint(
          'PassportPortraitExtractor: Could not delete previous extraction: $e',
        );
      }
    }

    // ── Decode source image ──────────────────────────────────────────────────
    final bytes = await File(passportFrontImagePath).readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) {
      debugPrint(
        'PassportPortraitExtractor: Failed to decode image at $passportFrontImagePath',
      );
      return null;
    }

    final imageWidth = image.width;
    final imageHeight = image.height;

    // ── Detect face with ML Kit ──────────────────────────────────────────────
    final cropRect = await _detectFaceAndGetCropRect(
      passportFrontImagePath,
      imageWidth,
      imageHeight,
    );

    final int cropX;
    final int cropY;
    final int cropWidth;
    final int cropHeight;

    if (cropRect != null) {
      cropX = cropRect['x']!;
      cropY = cropRect['y']!;
      cropWidth = cropRect['width']!;
      cropHeight = cropRect['height']!;
      debugPrint(
        'PassportPortraitExtractor: Using face detection '
        '($cropWidth x $cropHeight at $cropX,$cropY)',
      );
    } else {
      debugPrint(
        'PassportPortraitExtractor: Face detection failed — using heuristic fallback',
      );
      final fallback = _getFallbackCropRect(imageWidth, imageHeight);
      cropX = fallback['x']!;
      cropY = fallback['y']!;
      cropWidth = fallback['width']!;
      cropHeight = fallback['height']!;
    }

    if (cropWidth < 50 || cropHeight < 50) {
      debugPrint(
        'PassportPortraitExtractor: Crop dimensions too small (${cropWidth}x$cropHeight)',
      );
      return null;
    }

    // ── Crop and save ────────────────────────────────────────────────────────
    final croppedImage = img.copyCrop(
      image,
      x: cropX,
      y: cropY,
      width: cropWidth,
      height: cropHeight,
    );

    final croppedBytes = img.encodeJpg(croppedImage, quality: 90);

    // Use a timestamp filename so each session produces a unique file.
    // This prevents a stale file from a previous session from ever being
    // accidentally shown — the caller always gets a fresh path.
    final sourceFile = File(passportFrontImagePath);
    final directory = sourceFile.parent;
    final outputPath =
        '${directory.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';

    await File(outputPath).writeAsBytes(croppedBytes);

    debugPrint(
      'PassportPortraitExtractor: Saved portrait (${cropWidth}x$cropHeight) → $outputPath',
    );

    return outputPath;
  } on FileSystemException catch (e) {
    debugPrint('PassportPortraitExtractor: File I/O error: $e');
    return null;
  } on Exception catch (e) {
    debugPrint('PassportPortraitExtractor: Extraction error: $e');
    return null;
  }
}

// ── ML Kit face detection ─────────────────────────────────────────────────────

/// Detects the largest face in [imagePath] and returns a crop rectangle
/// with passport-photo-standard margins (35:45 aspect ratio, face ~75% tall).
///
/// Returns null when no face is detected or detection throws.
Future<Map<String, int>?> _detectFaceAndGetCropRect(
  String imagePath,
  int imageWidth,
  int imageHeight,
) async {
  try {
    final inputImage = InputImage.fromFilePath(imagePath);
    final faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks: false,
        enableContours: false,
        enableClassification: false,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );

    final faces = await faceDetector.processImage(inputImage);
    await faceDetector.close();

    if (faces.isEmpty) {
      debugPrint('PassportPortraitExtractor: No faces detected');
      return null;
    }

    // Pick the largest detected face (most likely the passport photo face).
    final face = faces.reduce(
      (a, b) =>
          a.boundingBox.width * a.boundingBox.height >=
              b.boundingBox.width * b.boundingBox.height
          ? a
          : b,
    );
    final box = face.boundingBox;

    // Passport photo standard: face occupies ~75% of photo height.
    // height = faceHeight / 0.75  →  face fits with 12.5% headroom top & bottom
    final photoHeight = (box.height / 0.75).round();
    // Width from 35:45 ratio
    final photoWidth = (photoHeight * (35.0 / 45.0)).round();

    // Centre horizontally on the face, add top headroom (~12%)
    final photoX = (box.center.dx - photoWidth / 2).round();
    final photoY = (box.top - photoHeight * 0.12).round();

    final x = photoX.clamp(0, imageWidth - 1);
    final y = photoY.clamp(0, imageHeight - 1);
    final w = photoWidth.clamp(1, imageWidth - x);
    final h = photoHeight.clamp(1, imageHeight - y);

    debugPrint(
      'PassportPortraitExtractor: Face at '
      '(${box.left.toInt()},${box.top.toInt()}) '
      '${box.width.toInt()}×${box.height.toInt()} → crop ${w}x$h',
    );

    return {'x': x, 'y': y, 'width': w, 'height': h};
  } catch (e) {
    debugPrint('PassportPortraitExtractor: ML Kit error: $e');
    return null;
  }
}

// ── Heuristic fallback ────────────────────────────────────────────────────────

/// ICAO 9303 region-based fallback when ML Kit cannot detect a face.
/// Photo area: left side of bio-data page, 35:45 aspect ratio.
Map<String, int> _getFallbackCropRect(int imageWidth, int imageHeight) {
  final width = (imageWidth * 0.25).round();
  final height = (width * (45.0 / 35.0)).round(); // exact 35:45 ratio
  final x = (imageWidth * 0.07).round();
  final y = (imageHeight * 0.32).round();

  final cx = x.clamp(0, imageWidth - 1);
  final cy = y.clamp(0, imageHeight - 1);
  return {
    'x': cx,
    'y': cy,
    'width': width.clamp(1, imageWidth - cx),
    'height': height.clamp(1, imageHeight - cy),
  };
}

/// Deletes any portrait extraction file at [profileImagePath].
///
/// Call this when starting a fresh scan so stale extractions from a previous
/// session are never shown on the form. Safe to call with null or an empty
/// string — it will do nothing.
Future<void> deletePortraitExtraction(String? profileImagePath) async {
  if (profileImagePath == null || profileImagePath.isEmpty) return;
  try {
    final file = File(profileImagePath);
    if (await file.exists()) {
      await file.delete();
      debugPrint(
        'PassportPortraitExtractor: Deleted extraction on session start: $profileImagePath',
      );
    }
  } catch (e) {
    debugPrint(
      'PassportPortraitExtractor: Failed to delete on session start: $e',
    );
  }
}

// ── PAN Card portrait extractor ───────────────────────────────────────────────

/// Automatically extracts the profile photo from a captured PAN card image.
///
/// Indian PAN cards have two common layouts:
/// - **New layout** (2017+): photo on the **left side**, roughly top-left
///   quadrant (x: 2–22%, y: 20–70% of card height).
/// - **Old layout** (pre-2017): photo on the **bottom-right** corner
///   (x: 72–92%, y: 50–95% of card height).
///
/// The function first tries ML Kit face detection (works for both layouts).
/// If no face is found, it tries the new-layout region first, then the
/// old-layout region as a second fallback.
///
/// Returns the file path to the cropped portrait, or null on failure.
Future<String?> extractPanCardPortrait(
  String panCardFrontImagePath, {
  String? previousProfilePath,
}) async {
  try {
    // ── Delete previous extraction ───────────────────────────────────────────
    if (previousProfilePath != null && previousProfilePath.isNotEmpty) {
      try {
        final prev = File(previousProfilePath);
        if (await prev.exists()) await prev.delete();
      } catch (_) {}
    }

    // ── Decode source image ──────────────────────────────────────────────────
    final bytes = await File(panCardFrontImagePath).readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) {
      debugPrint('PanPortraitExtractor: Failed to decode image');
      return null;
    }

    final imageWidth = image.width;
    final imageHeight = image.height;

    // ── Try ML Kit face detection first ─────────────────────────────────────
    Map<String, int>? cropRect = await _detectFaceAndGetCropRect(
      panCardFrontImagePath,
      imageWidth,
      imageHeight,
    );

    // ── Fallback: new PAN layout (photo top-left) ────────────────────────────
    cropRect ??= _getPanNewLayoutCropRect(imageWidth, imageHeight);

    final cropX = cropRect['x']!;
    final cropY = cropRect['y']!;
    final cropWidth = cropRect['width']!;
    final cropHeight = cropRect['height']!;

    if (cropWidth < 40 || cropHeight < 40) {
      debugPrint('PanPortraitExtractor: Crop too small');
      return null;
    }

    // ── Crop and save ────────────────────────────────────────────────────────
    final cropped = img.copyCrop(
      image,
      x: cropX,
      y: cropY,
      width: cropWidth,
      height: cropHeight,
    );

    final croppedBytes = img.encodeJpg(cropped, quality: 90);
    final dir = File(panCardFrontImagePath).parent;
    final outputPath =
        '${dir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(outputPath).writeAsBytes(croppedBytes);

    debugPrint(
      'PanPortraitExtractor: Saved portrait (${cropWidth}x$cropHeight) → $outputPath',
    );
    return outputPath;
  } on FileSystemException catch (e) {
    debugPrint('PanPortraitExtractor: File I/O error: $e');
    return null;
  } on Exception catch (e) {
    debugPrint('PanPortraitExtractor: Extraction error: $e');
    return null;
  }
}

/// New PAN card layout (2017+): photo is on the **left side**.
/// Approximate region: x 2–22%, y 20–70% of the card.
Map<String, int> _getPanNewLayoutCropRect(int imageWidth, int imageHeight) {
  final x = (imageWidth * 0.02).round();
  final y = (imageHeight * 0.20).round();
  final w = (imageWidth * 0.20).round();
  final h = (imageHeight * 0.50).round();
  return {
    'x': x.clamp(0, imageWidth - 1),
    'y': y.clamp(0, imageHeight - 1),
    'width': w.clamp(1, imageWidth - x),
    'height': h.clamp(1, imageHeight - y),
  };
}

// ── Driving Licence portrait extractor ───────────────────────────────────────

/// Automatically extracts the profile photo from a captured Driving Licence
/// front image.
///
/// Indian DL cards have two common layouts:
/// - **Modern chip-card layout** (majority — Maharashtra, Rajasthan, Delhi,
///   etc.): photo on the **top-right** corner (x: 65–90%, y: 5–50%).
/// - **Older/state layout** (Kerala, Arunachal, etc.): photo on the
///   **top-left** corner (x: 2–28%, y: 5–55%).
///
/// ML Kit face detection is tried first and works for both layouts.
/// If it finds no face the top-right heuristic region is used as fallback
/// (covers the majority of real-world DL cards).
///
/// Returns the file path to the cropped portrait, or null on failure.
Future<String?> extractDrivingLicencePortrait(
  String dlFrontImagePath, {
  String? previousProfilePath,
}) async {
  try {
    // ── Delete previous extraction ───────────────────────────────────────────
    if (previousProfilePath != null && previousProfilePath.isNotEmpty) {
      try {
        final prev = File(previousProfilePath);
        if (await prev.exists()) await prev.delete();
      } catch (_) {}
    }

    // ── Decode source image ──────────────────────────────────────────────────
    final bytes = await File(dlFrontImagePath).readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) {
      debugPrint('DLPortraitExtractor: Failed to decode image');
      return null;
    }

    final imageWidth = image.width;
    final imageHeight = image.height;

    // ── Try ML Kit face detection first ─────────────────────────────────────
    Map<String, int>? cropRect = await _detectFaceAndGetCropRect(
      dlFrontImagePath,
      imageWidth,
      imageHeight,
    );

    // ── Fallback: modern chip-card layout (photo top-right) ──────────────────
    cropRect ??= _getDLTopRightCropRect(imageWidth, imageHeight);

    final cropX = cropRect['x']!;
    final cropY = cropRect['y']!;
    final cropWidth = cropRect['width']!;
    final cropHeight = cropRect['height']!;

    if (cropWidth < 40 || cropHeight < 40) {
      debugPrint('DLPortraitExtractor: Crop too small');
      return null;
    }

    // ── Crop and save ────────────────────────────────────────────────────────
    final cropped = img.copyCrop(
      image,
      x: cropX,
      y: cropY,
      width: cropWidth,
      height: cropHeight,
    );

    final croppedBytes = img.encodeJpg(cropped, quality: 90);
    final dir = File(dlFrontImagePath).parent;
    final outputPath =
        '${dir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(outputPath).writeAsBytes(croppedBytes);

    debugPrint(
      'DLPortraitExtractor: Saved portrait (${cropWidth}x$cropHeight) → $outputPath',
    );
    return outputPath;
  } on FileSystemException catch (e) {
    debugPrint('DLPortraitExtractor: File I/O error: $e');
    return null;
  } on Exception catch (e) {
    debugPrint('DLPortraitExtractor: Extraction error: $e');
    return null;
  }
}

/// Modern DL chip-card layout: photo is in the **top-right** corner.
/// Covers Maharashtra, Rajasthan, Delhi, and most post-2010 state DLs.
/// Approximate region: x 65–90%, y 5–50%.
Map<String, int> _getDLTopRightCropRect(int imageWidth, int imageHeight) {
  final x = (imageWidth * 0.65).round();
  final y = (imageHeight * 0.05).round();
  final w = (imageWidth * 0.25).round();
  final h = (imageHeight * 0.45).round();
  return {
    'x': x.clamp(0, imageWidth - 1),
    'y': y.clamp(0, imageHeight - 1),
    'width': w.clamp(1, imageWidth - x),
    'height': h.clamp(1, imageHeight - y),
  };
}

// ── Aadhaar card portrait extractor ──────────────────────────────────────────

/// Automatically extracts the profile photo from a captured Aadhaar card
/// front image.
///
/// All physical Aadhaar cards (both old and new designs) place the photo on
/// the **left side** of the card (x: 2–28%, y: 15–75%).
///
/// ML Kit face detection is tried first. If it finds no face the left-side
/// heuristic region is used as fallback.
///
/// Returns the file path to the cropped portrait, or null on failure.
Future<String?> extractAadhaarPortrait(
  String aadhaarFrontImagePath, {
  String? previousProfilePath,
}) async {
  try {
    // ── Delete previous extraction ───────────────────────────────────────────
    if (previousProfilePath != null && previousProfilePath.isNotEmpty) {
      try {
        final prev = File(previousProfilePath);
        if (await prev.exists()) await prev.delete();
      } catch (_) {}
    }

    // ── Decode source image ──────────────────────────────────────────────────
    final bytes = await File(aadhaarFrontImagePath).readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) {
      debugPrint('AadhaarPortraitExtractor: Failed to decode image');
      return null;
    }

    final imageWidth = image.width;
    final imageHeight = image.height;

    // ── Try ML Kit face detection first ─────────────────────────────────────
    Map<String, int>? cropRect = await _detectFaceAndGetCropRect(
      aadhaarFrontImagePath,
      imageWidth,
      imageHeight,
    );

    // ── Fallback: left-side region (all physical Aadhaar card designs) ───────
    cropRect ??= _getAadhaarLeftSideCropRect(imageWidth, imageHeight);

    final cropX = cropRect['x']!;
    final cropY = cropRect['y']!;
    final cropWidth = cropRect['width']!;
    final cropHeight = cropRect['height']!;

    if (cropWidth < 40 || cropHeight < 40) {
      debugPrint('AadhaarPortraitExtractor: Crop too small');
      return null;
    }

    // ── Crop and save ────────────────────────────────────────────────────────
    final cropped = img.copyCrop(
      image,
      x: cropX,
      y: cropY,
      width: cropWidth,
      height: cropHeight,
    );

    final croppedBytes = img.encodeJpg(cropped, quality: 90);
    final dir = File(aadhaarFrontImagePath).parent;
    final outputPath =
        '${dir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(outputPath).writeAsBytes(croppedBytes);

    debugPrint(
      'AadhaarPortraitExtractor: Saved portrait (${cropWidth}x$cropHeight) → $outputPath',
    );
    return outputPath;
  } on FileSystemException catch (e) {
    debugPrint('AadhaarPortraitExtractor: File I/O error: $e');
    return null;
  } on Exception catch (e) {
    debugPrint('AadhaarPortraitExtractor: Extraction error: $e');
    return null;
  }
}

/// Left-side fallback for all physical Aadhaar card designs.
/// Approximate region: x 2–28%, y 15–75%.
Map<String, int> _getAadhaarLeftSideCropRect(int imageWidth, int imageHeight) {
  final x = (imageWidth * 0.02).round();
  final y = (imageHeight * 0.15).round();
  final w = (imageWidth * 0.26).round();
  final h = (imageHeight * 0.60).round();
  return {
    'x': x.clamp(0, imageWidth - 1),
    'y': y.clamp(0, imageHeight - 1),
    'width': w.clamp(1, imageWidth - x),
    'height': h.clamp(1, imageHeight - y),
  };
}
