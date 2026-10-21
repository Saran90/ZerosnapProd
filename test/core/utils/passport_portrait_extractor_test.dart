import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:app/core/utils/passport_portrait_extractor.dart';

void main() {
  group('extractPassportPortrait', () {
    late Directory tempDir;

    setUp(() async {
      // Create a temporary directory for test files
      tempDir = await Directory.systemTemp.createTemp('passport_test_');
    });

    tearDown(() async {
      // Clean up temporary directory after each test
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('successful extraction with valid passport image', () async {
      // Create a mock passport image (landscape, 3:2 ratio, 1200x800)
      final mockPassportImage = img.Image(width: 1200, height: 800);
      // Fill with white background
      img.fill(mockPassportImage, color: img.ColorRgb8(255, 255, 255));
      // Draw a mock portrait region (left side, matching ICAO position)
      // Portrait should be at x: 5-25% (60-300), y: 25-75% (200-600)
      for (var x = 60; x < 300; x++) {
        for (var y = 200; y < 600; y++) {
          mockPassportImage.setPixel(x, y, img.ColorRgb8(128, 128, 200));
        }
      }

      // Save mock image
      final inputPath = '${tempDir.path}/mock_passport.jpg';
      await File(inputPath).writeAsBytes(img.encodeJpg(mockPassportImage));

      // Run extraction
      final result = await extractPassportPortrait(inputPath);

      // Verify result
      expect(result, isNotNull);
      expect(result, contains('profile_latest.jpg'));
      expect(await File(result!).exists(), isTrue);

      // Verify cropped image has reasonable dimensions
      final croppedBytes = await File(result).readAsBytes();
      final croppedImage = img.decodeImage(croppedBytes);
      expect(croppedImage, isNotNull);
      expect(croppedImage!.width, greaterThan(0));
      expect(croppedImage.height, greaterThan(0));
      // Expected dimensions based on 25% width and 35:45 aspect ratio
      // 25% of 1200 = 300, height = 300 × 1.2857 ≈ 386
      expect(croppedImage.width, equals(300));
      expect(croppedImage.height, closeTo(386, 2));
    });

    test('null return on decode failure (invalid image data)', () async {
      // Create a file with invalid image data
      final invalidPath = '${tempDir.path}/invalid_image.jpg';
      await File(invalidPath).writeAsString('not an image');

      // Run extraction
      final result = await extractPassportPortrait(invalidPath);

      // Verify null return
      expect(result, isNull);
    });

    test('null return on I/O error (file not found)', () async {
      // Use a non-existent file path
      final nonExistentPath = '${tempDir.path}/does_not_exist.jpg';

      // Run extraction
      final result = await extractPassportPortrait(nonExistentPath);

      // Verify null return
      expect(result, isNull);
    });

    test('bounds clamping with small image', () async {
      // Create a small but not too small image (200x150) to test clamping logic
      // (Below 50x50 would be rejected as too small)
      final smallImage = img.Image(width: 200, height: 150);
      img.fill(smallImage, color: img.ColorRgb8(100, 100, 100));

      final inputPath = '${tempDir.path}/small_image.jpg';
      await File(inputPath).writeAsBytes(img.encodeJpg(smallImage));

      // Run extraction
      final result = await extractPassportPortrait(inputPath);

      // Should still succeed despite small size
      expect(result, isNotNull);
      expect(await File(result!).exists(), isTrue);

      // Verify cropped image dimensions are clamped correctly
      final croppedBytes = await File(result).readAsBytes();
      final croppedImage = img.decodeImage(croppedBytes);
      expect(croppedImage, isNotNull);
      expect(croppedImage!.width, lessThanOrEqualTo(200));
      expect(croppedImage.height, lessThanOrEqualTo(150));
      expect(croppedImage.width, greaterThanOrEqualTo(50));
      expect(croppedImage.height, greaterThanOrEqualTo(50));
    });

    test('output file creation with fixed filename', () async {
      // Create a mock passport image
      final mockImage = img.Image(width: 800, height: 600);
      img.fill(mockImage, color: img.ColorRgb8(200, 200, 200));

      final inputPath = '${tempDir.path}/passport_front.jpg';
      await File(inputPath).writeAsBytes(img.encodeJpg(mockImage));

      // First extraction
      final result1 = await extractPassportPortrait(inputPath);
      expect(result1, isNotNull);
      expect(result1, endsWith('profile_latest.jpg'));
      expect(await File(result1!).exists(), isTrue);

      // Second extraction (should overwrite)
      final result2 = await extractPassportPortrait(inputPath);
      expect(result2, isNotNull);
      expect(result2, equals(result1)); // Same filename
      expect(await File(result2!).exists(), isTrue);

      // Only one profile file should exist (proves overwriting works, not accumulation)
      final profileFiles = await tempDir
          .list()
          .where((entity) => entity.path.contains('profile_'))
          .toList();
      expect(profileFiles.length, equals(1));
    });

    test('handles edge case with too-small crop region gracefully', () async {
      // Create a 30x30 pixel image (will fail minimum dimension check)
      final tinyImage = img.Image(width: 30, height: 30);
      img.fill(tinyImage, color: img.ColorRgb8(128, 128, 128));

      final inputPath = '${tempDir.path}/tiny_image.jpg';
      await File(inputPath).writeAsBytes(img.encodeJpg(tinyImage));

      // Run extraction
      final result = await extractPassportPortrait(inputPath);

      // Should return null because crop dimensions would be < 50x50
      expect(result, isNull);
    });

    test('preserves JPEG quality in output', () async {
      // Create a mock passport image with distinct colors
      final mockImage = img.Image(width: 600, height: 400);
      img.fill(mockImage, color: img.ColorRgb8(255, 0, 0));
      // Add a pattern in the portrait region
      for (var x = 30; x < 150; x++) {
        for (var y = 100; y < 300; y++) {
          mockImage.setPixel(x, y, img.ColorRgb8(0, 255, 0));
        }
      }

      final inputPath = '${tempDir.path}/colorful_passport.jpg';
      await File(inputPath).writeAsBytes(img.encodeJpg(mockImage));

      // Run extraction
      final result = await extractPassportPortrait(inputPath);
      expect(result, isNotNull);

      // Verify output is valid JPEG
      final croppedBytes = await File(result!).readAsBytes();
      final croppedImage = img.decodeImage(croppedBytes);
      expect(croppedImage, isNotNull);

      // Check that the green pattern is preserved in the output
      // (quality 90 should preserve colors reasonably well)
      final centerPixel = croppedImage!.getPixel(
        croppedImage.width ~/ 2,
        croppedImage.height ~/ 2,
      );
      // Should be greenish (G channel > R and B channels)
      expect(centerPixel.g, greaterThan(centerPixel.r));
      expect(centerPixel.g, greaterThan(centerPixel.b));
    });
  });
}
