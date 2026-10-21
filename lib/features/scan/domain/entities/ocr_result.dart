import '../../../../core/services/firebase_logger.dart';

/// Mirrors the Android project's OcrResponse model.
/// The `data` map contains the extracted fields from the OCR API.
class OcrResult {
  final Map<String, dynamic>? data;
  final String message;
  final int code;

  const OcrResult({this.data, this.message = '', this.code = 0});

  factory OcrResult.fromJson(Map<String, dynamic> json) {
    final code = json['code'] as int? ?? 0;
    final message = json['message'] as String? ?? '';

    if (code != 200) {
      FirebaseLogger.instance.logError(
        Exception('OCR failed (code=$code): $message'),
        null,
        hint: 'ocr_failure | code=$code | $message',
      );
    }

    return OcrResult(
      data: (json['Data'] ?? json['data']) as Map<String, dynamic>?,
      message: message,
      code: code,
    );
  }

  bool get isSuccess => code == 200;
}
