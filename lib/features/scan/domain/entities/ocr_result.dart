/// Mirrors the Android project's OcrResponse model.
/// The `data` map contains the extracted fields from the OCR API.
class OcrResult {
  final Map<String, dynamic>? data;
  final String message;
  final int code;

  const OcrResult({this.data, this.message = '', this.code = 0});

  factory OcrResult.fromJson(Map<String, dynamic> json) {
    return OcrResult(
      data: (json['Data'] ?? json['data']) as Map<String, dynamic>?,
      message: json['message'] as String? ?? '',
      code: json['code'] as int? ?? 0,
    );
  }

  bool get isSuccess => code == 200;
}
