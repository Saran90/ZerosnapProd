import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/guest.dart';
import '../repositories/guest_repository.dart';

class GetGuestList implements UseCase<List<Guest>, GetGuestListParams> {
  final GuestRepository repository;

  GetGuestList(this.repository);

  @override
  Future<Either<Failure, List<Guest>>> call(GetGuestListParams params) async {
    return await repository.getGuestList(
      branchId: params.branchId,
      userId: params.userId,
      btnStatusOfCheckINOUT: params.btnStatusOfCheckINOUT,
    );
  }
}

class GetGuestListParams {
  final int branchId;
  final int userId;
  final int btnStatusOfCheckINOUT;

  const GetGuestListParams({
    required this.branchId,
    this.userId = 0,
    this.btnStatusOfCheckINOUT = 0,
  });
}
