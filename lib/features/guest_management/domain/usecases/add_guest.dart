import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/guest.dart';
import '../repositories/guest_repository.dart';

class AddGuest extends UseCase<Guest, Guest> {
  final GuestRepository repository;
  AddGuest(this.repository);

  @override
  Future<Either<Failure, Guest>> call(Guest params) =>
      repository.addGuest(params);
}
