import 'package:equatable/equatable.dart';

abstract class GuestListEvent extends Equatable {
  const GuestListEvent();

  @override
  List<Object?> get props => [];
}

class LoadGuestList extends GuestListEvent {
  final int branchId;
  final int userId;
  final int btnStatusOfCheckINOUT;

  const LoadGuestList({
    required this.branchId,
    this.userId = 0,
    this.btnStatusOfCheckINOUT = 0,
  });

  @override
  List<Object?> get props => [branchId, userId, btnStatusOfCheckINOUT];
}

class RefreshGuestList extends GuestListEvent {
  final int branchId;
  final int userId;
  final int btnStatusOfCheckINOUT;

  const RefreshGuestList({
    required this.branchId,
    this.userId = 0,
    this.btnStatusOfCheckINOUT = 0,
  });

  @override
  List<Object?> get props => [branchId, userId, btnStatusOfCheckINOUT];
}

class CheckInGuest extends GuestListEvent {
  final int guestdataId;
  final int branchId;
  final String applicationId;
  final int userId;

  const CheckInGuest({
    required this.guestdataId,
    required this.branchId,
    required this.applicationId,
    this.userId = 0,
  });

  @override
  List<Object?> get props => [guestdataId, branchId, applicationId, userId];
}

class CheckOutGuest extends GuestListEvent {
  final int guestdataId;
  final int branchId;
  final int userId;

  const CheckOutGuest({
    required this.guestdataId,
    required this.branchId,
    this.userId = 0,
  });

  @override
  List<Object?> get props => [guestdataId, branchId, userId];
}

/// Fired when the FRRO WebView navigates to a submission confirmation URL.
/// Updates local state only — does NOT call any API.
class FrroSubmitted extends GuestListEvent {
  final int guestdataId;
  final String applicationId;

  const FrroSubmitted({required this.guestdataId, required this.applicationId});

  @override
  List<Object?> get props => [guestdataId, applicationId];
}
