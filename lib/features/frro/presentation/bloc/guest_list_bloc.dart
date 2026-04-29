import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/check_in_guest.dart';
import '../../domain/usecases/check_out_guest.dart';
import '../../domain/usecases/get_guest_list.dart';
import 'guest_list_event.dart';
import 'guest_list_state.dart';

class GuestListBloc extends Bloc<GuestListEvent, GuestListState> {
  final GetGuestList getGuestList;
  final CheckInGuestUseCase checkInGuest;
  final CheckOutGuestUseCase checkOutGuest;

  GuestListBloc({
    required this.getGuestList,
    required this.checkInGuest,
    required this.checkOutGuest,
  }) : super(GuestListInitial()) {
    on<LoadGuestList>(_onLoadGuestList);
    on<RefreshGuestList>(_onRefreshGuestList);
    on<CheckInGuest>(_onCheckInGuest);
    on<CheckOutGuest>(_onCheckOutGuest);
    on<FrroSubmitted>(_onFrroSubmitted);
  }

  /// Returns the current set of locally-submitted FRRO guest IDs,
  /// preserved across list reloads so badges persist.
  Set<int> get _currentSubmittedIds => state is GuestListLoaded
      ? (state as GuestListLoaded).frroSubmittedIds
      : {};

  Future<void> _onLoadGuestList(
    LoadGuestList event,
    Emitter<GuestListState> emit,
  ) async {
    await _fetchGuests(
      event.branchId,
      event.userId,
      event.btnStatusOfCheckINOUT,
      emit,
    );
  }

  Future<void> _onRefreshGuestList(
    RefreshGuestList event,
    Emitter<GuestListState> emit,
  ) async {
    await _fetchGuests(
      event.branchId,
      event.userId,
      event.btnStatusOfCheckINOUT,
      emit,
    );
  }

  /// Handles local FRRO submission tracking — no API call, just updates
  /// the in-memory set of submitted guest IDs.
  void _onFrroSubmitted(FrroSubmitted event, Emitter<GuestListState> emit) {
    if (state is GuestListLoaded) {
      emit((state as GuestListLoaded).copyWithSubmitted(event.guestdataId));
    }
  }

  Future<void> _onCheckInGuest(
    CheckInGuest event,
    Emitter<GuestListState> emit,
  ) async {
    final currentState = state;
    emit(GuestCheckInProgress(event.guestdataId));

    final result = await checkInGuest(
      guestdataId: event.guestdataId,
      branchId: event.branchId,
      applicationId: event.applicationId,
      userId: event.userId,
    );

    result.fold(
      (failure) =>
          emit(GuestCheckInFailure(event.guestdataId, failure.message)),
      (success) {
        if (success) {
          emit(GuestCheckInSuccess(event.guestdataId));
        } else {
          emit(
            GuestCheckInFailure(
              event.guestdataId,
              'Check-in failed. Please try again.',
            ),
          );
        }
      },
    );

    // Restore previous list state so the UI doesn't go blank
    if (currentState is GuestListLoaded) {
      emit(currentState);
    }
  }

  Future<void> _onCheckOutGuest(
    CheckOutGuest event,
    Emitter<GuestListState> emit,
  ) async {
    final currentState = state;
    emit(GuestCheckOutProgress(event.guestdataId));

    final result = await checkOutGuest(
      guestdataId: event.guestdataId,
      branchId: event.branchId,
      userId: event.userId,
    );

    result.fold(
      (failure) =>
          emit(GuestCheckOutFailure(event.guestdataId, failure.message)),
      (success) {
        if (success) {
          emit(GuestCheckOutSuccess(event.guestdataId));
        } else {
          emit(
            GuestCheckOutFailure(
              event.guestdataId,
              'Check-out failed. Please try again.',
            ),
          );
        }
      },
    );

    // Restore previous list state so the UI doesn't go blank
    if (currentState is GuestListLoaded) {
      emit(currentState);
    }
  }

  Future<void> _fetchGuests(
    int branchId,
    int userId,
    int btnStatusOfCheckINOUT,
    Emitter<GuestListState> emit,
  ) async {
    // Preserve locally-submitted IDs across reloads
    final submittedIds = _currentSubmittedIds;
    emit(GuestListLoading(btnStatusOfCheckINOUT: btnStatusOfCheckINOUT));
    final result = await getGuestList(
      GetGuestListParams(
        branchId: branchId,
        userId: userId,
        btnStatusOfCheckINOUT: btnStatusOfCheckINOUT,
      ),
    );

    result.fold(
      (failure) => emit(
        GuestListError(
          failure.message,
          btnStatusOfCheckINOUT: btnStatusOfCheckINOUT,
        ),
      ),
      (guests) => emit(
        GuestListLoaded(
          guests,
          btnStatusOfCheckINOUT: btnStatusOfCheckINOUT,
          frroSubmittedIds: submittedIds,
        ),
      ),
    );
  }
}
