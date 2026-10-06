import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michi_link_mobile/app/global/app_enums.dart';
import 'package:michi_link_mobile/app/models/alert_record.dart';
import 'package:michi_link_mobile/app/models/collar_config.dart';
import 'package:michi_link_mobile/app/models/collar_coords.dart';
import 'package:michi_link_mobile/app/models/collar_last_alert.dart';
import 'package:michi_link_mobile/app/models/collar_model.dart';
import 'package:michi_link_mobile/app/models/collar_radio.dart';
import 'package:michi_link_mobile/app/models/collar_status.dart';
import 'package:michi_link_mobile/app/models/history_record.dart';

void main() {
  group('Models Serialization Test', () {
    test('CollarCoords parses and converts correctly', () {
      final json = <String, dynamic>{
        'alt_m': 35.0,
        'lat': -8.0666408,
        'lon': -79.0628176,
      };

      final coords = CollarCoords.fromJson(json);
      expect(coords.altM, 35.0);
      expect(coords.lat, -8.0666408);
      expect(coords.lon, -79.0628176);
      expect(coords.toJson(), json);
    });

    test('CollarStatus parses and converts correctly', () {
      final json = <String, dynamic>{
        'battery_pct': 91,
        'battery_v': 3.99,
        'gps_fix': true,
        'sats': 13,
      };

      final status = CollarStatus.fromJson(json);
      expect(status.batteryPct, 91);
      expect(status.batteryV, 3.99);
      expect(status.gpsFix, isTrue);
      expect(status.sats, 13);
      expect(status.toJson(), json);
    });

    test('CollarRadio parses and converts correctly', () {
      final json = <String, dynamic>{
        'distance_home_m': 2.7,
        'packets_lost_gap': 0,
        'rssi': -43,
        'snr': 13.3,
        'seq': 272,
      };

      final radio = CollarRadio.fromJson(json);
      expect(radio.distanceHomeM, 2.7);
      expect(radio.packetsLostGap, 0);
      expect(radio.rssi, -43);
      expect(radio.snr, 13.3);
      expect(radio.toJson(), json);
    });

    test('CollarConfig parses and converts correctly', () {
      final json = <String, dynamic>{
        'max_distance_m': 500,
        'min_battery_pct': 20,
        'require_gps_fix': true,
      };

      final config = CollarConfig.fromJson(json);
      expect(config.maxDistanceM, 500);
      expect(config.minBatteryPct, 20);
      expect(config.requireGpsFix, isTrue);
      expect(config.toJson(), json);
    });

    test('CollarLastAlert parses and converts correctly', () {
      final now = DateTime.now();
      final timestamp = Timestamp.fromDate(now);

      final json = <String, dynamic>{
        'severity': 'INFO',
        'type': 'SIGNAL_NORMAL',
        'value': -97,
        'timestamp': timestamp,
      };

      final alert = CollarLastAlert.fromJson(json);
      expect(alert.severity, AlertSeverity.info);
      expect(alert.type, AlertType.signalNormal);
      expect(alert.value, -97);
      expect(alert.timestamp, now.toLocal());
      expect(alert.toJson()['timestamp'], now.toUtc());
    });

    test('CollarModel parses and converts correctly', () {
      final now = DateTime.now();
      final timestamp = Timestamp.fromDate(now);

      final json = <String, dynamic>{
        'device_id': 'COLLAR_9E2B4A1F8C3D2E5A',
        'name': 'Mi Mascota',
        'is_online': false,
        'has_active_alert': false,
        'last_seen': timestamp,
        'packet_loss_pct': '14.43%',
        'packets_lost': 71,
        'packets_received': 421,
        'config': {
          'max_distance_m': 500,
          'min_battery_pct': 20,
          'require_gps_fix': true,
        },
        'coords': {'alt_m': 35.0, 'lat': -8.0666408, 'lon': -79.0628176},
        'last_alert': {
          'severity': 'INFO',
          'type': 'SIGNAL_NORMAL',
          'value': -97,
          'timestamp': timestamp,
        },
        'radio': {
          'distance_home_m': 2.7,
          'packets_lost_gap': 0,
          'rssi': -43,
          'snr': 13.3,
          'seq': 272,
        },
        'status': {
          'battery_pct': 91,
          'battery_v': 3.99,
          'gps_fix': true,
          'sats': 13,
        },
      };

      final collar = CollarModel.fromJson(json);
      expect(collar.deviceId, 'COLLAR_9E2B4A1F8C3D2E5A');
      expect(collar.name, 'Mi Mascota');
      expect(collar.isOnline, isFalse);
      expect(collar.hasActiveAlert, isFalse);
      expect(collar.packetsLost, 71);
      expect(collar.packetsReceived, 421);
      expect(collar.config.maxDistanceM, 500);
      expect(collar.coords.lat, -8.0666408);
      expect(collar.lastAlert?.type, AlertType.signalNormal);
      expect(collar.status.batteryPct, 91);
      expect(collar.lastSeen, now.toLocal());
      expect(collar.toJson()['last_seen'], now.toUtc());
    });

    test('HistoryRecord parses and converts correctly', () {
      final now = DateTime.now();
      final timestamp = Timestamp.fromDate(now);

      final json = <String, dynamic>{
        'coords': {'alt_m': 82.0, 'lat': -8.0667321, 'lon': -79.0627358},
        'expire_at': timestamp,
        'radio': {
          'distance_home_m': 11.0,
          'packets_lost_gap': 0,
          'rssi': -19,
          'snr': 13.0,
          'seq': 178,
        },
        'status': {
          'battery_pct': 95,
          'battery_v': 4.01,
          'gps_fix': true,
          'sats': 13,
        },
        'timestamp': timestamp,
      };

      final history = HistoryRecord.fromJson(json, id: '0FTQ4hUaqlvgDTWJDycW');
      expect(history.id, '0FTQ4hUaqlvgDTWJDycW');
      expect(history.coords.altM, 82.0);
      expect(history.radio.distanceHomeM, 11.0);
      expect(history.status.batteryV, 4.01);
      expect(history.timestamp, now.toLocal());
      expect(history.expireAt, now.toLocal());
      expect(history.toJson()['timestamp'], now.toUtc());
      expect(history.toJson()['expire_at'], now.toUtc());
    });

    test('AlertRecord parses and converts correctly', () {
      final now = DateTime.now();
      final timestamp = Timestamp.fromDate(now);

      final json = <String, dynamic>{
        'expire_at': timestamp,
        'severity': 'INFO',
        'timestamp': timestamp,
        'type': 'BATTERY_NORMAL',
        'value': 59,
      };

      final alert = AlertRecord.fromJson(json, id: '5k7aq0EYUV7l6Omn5j1r');
      expect(alert.id, '5k7aq0EYUV7l6Omn5j1r');
      expect(alert.severity, AlertSeverity.info);
      expect(alert.type, AlertType.batteryNormal);
      expect(alert.value, 59);
      expect(alert.timestamp, now.toLocal());
      expect(alert.expireAt, now.toLocal());
      expect(alert.toJson()['timestamp'], now.toUtc());
      expect(alert.toJson()['expire_at'], now.toUtc());
    });
  });
}
