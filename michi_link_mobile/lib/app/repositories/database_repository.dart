import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expressive_kit/expressive_kit.dart';
import 'package:michi_link_mobile/app/app.dart';

abstract class DatabaseRepository {
  Stream<CollarModel> getCollarStream({required String deviceId});
  void updateCollar({
    required String deviceId,
    required String name,
    required CatBreed breed,
  });
  void updateCollarConfig({
    required String deviceId,
    required CollarConfig config,
  });
  Stream<List<AlertRecord>> getAlertRecordsStream({required String deviceId});
  Stream<List<HistoryRecord>> getHistoryRecordsStream({
    required String deviceId,
    required DateTime start,
    required DateTime end,
  });
  void updateDeviceSettings({
    required String token,
    AppDeviceInfo? deviceInfo,
    String? collarToModify,
    List<String>? enabledCollars,
  });
}

class MockDatabaseRepository implements DatabaseRepository {
  @override
  Stream<CollarModel> getCollarStream({required String deviceId}) {
    return Stream.value(
      CollarModel(
        deviceId: deviceId,
        name: 'Collar 1',
        isOnline: true,
        hasActiveAlert: true,
        packetLossPct: 100,
        packetsLost: 100,
        packetsReceived: 100,
        config: const CollarConfig(
          maxDistanceM: 10,
          minBatteryPct: 10,
          requireGpsFix: true,
          notifLanguage: 'en',
        ),
        coords: const CollarCoords(lat: 0, lon: 0, altM: 0),
        radio: const CollarRadio(
          distanceHomeM: 10,
          rssi: 10,
          snr: 10,
          packetsLostGap: 10,
        ),
        status: const CollarStatus(
          batteryPct: 40,
          batteryV: 3.7,
          gpsFix: true,
          sats: 10,
        ),
        lastSeen: DateTime.now(),
        baseCoords: const CollarCoords(altM: 0, lat: 0, lon: 0),
        seq: 10,
      ),
    );
  }

  @override
  void updateCollar({
    required String deviceId,
    required String name,
    required CatBreed breed,
  }) {}

  @override
  void updateCollarConfig({
    required String deviceId,
    required CollarConfig config,
  }) {}

  @override
  Stream<List<AlertRecord>> getAlertRecordsStream({required String deviceId}) {
    return Stream.value([
      AlertRecord(
        id: '1',
        severity: AlertSeverity.critical,
        type: AlertType.batteryCritical,
        value: 10,
        expireAt: DateTime.now().add(const Duration(hours: 1)),
        timestamp: DateTime.now(),
      ),
      AlertRecord(
        id: '2',
        severity: AlertSeverity.warning,
        type: AlertType.geofenceRestored,
        value: 5,
        expireAt: DateTime.now().add(const Duration(hours: 1)),
        timestamp: DateTime.now(),
      ),
    ]);
  }

  @override
  Stream<List<HistoryRecord>> getHistoryRecordsStream({
    required String deviceId,
    required DateTime start,
    required DateTime end,
  }) {
    return Stream.value([
      HistoryRecord(
        id: '1',
        coords: const CollarCoords(lat: 40.6892, lon: -74.0445, altM: 0),
        timestamp: DateTime.now(),
        radio: const CollarRadio(
          distanceHomeM: 10,
          packetsLostGap: 10,
          rssi: 10,
          snr: 10,
        ),
        seq: 10,
        status: const CollarStatus(
          batteryPct: 40,
          batteryV: 3.7,
          gpsFix: true,
          sats: 10,
        ),
        expireAt: DateTime.now().add(const Duration(hours: 1)),
      ),
      HistoryRecord(
        id: '2',
        coords: const CollarCoords(lat: 34.0522, lon: -118.2437, altM: 0),
        timestamp: DateTime.now().add(const Duration(hours: 1)),
        radio: const CollarRadio(
          distanceHomeM: 10,
          packetsLostGap: 10,
          rssi: 10,
          snr: 10,
        ),
        seq: 10,
        status: const CollarStatus(
          batteryPct: 100,
          batteryV: 4.2,
          gpsFix: true,
          sats: 12,
        ),
        expireAt: DateTime.now().add(const Duration(hours: 1)),
      ),
    ]);
  }

  @override
  void updateDeviceSettings({
    required String token,
    AppDeviceInfo? deviceInfo,
    String? collarToModify,
    List<String>? enabledCollars,
  }) {}
}

class FirestoreDatabaseRepository implements DatabaseRepository {
  FirestoreDatabaseRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _collarDoc(String deviceId) =>
      _firestore.collection('collars').doc(deviceId.trim());

  @override
  Stream<CollarModel> getCollarStream({required String deviceId}) {
    final trimmedId = deviceId.trim();
    if (trimmedId.isEmpty) return const Stream.empty();
    return _collarDoc(trimmedId)
        .snapshots()
        .where((snapshot) => snapshot.exists && snapshot.data() != null)
        .map((snapshot) => CollarModel.fromJson(snapshot.data()!));
  }

  @override
  void updateCollar({
    required String deviceId,
    required String name,
    required CatBreed breed,
  }) {
    final trimmedId = deviceId.trim();
    if (trimmedId.isEmpty) return;
    unawaited(
      _collarDoc(trimmedId).update({'name': name.trim(), 'breed': breed.name}),
    );
  }

  @override
  void updateCollarConfig({
    required String deviceId,
    required CollarConfig config,
  }) {
    final trimmedId = deviceId.trim();
    if (trimmedId.isEmpty) return;
    unawaited(_collarDoc(trimmedId).update({'config': config.toJson()}));
  }

  @override
  Stream<List<AlertRecord>> getAlertRecordsStream({required String deviceId}) {
    final trimmedId = deviceId.trim();
    if (trimmedId.isEmpty) return Stream.value(const []);
    return _collarDoc(trimmedId)
        .collection('alerts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AlertRecord.fromJson(doc.data(), id: doc.id))
              .toList(),
        );
  }

  @override
  Stream<List<HistoryRecord>> getHistoryRecordsStream({
    required String deviceId,
    required DateTime start,
    required DateTime end,
  }) {
    final trimmedId = deviceId.trim();
    if (trimmedId.isEmpty) return Stream.value(const []);
    return _collarDoc(trimmedId)
        .collection('history')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => HistoryRecord.fromJson(doc.data(), id: doc.id))
              .toList(),
        );
  }

  @override
  void updateDeviceSettings({
    required String token,
    AppDeviceInfo? deviceInfo,
    String? collarToModify,
    List<String>? enabledCollars,
  }) {
    final trimmedToken = token.trim();
    if (trimmedToken.isEmpty) return;

    final trimmedCollar = collarToModify?.trim();
    final data = <String, dynamic>{
      if (deviceInfo != null) ...{
        'platform': AppVariables.appOS,
        'token': trimmedToken,
        'lastOpenAt': FieldValue.serverTimestamp(),
        'androidInfo': deviceInfo.toJson(),
      },
      if (trimmedCollar != null &&
          trimmedCollar.isNotEmpty &&
          enabledCollars != null)
        'enabledCollars': enabledCollars.contains(trimmedCollar)
            ? FieldValue.arrayRemove([trimmedCollar])
            : FieldValue.arrayUnion([trimmedCollar])
      else if (collarToModify == null &&
          enabledCollars != null &&
          enabledCollars.isNotEmpty)
        'enabledCollars': FieldValue.arrayUnion(enabledCollars),
    };

    if (data.isNotEmpty) {
      unawaited(
        _firestore
            .collection('devices')
            .doc(trimmedToken)
            .set(data, SetOptions(merge: true)),
      );
    }
  }
}
