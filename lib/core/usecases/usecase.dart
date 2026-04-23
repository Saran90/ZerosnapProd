import 'package:dartz/dartz.dart';
import '../errors/failures.dart';

/// Base use case with params
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Base use case with no params
abstract class UseCaseNoParams<Type> {
  Future<Either<Failure, Type>> call();
}

/// Marker class for use cases that take no parameters
class NoParams {}
