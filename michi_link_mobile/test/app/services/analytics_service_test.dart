import 'package:flutter_test/flutter_test.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:mocktail/mocktail.dart';

class MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

void main() {
  group('AnalyticsService', () {
    late MockAnalyticsRepository repository;
    late AnalyticsService service;

    setUp(() {
      repository = MockAnalyticsRepository();
      service = AnalyticsService(analyticsRepository: repository);
    });

    test('logEvent delegates to repository', () {
      when(
        () => repository.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenReturn(null);

      service.logEvent(name: 'test_event', parameters: {'key': 'value'});

      verify(
        () => repository.logEvent(
          name: 'test_event',
          parameters: {'key': 'value'},
        ),
      ).called(1);
    });

    test('setCurrentScreen delegates to repository', () {
      when(
        () => repository.setCurrentScreen(screenName: any(named: 'screenName')),
      ).thenReturn(null);

      service.setCurrentScreen(screenName: 'HomeScreen');

      verify(
        () => repository.setCurrentScreen(screenName: 'HomeScreen'),
      ).called(1);
    });
  });
}
