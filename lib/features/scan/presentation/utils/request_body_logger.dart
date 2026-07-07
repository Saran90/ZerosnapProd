import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Utility class for logging API request bodies with clean formatting.
/// Base64 image data is replaced with length indicators to keep logs readable.
class RequestBodyLogger {
  /// Logs the SavePassportAndVisa request body to the debug console.
  ///
  /// Base64 image fields are replaced with placeholders showing their character count.
  static void logSavePassportBody(Map<String, dynamic> body) {
    debugPrint(
      '==================== SavePassportAndVisa Request Body ====================',
    );
    debugPrint('Total fields: ${body.length}');

    // Create a copy and replace base64 images with placeholders
    final bodyForPrint = _replaceBase64WithPlaceholders(body, [
      'passportFile',
      'passportBackFile',
      'profileImageFile',
      'User_Signature',
      'visaFile',
      'visaFile2',
      'visaFile3',
    ]);

    debugPrint(const JsonEncoder.withIndent('  ').convert(bodyForPrint));
    debugPrint(
      '=========================================================================',
    );
  }

  /// Logs the SaveIndianCard request body to the debug console.
  ///
  /// Base64 image fields are replaced with placeholders showing their character count.
  static void logSaveIndianCardBody(Map<String, dynamic> body) {
    debugPrint(
      '==================== SaveIndianCard Request Body ====================',
    );
    debugPrint('Total fields: ${body.length}');

    // Create a copy and replace base64 images with placeholders
    final bodyForPrint = _replaceBase64WithPlaceholders(body, [
      'IdFrontFile',
      'IdBackFile',
      'ProfileImageFile',
      'GuestSignatureFile',
    ]);

    debugPrint(const JsonEncoder.withIndent('  ').convert(bodyForPrint));
    debugPrint(
      '=====================================================================',
    );
  }

  /// Replaces base64 encoded fields with readable placeholders.
  static Map<String, dynamic> _replaceBase64WithPlaceholders(
    Map<String, dynamic> body,
    List<String> imageFields,
  ) {
    final bodyForPrint = Map<String, dynamic>.from(body);

    for (final field in imageFields) {
      if (bodyForPrint[field]?.toString().isNotEmpty == true) {
        final length = bodyForPrint[field].toString().length;
        bodyForPrint[field] = '<base64 image: $length chars>';
      }
    }

    return bodyForPrint;
  }
}
