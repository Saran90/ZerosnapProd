import 'package:equatable/equatable.dart';

/// Full MRZ/passport scan result — mirrors the Android project's Passport model.
/// Fields are populated from the mrzscanner_flutter JSON response.
class MrzResult extends Equatable {
  // Core identity
  final String? surname;
  final String? givenNames;
  final String? documentNumber;
  final String? nationality;
  final String? dateOfBirth;
  final String? sex;
  final String? expiryDate;
  final String? documentType;
  final String? issuingCountry;

  // Extended fields from JSON response
  final String? documentTypeReadable;
  final String? documentNumberWithCheckDigit;
  final String? documentNumberCheckDigit;
  final String? dobRaw;
  final String? dobWithCheckDigit;
  final String? dobCheckDigit;
  final String? estIssuingDateRaw;
  final String? estIssuingDateReadable;
  final String? expirationDateRaw;
  final String? expirationDateWithCheckDigit;
  final String? expirationDateCheckDigit;
  final String? masterCheckDigit;
  final String? optionals;
  final String? message;

  // Images (base64 encoded)
  final String? fullImage;
  final String? portrait;
  final String? signature;

  // Raw fallback
  final String? rawMrz;

  const MrzResult({
    this.surname,
    this.givenNames,
    this.documentNumber,
    this.nationality,
    this.dateOfBirth,
    this.sex,
    this.expiryDate,
    this.documentType,
    this.issuingCountry,
    this.documentTypeReadable,
    this.documentNumberWithCheckDigit,
    this.documentNumberCheckDigit,
    this.dobRaw,
    this.dobWithCheckDigit,
    this.dobCheckDigit,
    this.estIssuingDateRaw,
    this.estIssuingDateReadable,
    this.expirationDateRaw,
    this.expirationDateWithCheckDigit,
    this.expirationDateCheckDigit,
    this.masterCheckDigit,
    this.optionals,
    this.message,
    this.fullImage,
    this.portrait,
    this.signature,
    this.rawMrz,
  });

  String get fullName =>
      [givenNames, surname].where((e) => e != null && e.isNotEmpty).join(' ');

  bool get hasPortrait => portrait != null && portrait!.isNotEmpty;
  bool get hasFullImage => fullImage != null && fullImage!.isNotEmpty;

  /// Parse from the JSON map returned by mrzscanner_flutter (same keys as Android project).
  factory MrzResult.fromJson(Map<String, dynamic> json) {
    return MrzResult(
      message: json['message'] as String?,
      documentType: json['document_type_raw'] as String?,
      documentTypeReadable: json['document_type_readable'] as String?,
      issuingCountry: json['issuing_country'] as String?,
      surname: json['surname'] as String?,
      documentNumber: json['document_number'] as String?,
      documentNumberWithCheckDigit:
          json['document_number_with_check_digit'] as String?,
      documentNumberCheckDigit: json['document_number_check_digit'] as String?,
      nationality: json['nationality'] as String?,
      dobRaw: json['dob_raw'] as String?,
      dobWithCheckDigit: json['dob_with_check_digit'] as String?,
      dobCheckDigit: json['dob_check_digit'] as String?,
      dateOfBirth: json['dob_readable'] as String?,
      sex: json['sex'] as String?,
      estIssuingDateRaw: json['est_issuing_date_raw'] as String?,
      estIssuingDateReadable: json['est_issuing_date_readable'] as String?,
      expirationDateRaw: json['expiration_date_raw'] as String?,
      expirationDateWithCheckDigit:
          json['expiration_date_with_check_digit'] as String?,
      expirationDateCheckDigit: json['expiration_date_check_digit'] as String?,
      expiryDate: json['expiration_date_readable'] as String?,
      masterCheckDigit: json['master_check_digit'] as String?,
      givenNames: json['given_names_readable'] as String?,
      optionals: json['optionals'] as String?,
      fullImage: json['full_image'] as String?,
      portrait: json['portrait'] as String?,
      signature: json['signature'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'message': message,
    'document_type_raw': documentType,
    'document_type_readable': documentTypeReadable,
    'issuing_country': issuingCountry,
    'surname': surname,
    'document_number': documentNumber,
    'document_number_with_check_digit': documentNumberWithCheckDigit,
    'document_number_check_digit': documentNumberCheckDigit,
    'nationality': nationality,
    'dob_raw': dobRaw,
    'dob_with_check_digit': dobWithCheckDigit,
    'dob_check_digit': dobCheckDigit,
    'dob_readable': dateOfBirth,
    'sex': sex,
    'est_issuing_date_raw': estIssuingDateRaw,
    'est_issuing_date_readable': estIssuingDateReadable,
    'expiration_date_raw': expirationDateRaw,
    'expiration_date_with_check_digit': expirationDateWithCheckDigit,
    'expiration_date_check_digit': expirationDateCheckDigit,
    'expiration_date_readable': expiryDate,
    'master_check_digit': masterCheckDigit,
    'given_names_readable': givenNames,
    'optionals': optionals,
    'full_image': fullImage,
    'portrait': portrait,
    'signature': signature,
  };

  @override
  List<Object?> get props => [
    surname,
    givenNames,
    documentNumber,
    nationality,
    dateOfBirth,
    sex,
    expiryDate,
    documentType,
    issuingCountry,
    fullImage,
    portrait,
  ];
}
