import 'package:go_router/go_router.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/collars/collars.dart';
import 'package:michi_link_mobile/history/history.dart';
import 'package:michi_link_mobile/home/home.dart';
import 'package:michi_link_mobile/notifications/notifications.dart';
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
          routes: [
            GoRoute(
              name: AppRoute.settings.name,
              path: AppRoute.settings.path,
              builder: (context, state) => const SettingsPage(),
            ),
            GoRoute(
              name: AppRoute.collars.name,
              path: AppRoute.collars.path,
              builder: (context, state) => const CollarsPage(),
            ),
            GoRoute(
              name: AppRoute.notifications.name,
              path: AppRoute.notifications.path,
              builder: (context, state) {
                final collarId = state.pathParameters['collarId']!;
                return NotificationsPage(collarId: collarId);
              },
            ),
            GoRoute(
              name: AppRoute.history.name,
              path: AppRoute.history.path,
              builder: (context, state) {
                final collarId = state.pathParameters['collarId']!;
                return HistoryPage(collarId: collarId);
              },
            ),
          ],
        ),
      ],
      debugLogDiagnostics: true,
    );
  }
}

enum AppRoute {
  home('/', 'home'),
  settings('settings', 'settings'),
  collars('collars', 'collars'),
  notifications('notifications/:collarId', 'notifications'),
  history('history/:collarId', 'history');

  const AppRoute(this.path, this.name);
  final String path;
  final String name;
}
