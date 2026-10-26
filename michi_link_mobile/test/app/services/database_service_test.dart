import 'package:flutter_test/flutter_test.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:mocktail/mocktail.dart';

class MockDatabaseRepositoryInternal extends Mock
    implements DatabaseRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(CatBreed.defaultBreed);
    registerFallbackValue(
      const CollarConfig(
        maxDistanceM: 100,
        minBatteryPct: 20,
        requireGpsFix: true,
        notifLanguage: 'en',
      ),
    );
  });

  group('DatabaseService', () {
    late MockDatabaseRepositoryInternal repository;
    late DatabaseService service;

    setUp(() {
      repository = MockDatabaseRepositoryInternal();
      service = DatabaseService(databaseRepository: repository);
    });

    test('getCollarStream delegates to repository', () {
      final collar = CollarModel.fromJson(const {'device_id': 'COLLAR_1'});
      when(
        () => repository.getCollarStream(deviceId: 'COLLAR_1'),
      ).thenAnswer((_) => Stream.value(collar));

      expect(service.getCollarStream(deviceId: 'COLLAR_1'), emits(collar));
      verify(() => repository.getCollarStream(deviceId: 'COLLAR_1')).called(1);
    });

    test('updateCollar delegates to repository', () {
      when(
        () => repository.updateCollar(
          deviceId: 'COLLAR_1',
          name: 'Michi',
          breed: CatBreed.siamese,
        ),
      ).thenReturn(null);

      service.updateCollar(
        deviceId: 'COLLAR_1',
        name: 'Michi',
        breed: CatBreed.siamese,
      );

      verify(
        () => repository.updateCollar(
          deviceId: 'COLLAR_1',
          name: 'Michi',
          breed: CatBreed.siamese,
        ),
      ).called(1);
    });

    test('updateCollarConfig delegates to repository', () {
      const config = CollarConfig(
        maxDistanceM: 200,
        minBatteryPct: 15,
        requireGpsFix: false,
        notifLanguage: 'es',
      );
      when(
        () =>
            repository.updateCollarConfig(deviceId: 'COLLAR_1', config: config),
      ).thenReturn(null);

      service.updateCollarConfig(deviceId: 'COLLAR_1', config: config);

      verify(
        () =>
            repository.updateCollarConfig(deviceId: 'COLLAR_1', config: config),
      ).called(1);
    });

    test('getAlertRecordsStream delegates to repository', () {
      when(
        () => repository.getAlertRecordsStream(deviceId: 'COLLAR_1'),
      ).thenAnswer((_) => Stream.value([]));

      expect(
        service.getAlertRecordsStream(deviceId: 'COLLAR_1'),
        emits(isEmpty),
      );
      verify(
        () => repository.getAlertRecordsStream(deviceId: 'COLLAR_1'),
      ).called(1);
    });

    test('getHistoryRecordsStream delegates to repository', () {
      final start = DateTime(2026);
      final end = DateTime(2026, 1, 2);
      when(
        () => repository.getHistoryRecordsStream(
          deviceId: 'COLLAR_1',
          start: start,
          end: end,
        ),
      ).thenAnswer((_) => Stream.value([]));

      expect(
        service.getHistoryRecordsStream(
          deviceId: 'COLLAR_1',
          start: start,
          end: end,
        ),
        emits(isEmpty),
      );
      verify(
        () => repository.getHistoryRecordsStream(
          deviceId: 'COLLAR_1',
          start: start,
          end: end,
        ),
      ).called(1);
    });

    test('updateDeviceSettings delegates to repository', () {
      when(
        () => repository.updateDeviceSettings(
          token: 'token123',
          collarToModify: 'COLLAR_1',
          enabledCollars: ['COLLAR_1'],
        ),
      ).thenReturn(null);

      service.updateDeviceSettings(
        token: 'token123',
        collarToModify: 'COLLAR_1',
        enabledCollars: ['COLLAR_1'],
      );

      verify(
        () => repository.updateDeviceSettings(
          token: 'token123',
          collarToModify: 'COLLAR_1',
          enabledCollars: ['COLLAR_1'],
        ),
      ).called(1);
    });
  });
}
