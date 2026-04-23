import 'package:equatable/equatable.dart';

class FrroRegistration extends Equatable {
  final String id;
  final String guestId;
  final String guestName;
  final String passportNumber;
  final String nationality;
  final String visaNumber;
  final String visaType;
  final DateTime visaIssueDate;
  final DateTime visaExpiryDate;
  final String placeOfIssue;
  final String purposeOfVisit;
  final DateTime arrivalDate;
  final String portOfArrival;
  final FrroStatus status;
  final DateTime? submittedAt;
  final DateTime createdAt;

  const FrroRegistration({
    required this.id,
    required this.guestId,
    required this.guestName,
    required this.passportNumber,
    required this.nationality,
    required this.visaNumber,
    required this.visaType,
    required this.visaIssueDate,
    required this.visaExpiryDate,
    required this.placeOfIssue,
    required this.purposeOfVisit,
    required this.arrivalDate,
    required this.portOfArrival,
    required this.status,
    this.submittedAt,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, guestId, passportNumber, status];
}

enum FrroStatus { draft, submitted, approved, rejected }
