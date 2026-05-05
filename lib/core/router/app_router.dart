import 'package:go_router/go_router.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/guest_management/presentation/pages/guest_list_page.dart';
import '../../features/guest_management/presentation/pages/guest_detail_page.dart';
import '../../features/guest_management/presentation/pages/add_guest_page.dart';
import '../../features/frro/presentation/pages/frro_list_page.dart';
import '../../features/frro/presentation/pages/frro_form_page.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String guestList = '/guests';
  static const String addGuest = '/guests/add';
  static const String guestDetail = '/guests/:id';
  static const String frroList = '/frro';
  static const String frroForm = '/frro/form';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: AppRoutes.dashboard,
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: AppRoutes.guestList,
      builder: (context, state) => const GuestListPage(),
      routes: [
        GoRoute(path: 'add', builder: (context, state) => const AddGuestPage()),
        GoRoute(
          path: ':id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return GuestDetailPage(guestId: id);
          },
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.frroList,
      builder: (context, state) => const FrroListPage(),
      routes: [
        GoRoute(
          path: 'form',
          builder: (context, state) => const FrroFormPage(),
        ),
      ],
    ),
  ],
);
