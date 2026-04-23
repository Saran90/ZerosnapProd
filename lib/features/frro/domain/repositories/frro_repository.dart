import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/frro_registration.dart';

abstract class FrroRepository {
  Future<Either<Failure, List<FrroRegistration>>> getFrroRegistrations();
  Future<Either<Failure, FrroRegistration>> getFrroById(String id);
  Future<Either<Failure, FrroRegistration>> createFrro(FrroRegistration frro);
  Future<Either<Failure, FrroRegistration>> updateFrro(FrroRegistration frro);
  Future<Either<Failure, void>> submitFrro(String id);
}
