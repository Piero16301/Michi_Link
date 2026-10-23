import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/notifications/notifications.dart';
import 'package:mocktail/mocktail.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  group('NotificationsCubit', () {
    late MockDatabaseService databaseService;
    late StreamController<List<AlertRecord>> streamController;

    setUp(() {
      databaseService = MockDatabaseService();
      streamController = StreamController<List<AlertRecord>>.broadcast();

      when(
        () => databaseService.getAlertRecordsStream(
          collarId: any(named: 'collarId'),
        ),
      ).thenAnswer((_) => streamController.stream);
    });

    tearDown(() async {
      await streamController.close();
    });

    test('initial state has provided collarId and empty alerts', () {
      final cubit = NotificationsCubit(
        collarId: 'COLLAR_TEST',
        databaseService: databaseService,
      );

      expect(cubit.state.collarId, 'COLLAR_TEST');
      expect(cubit.state.alerts, isEmpty);
      unawaited(cubit.close());
    });

    test('emits updated alerts when stream emits', () async {
      final cubit = NotificationsCubit(
        collarId: 'COLLAR_TEST',
        databaseService: databaseService,
      );

      final alert = AlertRecord(
        id: 'A1',
        type: AlertType.geofenceBreach,
        severity: AlertSeverity.critical,
        value: 120.5,
        expireAt: DateTime(2026, 1, 2),
        timestamp: DateTime(2026),
      );

      streamController.add([alert]);
      await pumpEventQueue();

      expect(cubit.state.alerts, equals([alert]));
      unawaited(cubit.close());
    });
  });
}
