import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:mocktail/mocktail.dart';

class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  group('AppRouteObserver', () {
    late MockAnalyticsService analyticsService;
    late AppRouteObserver observer;

    setUp(() {
      analyticsService = MockAnalyticsService();
      observer = AppRouteObserver(analyticsService: analyticsService);
    });

    test('didPush sends screen view when route is PageRoute with name', () {
      final route = MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'home'),
        builder: (_) => const SizedBox(),
      );

      observer.didPush(route, null);

      verify(
        () => analyticsService.setCurrentScreen(screenName: 'home'),
      ).called(1);
    });

    test(
      'didPop sends screen view for previousRoute when both are PageRoute',
      () {
        final currentRoute = MaterialPageRoute<void>(
          settings: const RouteSettings(name: 'details'),
          builder: (_) => const SizedBox(),
        );
        final previousRoute = MaterialPageRoute<void>(
          settings: const RouteSettings(name: 'home'),
          builder: (_) => const SizedBox(),
        );

        observer.didPop(currentRoute, previousRoute);

        verify(
          () => analyticsService.setCurrentScreen(screenName: 'home'),
        ).called(1);
      },
    );

    test('didRemove sends screen view for previousRoute', () {
      final currentRoute = MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'removed'),
        builder: (_) => const SizedBox(),
      );
      final previousRoute = MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'home'),
        builder: (_) => const SizedBox(),
      );

      observer.didRemove(currentRoute, previousRoute);

      verify(
        () => analyticsService.setCurrentScreen(screenName: 'home'),
      ).called(1);
    });

    test('didReplace sends screen view for newRoute', () {
      final newRoute = MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'new_screen'),
        builder: (_) => const SizedBox(),
      );

      observer.didReplace(newRoute: newRoute);

      verify(
        () => analyticsService.setCurrentScreen(screenName: 'new_screen'),
      ).called(1);
    });

    test('didChangeTop sends screen view for topRoute', () {
      final topRoute = MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'top_screen'),
        builder: (_) => const SizedBox(),
      );

      observer.didChangeTop(topRoute, null);

      verify(
        () => analyticsService.setCurrentScreen(screenName: 'top_screen'),
      ).called(1);
    });
  });
}
