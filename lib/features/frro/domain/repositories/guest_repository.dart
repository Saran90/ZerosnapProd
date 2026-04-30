import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/guest.dart';

abstract class GuestRepository {
  Future<Either<Failure, List<Guest>>> getGuestList({
    required int branchId,
    int userId = 0,
    int btnStatusOfCheckINOUT = 0,
  });

  Future<Either<Failure, bool>> checkIn({
    required int guestdataId,
    required int branchId,
    required String applicationId,
    int userId = 0,
  });

  Future<Either<Failure, bool>> checkOut({
    required int guestdataId,
    required int branchId,
    int userId = 0,
  });

  Future<Either<Failure, bool>> updateFrroSubmissionStatus({
    required int guestdataId,
  });
}
