import 'package:equatable/equatable.dart';

class Guest extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String nationality;
  final String passportNumber;
  final String visaType;
  final DateTime checkIn;
  final DateTime? checkOut;
  final GuestStatus status;
  final bool frroSubmitted;
  final DateTime createdAt;

  const Guest({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.nationality,
    required this.passportNumber,
    required this.visaType,
    required this.checkIn,
    this.checkOut,
    required this.status,
    this.frroSubmitted = false,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    email,
    phone,
    nationality,
    passportNumber,
    visaType,
    checkIn,
    checkOut,
    status,
    frroSubmitted,
    createdAt,
  ];
}

enum GuestStatus { checkedIn, checkedOut, pending }
