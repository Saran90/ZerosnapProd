import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mrzscanner_flutter/mrzscanner_flutter.dart';
import 'core/di/injection_container.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/cubit/theme_cubit.dart';
import 'core/utils/app_version.dart';
import 'features/frro/presentation/bloc/guest_list_bloc.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Pass all Flutter framework errors to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  // Pass async/platform errors to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Initialize app version info
  await AppVersion.initialize();

  Mrzflutterplugin.registerWithLicenceKey(
    '328833D4810B7B5E68109F90F66321CF4E7D4AB588DB3E3331CAE99326E0852B013A7A2E837A9B494D4295783E1804B3',
  );
  await initDependencies();
  runApp(const ZerosnapApp());
}

class ZerosnapApp extends StatelessWidget {
  const ZerosnapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => sl<ThemeCubit>()),
        BlocProvider<GuestListBloc>(create: (_) => sl<GuestListBloc>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: 'Zerosnap',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            routerConfig: appRouter,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.noScaling),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
