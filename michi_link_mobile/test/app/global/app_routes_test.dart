import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/collars/collars.dart';
import 'package:michi_link_mobile/history/history.dart';
import 'package:michi_link_mobile/home/home.dart';
import 'package:michi_link_mobile/notifications/notifications.dart';
import 'package:michi_link_mobile/settings/settings.dart';
import 'package:mocktail/mocktail.dart';

class MockGoRouterState extends Mock implements GoRouterState {}

void main() {
  group('AppRoute', () {
    test('values have correct path and name', () {
      expect(AppRoute.home.path, '/');
      expect(AppRoute.home.name, 'home');
      expect(AppRoute.settings.path, 'settings');
      expect(AppRoute.settings.name, 'settings');
      expect(AppRoute.collars.path, 'collars');
      expect(AppRoute.collars.name, 'collars');
      expect(AppRoute.notifications.path, 'notifications/:collarId');
      expect(AppRoute.notifications.name, 'notifications');
      expect(AppRoute.history.path, 'history/:collarId');
      expect(AppRoute.history.name, 'history');
    });

    test('AppRoutes.getRouter creates a configured GoRouter', () {
      if (!getIt.isRegistered<AnalyticsService>()) {
        setupServiceLocator(Environment.mock);
      }
      final router = AppRoutes.getRouter();
      expect(router, isNotNull);
      expect(router.configuration.routes, isNotEmpty);
    });

    testWidgets('route builders return expected widgets', (tester) async {
      if (!getIt.isRegistered<AnalyticsService>()) {
        setupServiceLocator(Environment.mock);
      }
      final router = AppRoutes.getRouter();
      final homeRoute = router.configuration.routes.first as GoRoute;
      final state = MockGoRouterState();
      when(() => state.pathParameters).thenReturn({'collarId': 'COLLAR_1'});

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(homeRoute.builder!(context, state), isA<HomePage>());

              final settingsRoute = homeRoute.routes[0] as GoRoute;
              expect(
                settingsRoute.builder!(context, state),
                isA<SettingsPage>(),
              );

              final collarsRoute = homeRoute.routes[1] as GoRoute;
              expect(collarsRoute.builder!(context, state), isA<CollarsPage>());

              final notificationsRoute = homeRoute.routes[2] as GoRoute;
              expect(
                notificationsRoute.builder!(context, state),
                isA<NotificationsPage>(),
              );

              final historyRoute = homeRoute.routes[3] as GoRoute;
              expect(historyRoute.builder!(context, state), isA<HistoryPage>());

              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}
