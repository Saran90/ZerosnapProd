import 'dart:io';

import 'package:image/image.dart' as img;

/// Automatically extracts the passport portrait photo from a captured passport
/// front page image.
///
/// This function uses a region-based heuristic based on the ICAO 9303 standard
/// passport layout where the portrait photo is located on the left side of the
/// bio-data page:
///   - Horizontal position: approximately 5-25% from left edge
///   - Vertical position: approximately 25-75% from top
///
/// Returns the file path to the cropped portrait image, or null if extraction
/// fails for any reason (file I/O error, decode failure, etc.).
///
/// The extracted portrait is saved in the same directory as the source image
/// with a timestamp-based filename pattern: `profile_<timestamp>.jpg`
Future<String?> extractPassportPortrait(String passportFrontImagePath) async {
  try {
    // Read and decode the passport front image
    final bytes = await File(passportFrontImagePath).readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return null;

    final imageWidth = image.width;
    final imageHeight = image.height;

    // Calculate crop region based on ICAO 9303 standard passport layout
    // Photo is on the left side of the bio-data page
    final x = (imageWidth * 0.05).round(); // 5% from left
    final y = (imageHeight * 0.25).round(); // 25% from top
    final width = (imageWidth * 0.20).round(); // 20% of image width (5-25%)
    final height = (imageHeight * 0.50).round(); // 50% of image height (25-75%)

    // Clamp values to ensure they stay within image bounds
    final cropX = x.clamp(0, imageWidth - 1);
    final cropY = y.clamp(0, imageHeight - 1);
    final cropWidth = width.clamp(1, imageWidth - cropX);
    final cropHeight = height.clamp(1, imageHeight - cropY);

    // Extract the portrait region
    final croppedImage = img.copyCrop(
      image,
      x: cropX,
      y: cropY,
      width: cropWidth,
      height: cropHeight,
    );

    // Encode to JPEG with quality 90
    final croppedBytes = img.encodeJpg(croppedImage, quality: 90);

    // Save to same directory as source with timestamp-based filename
    final sourceFile = File(passportFrontImagePath);
    final directory = sourceFile.parent;
    final outputPath =
        '${directory.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(outputPath).writeAsBytes(croppedBytes);

    return outputPath;
  } catch (_) {
    // Any error (file read, decode, crop, encode, write) returns null
    // This allows graceful fallback to manual flow
    return null;
  }
}
