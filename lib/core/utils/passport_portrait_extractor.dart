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
