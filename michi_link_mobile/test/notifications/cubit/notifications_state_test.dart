import 'package:flutter_test/flutter_test.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/notifications/notifications.dart';

void main() {
  group('NotificationsState', () {
    test('supports value equality', () {
      expect(const NotificationsState(), equals(const NotificationsState()));
    });

    test('copyWith updates fields correctly', () {
      const state = NotificationsState();
      final alert = AlertRecord(
        id: '1',
        type: AlertType.lowBattery,
        severity: AlertSeverity.warning,
        value: 15,
        expireAt: DateTime(2026, 1, 2),
        timestamp: DateTime(2026),
      );

      final updated = state.copyWith(collarId: 'COLLAR_1', alerts: [alert]);

      expect(updated.collarId, 'COLLAR_1');
      expect(updated.alerts, [alert]);
      expect(updated.props, [
        'COLLAR_1',
        [alert],
        NotificationsStatus.loading,
      ]);
    });

    test('copyWith updates status correctly', () {
      const state = NotificationsState();
      final updated = state.copyWith(status: NotificationsStatus.success);
      expect(updated.status, NotificationsStatus.success);
    });

    test('copyWith preserves fields when null passed', () {
      const state = NotificationsState(
        collarId: 'COLLAR_1',
        status: NotificationsStatus.success,
      );
      final updated = state.copyWith();
      expect(updated.collarId, 'COLLAR_1');
      expect(updated.status, NotificationsStatus.success);
    });
  });
}
