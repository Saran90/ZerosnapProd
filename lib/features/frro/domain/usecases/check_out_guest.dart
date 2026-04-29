import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/guest_repository.dart';

class CheckOutGuestUseCase {
  final GuestRepository repository;
  CheckOutGuestUseCase(this.repository);

  Future<Either<Failure, bool>> call({
    required int guestdataId,
    required int branchId,
    int userId = 0,
  }) => repository.checkOut(
    guestdataId: guestdataId,
    branchId: branchId,
    userId: userId,
  );
}
