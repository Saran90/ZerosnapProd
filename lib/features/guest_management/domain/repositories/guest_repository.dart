import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/guest.dart';

abstract class GuestRepository {
  Future<Either<Failure, List<Guest>>> getGuests();
  Future<Either<Failure, Guest>> getGuestById(String id);
  Future<Either<Failure, Guest>> addGuest(Guest guest);
  Future<Either<Failure, Guest>> updateGuest(Guest guest);
  Future<Either<Failure, void>> deleteGuest(String id);
  Future<Either<Failure, List<Guest>>> searchGuests(String query);
}
