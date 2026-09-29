import 'package:go_router/go_router.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/home/home.dart';

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
      ],
      debugLogDiagnostics: true,
    );
  }
}

enum AppRoute {
  home('/', 'home'),
  settings('/settings', 'settings'),
  registerCollar('/register-collar', 'register-collar'),
  collarDetail('collar-detail', 'collar-detail');

  const AppRoute(this.path, this.name);
  final String path;
  final String name;
}
