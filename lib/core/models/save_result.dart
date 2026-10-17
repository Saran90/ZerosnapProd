/// Represents the standardised response from any card/passport save API.
///
/// The backend always returns:
///   { "Status": 1, "StatusMessage": "Saved successfully" }   → success
///   { "Status": 0, "StatusMessage": "<validation message>" } → validation error
///   { "Status": 2, "StatusMessage": "Time Out! ..." }        → session expired
class SaveResult {
  final int status;
  final String message;

  const SaveResult({required this.status, required this.message});

  bool get isSuccess => status == 1;
  bool get isValidationError => status == 0;
  bool get isSessionExpired => status == 2;

  factory SaveResult.fromJson(Map<String, dynamic> json) {
    final status =
        json['Status'] as int? ?? json['status'] as int? ?? 0;
    final message =
        json['StatusMessage'] as String? ??
        json['statusMessage'] as String? ??
        (status == 1 ? 'Saved successfully' : 'Submission failed');
    return SaveResult(status: status, message: message);
  }
}
