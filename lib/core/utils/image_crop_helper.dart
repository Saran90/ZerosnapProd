import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';

import '../theme/app_colors.dart';

/// Launches the image cropper for a given file path.
/// Returns the cropped file path, or null if the user cancelled.
Future<String?> cropImage(
  BuildContext context,
  String sourcePath, {
  CropAspectRatio? aspectRatio,
}) async {
  final cropped = await ImageCropper().cropImage(
    sourcePath: sourcePath,
    aspectRatio: aspectRatio,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Crop Image',
        toolbarColor: AppColors.primary,
        toolbarWidgetColor: Colors.white,
        activeControlsWidgetColor: AppColors.primary,
        backgroundColor: Colors.black,
        initAspectRatio: CropAspectRatioPreset.original,
        lockAspectRatio: false,
        hideBottomControls: false,
        showCropGrid: true,
      ),
      IOSUiSettings(
        title: 'Crop Image',
        cancelButtonTitle: 'Cancel',
        doneButtonTitle: 'Done',
      ),
    ],
  );
  return cropped?.path;
}

/// Compresses [sourcePath] to a JPEG below [maxBytes] (default 50 KB).
///
/// Strategy:
///   1. Decode the image.
///   2. If dimensions are very large, scale down first (max 800 px on longest side).
///   3. Iteratively reduce JPEG quality (85 → 75 → 60 → 45 → 30 → 15)
///      until the encoded size is under [maxBytes].
///   4. Write the result to the app's temp directory and return the path.
///
/// Returns the compressed file path, or [sourcePath] if compression fails.
Future<String> compressImageBelow50KB(
  String sourcePath, {
  int maxBytes = 50 * 1024, // 50 KB
}) async {
  try {
    final bytes = await File(sourcePath).readAsBytes();
    img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) return sourcePath;

    // Step 1 — scale down if the image is very large
    const maxDimension = 800;
    if (decoded.width > maxDimension || decoded.height > maxDimension) {
      decoded = img.copyResize(
        decoded,
        width: decoded.width > decoded.height ? maxDimension : -1,
        height: decoded.height >= decoded.width ? maxDimension : -1,
      );
    }

    // Step 2 — iteratively reduce quality until under maxBytes
    const qualities = [85, 75, 60, 45, 30, 15];
    Uint8List? result;
    for (final q in qualities) {
      final encoded = img.encodeJpg(decoded, quality: q);
      if (encoded.length <= maxBytes) {
        result = Uint8List.fromList(encoded);
        break;
      }
      result = Uint8List.fromList(encoded); // keep last attempt as fallback
    }

    if (result == null) return sourcePath;

    // Step 3 — write to temp file
    final outPath =
        '${Directory.systemTemp.path}/frro_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(outPath).writeAsBytes(result);
    return outPath;
  } catch (_) {
    return sourcePath; // fallback: return original if anything goes wrong
  }
}
