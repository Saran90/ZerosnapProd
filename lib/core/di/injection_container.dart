import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/frro/data/datasources/guest_remote_data_source.dart';
import '../../features/frro/data/repositories/guest_repository_impl.dart';
import '../../features/frro/domain/repositories/guest_repository.dart';
import '../../features/frro/domain/usecases/check_in_guest.dart';
import '../../features/frro/domain/usecases/check_out_guest.dart';
import '../../features/frro/domain/usecases/get_guest_list.dart';
import '../../features/frro/domain/usecases/update_frro_submission_status.dart';
import '../../features/frro/presentation/bloc/guest_list_bloc.dart';
import '../network/api_base_helper.dart';
import '../network/shared_preferences_provider.dart';
import '../theme/cubit/theme_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // External
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  // Core
  sl.registerLazySingleton<ThemeCubit>(() => ThemeCubit(sl()));
  sl.registerLazySingleton<ApiBaseHelper>(() => ApiBaseHelper());

  // FRRO Feature
  _initFrroFeature();
}

void _initFrroFeature() {
  // Data sources
  sl.registerLazySingleton<GuestRemoteDataSource>(
    () => GuestRemoteDataSourceImpl(
      apiHelper: sl(),
      prefs: SharedPreferencesProvider(),
    ),
  );

  // Repositories
  sl.registerLazySingleton<GuestRepository>(
    () => GuestRepositoryImpl(remoteDataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetGuestList(sl()));
  sl.registerLazySingleton(() => CheckInGuestUseCase(sl()));
  sl.registerLazySingleton(() => CheckOutGuestUseCase(sl()));
  sl.registerLazySingleton(() => UpdateFrroSubmissionStatusUseCase(sl()));

  // BLoC
  sl.registerFactory(
    () => GuestListBloc(
      getGuestList: sl(),
      checkInGuest: sl<CheckInGuestUseCase>(),
      checkOutGuest: sl<CheckOutGuestUseCase>(),
      updateFrroSubmissionStatus: sl<UpdateFrroSubmissionStatusUseCase>(),
    ),
  );
}
