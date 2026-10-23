import 'package:flutter_test/flutter_test.dart';
import 'package:michi_link_mobile/app/app.dart';

void main() {
  group('AlertSeverity', () {
    test('fromString returns correct values', () {
      expect(AlertSeverity.fromString('CRITICAL'), AlertSeverity.critical);
      expect(AlertSeverity.fromString('critical'), AlertSeverity.critical);
      expect(AlertSeverity.fromString('WARNING'), AlertSeverity.warning);
      expect(AlertSeverity.fromString('INFO'), AlertSeverity.info);
      expect(AlertSeverity.fromString('UNKNOWN'), AlertSeverity.unknown);
      expect(AlertSeverity.fromString('non_existent'), AlertSeverity.unknown);
      expect(AlertSeverity.fromString(null), AlertSeverity.unknown);
    });

    test('properties return expected values', () {
      expect(AlertSeverity.critical.value, 'CRITICAL');
      expect(AlertSeverity.warning.value, 'WARNING');
      expect(AlertSeverity.info.value, 'INFO');
      expect(AlertSeverity.unknown.value, 'UNKNOWN');
      expect(AlertSeverity.critical.color, isNotNull);
      expect(AlertSeverity.critical.icon, isNotEmpty);
    });
  });

  group('AlertType', () {
    test('fromString returns correct values', () {
      expect(AlertType.fromString('GEOFENCE_BREACH'), AlertType.geofenceBreach);
      expect(
        AlertType.fromString('GEOFENCE_RESTORED'),
        AlertType.geofenceRestored,
      );
      expect(AlertType.fromString('LOW_BATTERY'), AlertType.lowBattery);
      expect(
        AlertType.fromString('BATTERY_CRITICAL'),
        AlertType.batteryCritical,
      );
      expect(AlertType.fromString('BATTERY_NORMAL'), AlertType.batteryNormal);
      expect(AlertType.fromString('NO_GPS_FIX'), AlertType.noGpsFix);
      expect(
        AlertType.fromString('GPS_FIX_RESTORED'),
        AlertType.gpsFixRestored,
      );
      expect(AlertType.fromString('WEAK_SIGNAL'), AlertType.weakSignal);
      expect(AlertType.fromString('SIGNAL_NORMAL'), AlertType.signalNormal);
      expect(AlertType.fromString('UNKNOWN'), AlertType.unknown);
      expect(AlertType.fromString('invalid'), AlertType.unknown);
      expect(AlertType.fromString(null), AlertType.unknown);
    });

    test('isRecovery property returns correctly', () {
      expect(AlertType.geofenceBreach.isRecovery, isFalse);
      expect(AlertType.geofenceRestored.isRecovery, isTrue);
      expect(AlertType.lowBattery.isRecovery, isFalse);
      expect(AlertType.batteryCritical.isRecovery, isFalse);
      expect(AlertType.batteryNormal.isRecovery, isTrue);
      expect(AlertType.noGpsFix.isRecovery, isFalse);
      expect(AlertType.gpsFixRestored.isRecovery, isTrue);
      expect(AlertType.weakSignal.isRecovery, isFalse);
      expect(AlertType.signalNormal.isRecovery, isTrue);
      expect(AlertType.unknown.isRecovery, isFalse);
    });

    test('translationKey returns expected string', () {
      expect(AlertType.geofenceBreach.translationKey, 'alert_geofence_breach');
      expect(AlertType.batteryNormal.translationKey, 'alert_battery_normal');
    });
  });
}
