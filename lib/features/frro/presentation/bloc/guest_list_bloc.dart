import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/check_in_guest.dart';
import '../../domain/usecases/check_out_guest.dart';
import '../../domain/usecases/get_guest_list.dart';
import '../../domain/usecases/update_frro_submission_status.dart';
import 'guest_list_event.dart';
import 'guest_list_state.dart';

class GuestListBloc extends Bloc<GuestListEvent, GuestListState> {
  final GetGuestList getGuestList;
  final CheckInGuestUseCase checkInGuest;
  final CheckOutGuestUseCase checkOutGuest;
  final UpdateFrroSubmissionStatusUseCase updateFrroSubmissionStatus;

  GuestListBloc({
    required this.getGuestList,
    required this.checkInGuest,
    required this.checkOutGuest,
    required this.updateFrroSubmissionStatus,
  }) : super(GuestListInitial()) {
    on<LoadGuestList>(_onLoadGuestList);
    on<RefreshGuestList>(_onRefreshGuestList);
    on<CheckInGuest>(_onCheckInGuest);
    on<CheckOutGuest>(_onCheckOutGuest);
    on<FrroSubmitted>(_onFrroSubmitted);
  }

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

  /// Calls the UpdateFRROBeforeCheckInStatusMobile API when FRRO is submitted,
  /// then reloads the guest list so the updated status is reflected from the server.
  Future<void> _onFrroSubmitted(
    FrroSubmitted event,
    Emitter<GuestListState> emit,
  ) async {
    await updateFrroSubmissionStatus(guestdataId: event.guestdataId);

    // Reload the guest list so the server-side FRRO submission status is reflected
    final currentState = state;
    final branchId = currentState is GuestListLoaded
        ? 5 // use default branchId
        : 5;
    await _fetchGuests(branchId, 0, 1, emit);
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
        GuestListLoaded(guests, btnStatusOfCheckINOUT: btnStatusOfCheckINOUT),
      ),
    );
  }
}
