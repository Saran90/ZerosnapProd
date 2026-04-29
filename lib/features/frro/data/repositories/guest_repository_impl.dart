import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/guest.dart';
import '../../domain/repositories/guest_repository.dart';
import '../datasources/guest_remote_data_source.dart';

class GuestRepositoryImpl implements GuestRepository {
  final GuestRemoteDataSource remoteDataSource;

  GuestRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Guest>>> getGuestList({
    required int branchId,
    int userId = 0,
    int btnStatusOfCheckINOUT = 0,
  }) async {
    try {
      final guests = await remoteDataSource.getGuestList(
        branchId: branchId,
        userId: userId,
        btnStatusOfCheckINOUT: btnStatusOfCheckINOUT,
      );
      return Right(guests);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> checkIn({
    required int guestdataId,
    required int branchId,
    required String applicationId,
    int userId = 0,
  }) async {
    try {
      final success = await remoteDataSource.checkIn(
        guestdataId: guestdataId,
        branchId: branchId,
        applicationId: applicationId,
        userId: userId,
      );
      return Right(success);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> checkOut({
    required int guestdataId,
    required int branchId,
    int userId = 0,
  }) async {
    try {
      final success = await remoteDataSource.checkOut(
        guestdataId: guestdataId,
        branchId: branchId,
        userId: userId,
      );
      return Right(success);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }
}
