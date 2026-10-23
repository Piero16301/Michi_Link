import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

void main() {
  group('AnalyticsRepository', () {
    test('MockAnalyticsRepository methods execute without error', () {
      final repo = MockAnalyticsRepository();
      expect(
        () => repo.logEvent(name: 'event', parameters: {}),
        returnsNormally,
      );
      expect(
        () => repo.setCurrentScreen(screenName: 'screen'),
        returnsNormally,
      );
    });

    test(
      'FirebaseAnalyticsRepository delegates logEvent and setCurrentScreen',
      () {
        final analytics = MockFirebaseAnalytics();
        final repo = FirebaseAnalyticsRepository(analytics: analytics);

        when(
          () => analytics.logEvent(
            name: any(named: 'name'),
            parameters: any(named: 'parameters'),
          ),
        ).thenAnswer((_) async {});

        repo.logEvent(name: 'test_event', parameters: {'param': 'val'});
        verify(
          () => analytics.logEvent(
            name: 'test_event',
            parameters: {'param': 'val'},
          ),
        ).called(1);

        repo.setCurrentScreen(screenName: 'home_screen');
        verify(
          () => analytics.logEvent(
            name: 'screen_view',
            parameters: {'screen_name': 'home_screen'},
          ),
        ).called(1);
      },
    );
  });
}
