import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:michi_link_mobile/app/app.dart';

abstract class DatabaseRepository {
  Stream<CollarModel> getCollarStream(String deviceId);
}

class MockDatabaseRepository implements DatabaseRepository {
  @override
  Stream<CollarModel> getCollarStream(String deviceId) {
    return Stream.value(
      CollarModel(
        deviceId: deviceId,
        name: 'Collar 1',
        isOnline: true,
        hasActiveAlert: true,
        packetLossPct: '100',
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
          seq: 10,
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
      ),
    );
  }
}

class FirestoreDatabaseRepository implements DatabaseRepository {
  FirestoreDatabaseRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<CollarModel> getCollarStream(String deviceId) {
    return _firestore
        .collection('collars')
        .doc(deviceId)
        .snapshots()
        .map((snapshot) => CollarModel.fromJson(snapshot.data()!));
  }
}
