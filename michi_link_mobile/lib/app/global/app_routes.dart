import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/collars/collars.dart';
import 'package:michi_link_mobile/history/history.dart';
import 'package:michi_link_mobile/home/home.dart';
import 'package:michi_link_mobile/notifications/notifications.dart';
import 'package:michi_link_mobile/settings/settings.dart';

class AppRoutes {
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    observers: [AppRouteObserver(analyticsService: getIt<AnalyticsService>())],
    initialLocation: AppRoute.home.path,
    debugLogDiagnostics: kDebugMode,
    routes: [
      GoRoute(
        name: AppRoute.home.name,
        path: AppRoute.home.path,
        builder: (_, _) => const HomePage(),
        routes: [
          GoRoute(
            name: AppRoute.settings.name,
            path: AppRoute.settings.path,
            builder: (_, _) => const SettingsPage(),
          ),
          GoRoute(
            name: AppRoute.collars.name,
            path: AppRoute.collars.path,
            builder: (_, _) => const CollarsPage(),
          ),
          GoRoute(
            name: AppRoute.notifications.name,
            path: AppRoute.notifications.path,
            builder: (_, state) => NotificationsPage(
              deviceId: state.pathParameters['deviceId'] ?? '',
            ),
          ),
          GoRoute(
            name: AppRoute.history.name,
            path: AppRoute.history.path,
            builder: (_, state) =>
                HistoryPage(deviceId: state.pathParameters['deviceId'] ?? ''),
          ),
        ],
      ),
    ],
  );

  static GoRouter getRouter() => router;
}

enum AppRoute {
  home('/'),
  settings('settings'),
  collars('collars'),
  notifications('notifications/:deviceId'),
  history('history/:deviceId');

  const AppRoute(this.path);
  final String path;
}
