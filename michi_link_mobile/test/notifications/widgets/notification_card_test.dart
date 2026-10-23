import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/notifications/notifications.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('NotificationCard', () {
    testWidgets('renders critical geofence breach alert and formats distance', (
      tester,
    ) async {
      final alert = AlertRecord(
        id: '1',
        type: AlertType.geofenceBreach,
        severity: AlertSeverity.critical,
        value: 150.5,
        expireAt: DateTime(2026, 5, 11),
        timestamp: DateTime(2026, 5, 10, 14, 30),
      );

      await tester.pumpApp(Scaffold(body: NotificationCard(alert: alert)));

      expect(find.byType(NotificationCard), findsOneWidget);
      expect(find.text('14:30'), findsOneWidget);
    });

    testWidgets('renders recovery alert with normal status', (tester) async {
      final alert = AlertRecord(
        id: '2',
        type: AlertType.geofenceRestored,
        severity: AlertSeverity.info,
        value: 10,
        expireAt: DateTime(2026, 5, 11),
        timestamp: DateTime(2026, 5, 10, 15),
      );

      await tester.pumpApp(Scaffold(body: NotificationCard(alert: alert)));

      expect(find.byType(NotificationCard), findsOneWidget);
    });

    testWidgets('renders full date when showFullDate is true', (tester) async {
      final alert = AlertRecord(
        id: '3',
        type: AlertType.lowBattery,
        severity: AlertSeverity.warning,
        value: 18,
        expireAt: DateTime(2026, 5, 11),
        timestamp: DateTime(2026, 5, 10, 16, 45),
      );

      await tester.pumpApp(
        Scaffold(body: NotificationCard(alert: alert, showFullDate: true)),
      );

      expect(find.text('10/05/2026 • 16:45'), findsOneWidget);
    });

    testWidgets('renders batteryCritical alert', (tester) async {
      final alert = AlertRecord(
        id: '4',
        type: AlertType.batteryCritical,
        severity: AlertSeverity.critical,
        value: 5,
        expireAt: DateTime(2026, 5, 11),
        timestamp: DateTime(2026, 5, 10, 17),
      );

      await tester.pumpApp(Scaffold(body: NotificationCard(alert: alert)));

      expect(find.byType(NotificationCard), findsOneWidget);
    });

    testWidgets('renders batteryNormal alert', (tester) async {
      final alert = AlertRecord(
        id: '5',
        type: AlertType.batteryNormal,
        severity: AlertSeverity.info,
        value: 90,
        expireAt: DateTime(2026, 5, 11),
        timestamp: DateTime(2026, 5, 10, 18),
      );

      await tester.pumpApp(Scaffold(body: NotificationCard(alert: alert)));

      expect(find.byType(NotificationCard), findsOneWidget);
    });

    testWidgets('renders noGpsFix alert', (tester) async {
      final alert = AlertRecord(
        id: '6',
        type: AlertType.noGpsFix,
        severity: AlertSeverity.warning,
        value: 0,
        expireAt: DateTime(2026, 5, 11),
        timestamp: DateTime(2026, 5, 10, 19),
      );

      await tester.pumpApp(Scaffold(body: NotificationCard(alert: alert)));

      expect(find.byType(NotificationCard), findsOneWidget);
    });

    testWidgets('renders gpsFixRestored alert', (tester) async {
      final alert = AlertRecord(
        id: '7',
        type: AlertType.gpsFixRestored,
        severity: AlertSeverity.info,
        value: 8,
        expireAt: DateTime(2026, 5, 11),
        timestamp: DateTime(2026, 5, 10, 20),
      );

      await tester.pumpApp(Scaffold(body: NotificationCard(alert: alert)));

      expect(find.byType(NotificationCard), findsOneWidget);
    });

    testWidgets('renders weakSignal alert', (tester) async {
      final alert = AlertRecord(
        id: '8',
        type: AlertType.weakSignal,
        severity: AlertSeverity.warning,
        value: -95,
        expireAt: DateTime(2026, 5, 11),
        timestamp: DateTime(2026, 5, 10, 21),
      );

      await tester.pumpApp(Scaffold(body: NotificationCard(alert: alert)));

      expect(find.byType(NotificationCard), findsOneWidget);
    });

    testWidgets('renders signalNormal alert', (tester) async {
      final alert = AlertRecord(
        id: '9',
        type: AlertType.signalNormal,
        severity: AlertSeverity.info,
        value: -65,
        expireAt: DateTime(2026, 5, 11),
        timestamp: DateTime(2026, 5, 10, 22),
      );

      await tester.pumpApp(Scaffold(body: NotificationCard(alert: alert)));

      expect(find.byType(NotificationCard), findsOneWidget);
    });

    testWidgets('renders unknown type and severity alert', (tester) async {
      final alert = AlertRecord(
        id: '10',
        type: AlertType.unknown,
        severity: AlertSeverity.unknown,
        value: 0,
        expireAt: DateTime(2026, 5, 11),
        timestamp: DateTime(2026, 5, 10, 23),
      );

      await tester.pumpApp(Scaffold(body: NotificationCard(alert: alert)));

      expect(find.byType(NotificationCard), findsOneWidget);
    });
  });
}
