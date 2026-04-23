import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/cubit/theme_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // External
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  // Core
  sl.registerLazySingleton<ThemeCubit>(() => ThemeCubit(sl()));

  // Features — register here as you build them
  // _initAuth();
  // _initGuestManagement();
  // _initFrro();
}
