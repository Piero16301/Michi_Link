import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:michi_link_mobile/app/app.dart';

abstract class DatabaseRepository {
  Stream<CollarModel> getCollarStream({required String collarId});
  void updateCollar({
    required String collarId,
    required String name,
    required CatBreed breed,
  });
  void updateCollarConfig({
    required String collarId,
    required CollarConfig config,
  });
}

class MockDatabaseRepository implements DatabaseRepository {
  @override
  Stream<CollarModel> getCollarStream({required String collarId}) {
    return Stream.value(
      CollarModel(
        deviceId: collarId,
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
    required String collarId,
    required String name,
    required CatBreed breed,
  }) {}

  @override
  void updateCollarConfig({
    required String collarId,
    required CollarConfig config,
  }) {}
}

class FirestoreDatabaseRepository implements DatabaseRepository {
  FirestoreDatabaseRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<CollarModel> getCollarStream({required String collarId}) {
    return _firestore
        .collection('collars')
        .doc(collarId)
        .snapshots()
        .map((snapshot) => CollarModel.fromJson(snapshot.data()!));
  }

  @override
  void updateCollar({
    required String collarId,
    required String name,
    required CatBreed breed,
  }) {
    unawaited(
      _firestore.collection('collars').doc(collarId).update({
        'name': name,
        'breed': breed.name,
      }),
    );
  }

  @override
  void updateCollarConfig({
    required String collarId,
    required CollarConfig config,
  }) {
    unawaited(
      _firestore.collection('collars').doc(collarId).update({
        'config': config.toJson(),
      }),
    );
  }
}
