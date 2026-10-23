import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/notifications/notifications.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_app.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  group('NotificationsView', () {
    late MockDatabaseService databaseService;
    late StreamController<List<AlertRecord>> streamController;

    setUp(() async {
      databaseService = MockDatabaseService();
      streamController = StreamController<List<AlertRecord>>.broadcast();

      when(
        () => databaseService.getAlertRecordsStream(
          collarId: any(named: 'collarId'),
        ),
      ).thenAnswer((_) => streamController.stream);

      if (getIt.isRegistered<DatabaseService>()) {
        await getIt.unregister<DatabaseService>();
      }
      getIt.registerSingleton<DatabaseService>(databaseService);
    });

    tearDown(() async {
      await streamController.close();
      if (getIt.isRegistered<DatabaseService>()) {
        getIt.unregister<DatabaseService>();
      }
    });

    testWidgets('renders LoadingNotificationCard when stream has no data yet', (
      tester,
    ) async {
      await tester.pumpApp(const NotificationsView(collarId: 'COLLAR_TEST'));

      expect(find.byType(LoadingNotificationCard), findsWidgets);
    });

    testWidgets('renders empty state when alerts list is empty', (
      tester,
    ) async {
      await tester.pumpApp(const NotificationsView(collarId: 'COLLAR_TEST'));

      streamController.add([]);
      await tester.pump();

      expect(find.byType(NotificationCard), findsNothing);
    });

    testWidgets('renders notification items and headers when alerts arrive', (
      tester,
    ) async {
      await tester.pumpApp(const NotificationsView(collarId: 'COLLAR_TEST'));

      final alerts = [
        AlertRecord(
          id: 'A1',
          type: AlertType.geofenceBreach,
          severity: AlertSeverity.critical,
          value: 120,
          expireAt: DateTime.now().add(const Duration(days: 7)),
          timestamp: DateTime.now(),
        ),
        AlertRecord(
          id: 'A2',
          type: AlertType.lowBattery,
          severity: AlertSeverity.warning,
          value: 15,
          expireAt: DateTime.now().add(const Duration(days: 6)),
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];

      streamController.add(alerts);
      await tester.pump();

      expect(find.byType(NotificationCard), findsNWidgets(2));
    });

    testWidgets('renders SizedBox.shrink on stream error', (tester) async {
      await tester.pumpApp(const NotificationsView(collarId: 'COLLAR_TEST'));

      streamController.addError(Exception('error'));
      await tester.pump();

      expect(find.byType(NotificationCard), findsNothing);
      expect(find.byType(LoadingNotificationCard), findsNothing);
    });
  });
}
