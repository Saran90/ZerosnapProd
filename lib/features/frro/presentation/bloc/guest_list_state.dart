import 'package:equatable/equatable.dart';

import '../../domain/entities/guest.dart';

abstract class GuestListState extends Equatable {
  const GuestListState();

  @override
  List<Object?> get props => [];
}

class GuestListInitial extends GuestListState {}

class GuestListLoading extends GuestListState {
  final int btnStatusOfCheckINOUT;
  const GuestListLoading({this.btnStatusOfCheckINOUT = 0});

  @override
  List<Object?> get props => [btnStatusOfCheckINOUT];
}

class GuestListLoaded extends GuestListState {
  final List<Guest> guests;
  final int btnStatusOfCheckINOUT;

  const GuestListLoaded(this.guests, {this.btnStatusOfCheckINOUT = 0});

  @override
  List<Object?> get props => [guests, btnStatusOfCheckINOUT];
}

class GuestListError extends GuestListState {
  final String message;
  final int btnStatusOfCheckINOUT;

  const GuestListError(this.message, {this.btnStatusOfCheckINOUT = 0});

  @override
  List<Object?> get props => [message, btnStatusOfCheckINOUT];
}

class GuestCheckInProgress extends GuestListState {
  final int guestdataId;
  const GuestCheckInProgress(this.guestdataId);

  @override
  List<Object?> get props => [guestdataId];
}

class GuestCheckInSuccess extends GuestListState {
  final int guestdataId;
  const GuestCheckInSuccess(this.guestdataId);

  @override
  List<Object?> get props => [guestdataId];
}

class GuestCheckInFailure extends GuestListState {
  final int guestdataId;
  final String message;
  const GuestCheckInFailure(this.guestdataId, this.message);

  @override
  List<Object?> get props => [guestdataId, message];
}

class GuestCheckOutProgress extends GuestListState {
  final int guestdataId;
  const GuestCheckOutProgress(this.guestdataId);

  @override
  List<Object?> get props => [guestdataId];
}

class GuestCheckOutSuccess extends GuestListState {
  final int guestdataId;
  const GuestCheckOutSuccess(this.guestdataId);

  @override
  List<Object?> get props => [guestdataId];
}

class GuestCheckOutFailure extends GuestListState {
  final int guestdataId;
  final String message;
  const GuestCheckOutFailure(this.guestdataId, this.message);

  @override
  List<Object?> get props => [guestdataId, message];
}
