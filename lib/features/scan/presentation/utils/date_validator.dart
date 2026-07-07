/// Utility class for validating dates in passport and card forms.
class DateValidator {
  /// Validates a passport issuing date.
  /// Returns error message if invalid, null if valid.
  static String? validateIssuingDate(String dateText) {
    if (dateText.isEmpty || dateText.toLowerCase() == 'unknown') {
      return null;
    }

    final date = _tryParseDate(dateText);
    if (date != null && date.isAfter(DateTime.now())) {
      return 'Enter a valid passport issuing date';
    }

    return null;
  }

  /// Validates a passport expiry date.
  /// Returns error message if invalid, null if valid.
  static String? validatePassportExpiryDate(String dateText) {
    if (dateText.isEmpty || dateText.toLowerCase() == 'unknown') {
      return null;
    }

    final date = _tryParseDate(dateText);
    if (date == null) return null;

    if (date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return 'Passport has expired';
    }

    if (date.isBefore(DateTime.now())) {
      return 'Passport expiry date must be in the future';
    }

    return null;
  }

  /// Validates a visa issuing date.
  /// Returns error message if invalid, null if valid.
  static String? validateVisaIssuingDate(String dateText) {
    if (dateText.isEmpty || dateText.toLowerCase() == 'unknown') {
      return null;
    }

    final date = _tryParseDate(dateText);
    if (date != null && date.isAfter(DateTime.now())) {
      return 'Enter a valid visa issuing date';
    }

    return null;
  }

  /// Validates a visa expiry date.
  /// Returns error message if invalid, null if valid.
  static String? validateVisaExpiryDate(String dateText) {
    if (dateText.isEmpty || dateText.toLowerCase() == 'unknown') {
      return null;
    }

    final date = _tryParseDate(dateText);
    if (date == null) return null;

    if (date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return 'Visa has expired';
    }

    if (date.isBefore(DateTime.now())) {
      return 'Visa expiry date must be in the future';
    }

    return null;
  }

  /// Validates a document expiry date (for domestic cards).
  /// Returns error message if invalid, null if valid.
  static String? validateDocumentExpiryDate(DateTime? expiryDate) {
    if (expiryDate == null) return null;

    if (expiryDate.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return 'Document expired! Please select a valid expiration date.';
    }

    return null;
  }

  /// Tries to parse a date string in DD-MM-YYYY format.
  /// Returns null if parsing fails.
  static DateTime? _tryParseDate(String text) {
    try {
      final parts = text.split('-');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (_) {}
    return null;
  }
}
