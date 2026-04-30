import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/guest_repository.dart';

class UpdateFrroSubmissionStatusUseCase {
  final GuestRepository repository;
  UpdateFrroSubmissionStatusUseCase(this.repository);

  Future<Either<Failure, bool>> call({required int guestdataId}) =>
      repository.updateFrroSubmissionStatus(guestdataId: guestdataId);
}
