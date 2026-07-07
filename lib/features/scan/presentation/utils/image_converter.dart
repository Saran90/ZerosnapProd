import 'dart:convert';
import 'dart:io';

/// Utility class for converting image files to base64 strings.
class ImageConverter {
  /// Converts an image file at [path] to a base64 encoded string.
  /// Returns null if path is null, empty, or if conversion fails.
  static String? toBase64FromPath(String? path) {
    if (path == null || path.isEmpty) return null;

    try {
      return base64Encode(File(path).readAsBytesSync());
    } catch (_) {
      return null;
    }
  }

  /// Converts an image file to a base64 encoded string asynchronously.
  /// Returns null if path is null, empty, or if conversion fails.
  static Future<String?> toBase64FromPathAsync(String? path) async {
    if (path == null || path.isEmpty) return null;

    try {
      final bytes = await File(path).readAsBytes();
      return base64Encode(bytes);
    } catch (_) {
      return null;
    }
  }
}
