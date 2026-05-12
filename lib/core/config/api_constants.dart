class ApiConstants {
  ApiConstants._();

  // Auth
  static const String verify = '/api/UrlValid';
  static const String login = '/api/MRZauthenticate';
  static const String checkApiAccess = '/api/CheckApiIsAccessible';

  // Passport / Visa
  static const String savePassport = '/api/SavePassportAndVisa';
  static const String saveIndianPassport = '/api/SaveIndianPassport';
  static const String extractPassport = '/api/Zerosnap/GetGVPassportFront';

  // Domestic cards
  static const String saveIndianCard = '/api/SaveIndianCard';
  static const String saveAadhar = '/api/SaveIdCardImage';
  static const String saveOtherId = '/api/SaveIdCardsWithExtract';

  // OCR extract endpoints
  static const String extractDL = '/api/intellilabs/GetIndianDrivingLicenceOCR';
  static const String extractVoterId = '/api/intellilabs/GetVoterCardOCR';
  static const String extractAadhaar = '/api/intellilabs/GetAadharOCR';
  static const String extractPan = '/api/intellilabs/GetPanOCR';
  static const String extractVisa = '/api/Zerosnap/GetGVVisa';

  // Verify endpoints
  static const String verifyDL = '/api/intellilabs/GetDLBasicVerify';
  static const String verifyVoterId = '/api/intellilabs/GetVoterBasicVerify';
  static const String verifyAadhaar = '/api/intellilabs/GetAadhaarBasicVerify';
  static const String verifyPan = '/api/intellilabs/GetPanVerify';

  // Lookup lists
  static const String visaTypes = '/api/GetVisaTypeList';
  static const String visaSubTypes = '/api/GetVisaSubTypeList';
  static const String purposes = '/api/GetPurposeOfVisitList';
  static const String vehicleTypes = '/api/GetVehicleTypeList';
  static const String countries = '/api/GetNationalityList';
  static const String states = '/api/GetStatesList';
  static const String districts = '/api/GetDistrictList';

  // Check-in / Check-out
  static const String getGuestData = '/api/GetFrroGuestDataMobile';
  static const String updateFrroBeforeCheckInStatus =
      '/api/UpdateFRROBeforeCheckInStatusMobile';
  static const String updateCheckInStatus =
      '/api/UpdateFRROCheckInStatusMobile';
  static const String updateCheckOutStatus =
      '/api/UpdateFRROCheckOutStatusMobile';

  // Duplicate guest check
  static const String checkDuplicateGuest = '/api/CheckDupilcateGuest';
}
