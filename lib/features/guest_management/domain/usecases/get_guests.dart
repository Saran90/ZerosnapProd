import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/guest.dart';
import '../repositories/guest_repository.dart';

class GetGuests extends UseCaseNoParams<List<Guest>> {
  final GuestRepository repository;
  GetGuests(this.repository);

  @override
  Future<Either<Failure, List<Guest>>> call() => repository.getGuests();
}
