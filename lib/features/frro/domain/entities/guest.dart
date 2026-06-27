import 'package:equatable/equatable.dart';

import 'branch.dart';

/// Guest_PassToFRRO values:
///   0 = New guest
///   1 = Submitted to FRRO
///   2 = Check-in completed
///   3 = Checkout completed
enum FrroStatus {
  newGuest,
  submittedToFrro,
  checkInCompleted,
  checkoutCompleted,
}

/// Guest entity representing a hotel guest with their details
class Guest extends Equatable {
  final int guestdataId;
  final String guestCode;
  final String firstName;
  final String lastName;
  final String phoneNo;
  final String email;
  final String gender;
  final String nationality;
  final String nationalityText;
  final String dateOfBirth;
  final String address;
  final String country;
  final String countryText;
  final String city;
  final String purposeOfVisit;
  final String documentNo;
  final String countryOfIssue;
  final String countryOfIssueText;
  final String dateOfIssue;
  final String expiryDate;
  final String visaNo;
  final String visaPOICity;
  final String visaPOICountry;
  final String visaDateOfIssue;
  final String visaValidTill;
  final String visaType;
  final String arrivalDate;
  final String arrivalTime;
  final String checkOutDate;
  final String checkOutTime;
  final String profilePic;
  final int passToFRRO; // 0=New, 1=Submitted, 2=CheckIn, 3=Checkout
  final int isCheckOut;
  final String dateOfArrivalInIndia;
  final String arrivedFromCountry;
  final String arrivedFromCity;
  final String arrivedFromPlace;
  final String nextDestination;
  final String nextDestinationInState;
  final String nextDestinationInDistrict;
  final String nextDestinationInPlace;
  final String nextDestinationOutCountry;
  final String nextDestinationOutCity;
  final String nextDestinationOutPlace;
  final String specialCategory;
  final String visaSubTypeId;
  final String visaSubTypeName;
  final Branch branch;

  const Guest({
    required this.guestdataId,
    required this.guestCode,
    required this.firstName,
    required this.lastName,
    required this.phoneNo,
    required this.email,
    required this.gender,
    required this.nationality,
    required this.nationalityText,
    required this.dateOfBirth,
    required this.address,
    required this.country,
    required this.countryText,
    required this.city,
    required this.purposeOfVisit,
    required this.documentNo,
    required this.countryOfIssue,
    required this.countryOfIssueText,
    required this.dateOfIssue,
    required this.expiryDate,
    required this.visaNo,
    required this.visaPOICity,
    required this.visaPOICountry,
    required this.visaDateOfIssue,
    required this.visaValidTill,
    required this.visaType,
    required this.arrivalDate,
    required this.arrivalTime,
    required this.checkOutDate,
    required this.checkOutTime,
    required this.profilePic,
    required this.passToFRRO,
    required this.isCheckOut,
    required this.dateOfArrivalInIndia,
    required this.arrivedFromCountry,
    required this.arrivedFromCity,
    required this.arrivedFromPlace,
    required this.nextDestination,
    required this.nextDestinationInState,
    required this.nextDestinationInDistrict,
    required this.nextDestinationInPlace,
    required this.nextDestinationOutCountry,
    required this.nextDestinationOutCity,
    required this.nextDestinationOutPlace,
    required this.specialCategory,
    required this.visaSubTypeId,
    required this.visaSubTypeName,
    this.branch = Branch.empty,
  });

  String get fullName => '$firstName $lastName'.trim();

  String get formattedArrival => '$arrivalDate $arrivalTime';

  String get formattedCheckOut => '$checkOutDate $checkOutTime';

  /// Derived status from Guest_PassToFRRO
  FrroStatus get frroStatus {
    switch (passToFRRO) {
      case 1:
        return FrroStatus.submittedToFrro;
      case 2:
        return FrroStatus.checkInCompleted;
      case 3:
        return FrroStatus.checkoutCompleted;
      default:
        return FrroStatus.newGuest;
    }
  }

  bool get isNewGuest => passToFRRO == 0;
  bool get isFRROSubmitted => passToFRRO == 1;
  bool get isCheckInCompleted => passToFRRO == 2;
  bool get isCheckoutCompleted => passToFRRO == 3;

  /// Legacy helpers kept for compatibility
  bool get isSyncedToFRRO => passToFRRO >= 1;
  bool get isCheckedOut => passToFRRO == 3;

  @override
  List<Object?> get props => [
    guestdataId,
    guestCode,
    firstName,
    lastName,
    phoneNo,
    email,
    gender,
    nationality,
    nationalityText,
    dateOfBirth,
    address,
    country,
    countryText,
    city,
    purposeOfVisit,
    documentNo,
    countryOfIssue,
    countryOfIssueText,
    dateOfIssue,
    expiryDate,
    visaNo,
    visaPOICity,
    visaPOICountry,
    visaDateOfIssue,
    visaValidTill,
    visaType,
    arrivalDate,
    arrivalTime,
    checkOutDate,
    checkOutTime,
    profilePic,
    passToFRRO,
    isCheckOut,
    dateOfArrivalInIndia,
    arrivedFromCountry,
    arrivedFromCity,
    arrivedFromPlace,
    nextDestination,
    nextDestinationInState,
    nextDestinationInDistrict,
    nextDestinationInPlace,
    nextDestinationOutCountry,
    nextDestinationOutCity,
    nextDestinationOutPlace,
    specialCategory,
    visaSubTypeId,
    visaSubTypeName,
    branch,
  ];
}
