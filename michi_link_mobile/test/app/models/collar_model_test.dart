import 'package:flutter_test/flutter_test.dart';
import 'package:michi_link_mobile/app/app.dart';

void main() {
  group('CollarModel', () {
    test('fromJson handles null / empty fields with defaults', () {
      final model = CollarModel.fromJson(const {});
      expect(model.deviceId, '');
      expect(model.name, '');
      expect(model.isOnline, isFalse);
      expect(model.hasActiveAlert, isFalse);
      expect(model.packetLossPct, 0);
      expect(model.packetsLost, 0);
      expect(model.packetsReceived, 0);
      expect(model.config.maxDistanceM, 0);
      expect(model.coords.lat, 0);
      expect(model.baseCoords.lat, 0);
      expect(model.lastAlert, isNull);
      expect(model.radio.rssi, 0);
      expect(model.seq, 0);
      expect(model.status.batteryPct, 0);
      expect(model.breed, CatBreed.defaultBreed);
    });

    test('copyWith updates fields properly', () {
      final model = CollarModel.fromJson(const {});
      final updated = model.copyWith(
        deviceId: 'NEW_ID',
        name: 'New Name',
        isOnline: true,
        hasActiveAlert: true,
        packetLossPct: 5.5,
        packetsLost: 2,
        packetsReceived: 100,
        breed: CatBreed.siamese,
      );

      expect(updated.deviceId, 'NEW_ID');
      expect(updated.name, 'New Name');
      expect(updated.isOnline, isTrue);
      expect(updated.hasActiveAlert, isTrue);
      expect(updated.packetLossPct, 5.5);
      expect(updated.packetsLost, 2);
      expect(updated.packetsReceived, 100);
      expect(updated.breed, CatBreed.siamese);
      expect(updated.props, isNotEmpty);
    });
  });
}
