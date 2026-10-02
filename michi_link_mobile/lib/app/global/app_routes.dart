import 'package:go_router/go_router.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/home/home.dart';
import 'package:michi_link_mobile/settings/settings.dart';

class AppRoutes {
  static GoRouter getRouter() {
    return GoRouter(
      observers: [
        AppRouteObserver(analyticsService: getIt<AnalyticsService>()),
      ],
      initialLocation: AppRoute.home.path,
      routes: [
        GoRoute(
          name: AppRoute.home.name,
          path: AppRoute.home.path,
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          name: AppRoute.settings.name,
          path: AppRoute.settings.path,
          builder: (context, state) => const SettingsPage(),
        ),
      ],
      debugLogDiagnostics: true,
    );
  }
}

enum AppRoute {
  home('/', 'home'),
  settings('/settings', 'settings'),
  collars('/collars', 'collars'),
  collarModify('collar-modify', 'collar-modify'),
  collarSettings('collar-settings', 'collar-settings'),
  collarHistory('collar-history/:collarId', 'collar-history'),
  collarNotifications('collar-notifications/:collarId', 'collar-notifications');

  const AppRoute(this.path, this.name);
  final String path;
  final String name;
}
