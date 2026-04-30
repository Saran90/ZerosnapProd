import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/guest_repository.dart';

class CheckInGuestUseCase {
  final GuestRepository repository;
  CheckInGuestUseCase(this.repository);

  Future<Either<Failure, bool>> call({
    required int guestdataId,
    required int branchId,
    required String applicationId,
    int userId = 0,
  }) => repository.checkIn(
    guestdataId: guestdataId,
    branchId: branchId,
    applicationId: applicationId,
    userId: userId,
  );
}
