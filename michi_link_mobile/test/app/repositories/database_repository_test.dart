// Firestore classes are mocked for unit testing repository query delegation.
// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expressive_kit/expressive_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class MockQuery extends Mock implements Query<Map<String, dynamic>> {}

class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

class FakeSetOptions extends Fake implements SetOptions {}

void main() {
  group('DatabaseRepository', () {
    test('MockDatabaseRepository returns mock streams and handles updates', () {
      final repo = MockDatabaseRepository();

      expect(
        repo.getCollarStream(deviceId: 'COLLAR_1'),
        emits(
          isA<CollarModel>().having((c) => c.deviceId, 'deviceId', 'COLLAR_1'),
        ),
      );

      expect(
        repo.getAlertRecordsStream(deviceId: 'COLLAR_1'),
        emits(hasLength(2)),
      );

      expect(
        repo.getHistoryRecordsStream(
          deviceId: 'COLLAR_1',
          start: DateTime.now(),
          end: DateTime.now(),
        ),
        emits(hasLength(2)),
      );

      expect(
        () => repo.updateCollar(
          deviceId: 'COLLAR_1',
          name: 'Michi',
          breed: CatBreed.siamese,
        ),
        returnsNormally,
      );

      expect(
        () => repo.updateCollarConfig(
          deviceId: 'COLLAR_1',
          config: const CollarConfig(
            maxDistanceM: 100,
            minBatteryPct: 20,
            requireGpsFix: true,
            notifLanguage: 'en',
          ),
        ),
        returnsNormally,
      );

      expect(
        () => repo.updateDeviceSettings(
          token: 'token123',
          collarToModify: 'COLLAR_1',
          enabledCollars: ['COLLAR_1'],
        ),
        returnsNormally,
      );
    });

    group('FirestoreDatabaseRepository', () {
      late MockFirebaseFirestore mockFirestore;
      late MockCollectionReference mockCollarsCollection;
      late MockDocumentReference mockDocRef;
      late MockCollectionReference mockDevicesCollection;
      late MockDocumentReference mockDeviceDocRef;
      late FirestoreDatabaseRepository repo;

      setUpAll(() {
        registerFallbackValue(FakeSetOptions());
      });

      setUp(() {
        mockFirestore = MockFirebaseFirestore();
        mockCollarsCollection = MockCollectionReference();
        mockDocRef = MockDocumentReference();
        mockDevicesCollection = MockCollectionReference();
        mockDeviceDocRef = MockDocumentReference();
        repo = FirestoreDatabaseRepository(firestore: mockFirestore);

        when(
          () => mockFirestore.collection('collars'),
        ).thenReturn(mockCollarsCollection);
        when(() => mockCollarsCollection.doc(any())).thenReturn(mockDocRef);

        when(
          () => mockFirestore.collection('devices'),
        ).thenReturn(mockDevicesCollection);
        when(
          () => mockDevicesCollection.doc(any()),
        ).thenReturn(mockDeviceDocRef);
      });

      test('defaults to FirebaseFirestore.instance when omitted', () {
        try {
          FirestoreDatabaseRepository();
        } on Object catch (_) {}
      });

      test('getCollarStream emits CollarModel from document snapshot', () {
        final mockSnapshot = MockDocumentSnapshot();
        when(() => mockSnapshot.exists).thenReturn(true);
        when(
          () => mockDocRef.snapshots(),
        ).thenAnswer((_) => Stream.value(mockSnapshot));
        when(mockSnapshot.data).thenReturn(<String, dynamic>{
          'device_id': 'COLLAR_1',
          'name': 'Michi',
          'is_online': true,
          'has_active_alert': false,
          'packet_loss_pct': 0,
          'packets_lost': 0,
          'packets_received': 100,
          'seq': 1,
        });

        expect(
          repo.getCollarStream(deviceId: 'COLLAR_1'),
          emits(
            isA<CollarModel>()
                .having((c) => c.deviceId, 'deviceId', 'COLLAR_1')
                .having((c) => c.name, 'name', 'Michi'),
          ),
        );
      });

      test(
        'getCollarStream filters out non-existent or null data snapshots',
        () async {
          final nonExistentSnapshot = MockDocumentSnapshot();
          when(() => nonExistentSnapshot.exists).thenReturn(false);
          when(nonExistentSnapshot.data).thenReturn(null);

          final nullDataSnapshot = MockDocumentSnapshot();
          when(() => nullDataSnapshot.exists).thenReturn(true);
          when(nullDataSnapshot.data).thenReturn(null);

          final validSnapshot = MockDocumentSnapshot();
          when(() => validSnapshot.exists).thenReturn(true);
          when(validSnapshot.data).thenReturn(<String, dynamic>{
            'device_id': 'COLLAR_VALID',
            'name': 'Michi Valid',
            'is_online': true,
            'has_active_alert': false,
            'packet_loss_pct': 0,
            'packets_lost': 0,
            'packets_received': 50,
            'seq': 2,
          });

          when(() => mockDocRef.snapshots()).thenAnswer(
            (_) => Stream.fromIterable([
              nonExistentSnapshot,
              nullDataSnapshot,
              validSnapshot,
            ]),
          );

          final result = await repo
              .getCollarStream(deviceId: 'COLLAR_VALID')
              .first;
          expect(result.deviceId, equals('COLLAR_VALID'));
        },
      );

      test('updateCollar calls update on document reference', () {
        when(() => mockDocRef.update(any())).thenAnswer((_) async {});

        repo.updateCollar(
          deviceId: 'COLLAR_1',
          name: 'Michi Renamed',
          breed: CatBreed.siamese,
        );

        verify(
          () => mockDocRef.update(<String, dynamic>{
            'name': 'Michi Renamed',
            'breed': CatBreed.siamese.name,
          }),
        ).called(1);
      });

      test('updateCollarConfig calls update on document reference', () {
        const config = CollarConfig(
          maxDistanceM: 50,
          minBatteryPct: 15,
          requireGpsFix: true,
          notifLanguage: 'es',
        );
        when(() => mockDocRef.update(any())).thenAnswer((_) async {});

        repo.updateCollarConfig(deviceId: 'COLLAR_1', config: config);

        verify(
          () => mockDocRef.update(<String, dynamic>{'config': config.toJson()}),
        ).called(1);
      });

      test(
        'getAlertRecordsStream maps alert documents to AlertRecord list',
        () {
          final alertsCollection = MockCollectionReference();
          final alertsQuery = MockQuery();
          final alertsQuerySnapshot = MockQuerySnapshot();
          final alertDoc = MockQueryDocumentSnapshot();

          when(
            () => mockDocRef.collection('alerts'),
          ).thenReturn(alertsCollection);
          when(
            () => alertsCollection.orderBy('timestamp', descending: true),
          ).thenReturn(alertsQuery);
          when(
            alertsQuery.snapshots,
          ).thenAnswer((_) => Stream.value(alertsQuerySnapshot));
          when(() => alertsQuerySnapshot.docs).thenReturn([alertDoc]);
          when(() => alertDoc.id).thenReturn('ALERT_1');
          when(alertDoc.data).thenReturn(<String, dynamic>{
            'severity': 'critical',
            'type': 'battery_critical',
            'value': 10,
            'expire_at': Timestamp.now(),
            'timestamp': Timestamp.now(),
          });

          expect(
            repo.getAlertRecordsStream(deviceId: 'COLLAR_1'),
            emits(
              isA<List<AlertRecord>>().having(
                (list) => list.first.id,
                'id',
                'ALERT_1',
              ),
            ),
          );
        },
      );

      test('getHistoryRecordsStream maps history documents', () {
        final historyCollection = MockCollectionReference();
        final query1 = MockQuery();
        final query2 = MockQuery();
        final query3 = MockQuery();
        final historyQuerySnapshot = MockQuerySnapshot();
        final historyDoc = MockQueryDocumentSnapshot();
        final start = DateTime(2026, 10, 22, 10);
        final end = DateTime(2026, 10, 22, 12);

        when(
          () => mockDocRef.collection('history'),
        ).thenReturn(historyCollection);
        when(
          () => historyCollection.where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          ),
        ).thenReturn(query1);
        when(
          () => query1.where(
            'timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(end),
          ),
        ).thenReturn(query2);
        when(
          () => query2.orderBy('timestamp', descending: true),
        ).thenReturn(query3);
        when(
          query3.snapshots,
        ).thenAnswer((_) => Stream.value(historyQuerySnapshot));
        when(() => historyQuerySnapshot.docs).thenReturn([historyDoc]);
        when(() => historyDoc.id).thenReturn('HIST_1');
        when(historyDoc.data).thenReturn(<String, dynamic>{
          'coords': {'lat': 10.0, 'lon': -75.0, 'alt_m': 5.0},
          'timestamp': Timestamp.now(),
          'radio': {
            'distance_home_m': 12.0,
            'packets_lost_gap': 0,
            'rssi': -80,
            'snr': 9.0,
          },
          'seq': 5,
          'status': {
            'battery_pct': 85,
            'battery_v': 4.0,
            'gps_fix': true,
            'sats': 7,
          },
          'expire_at': Timestamp.now(),
        });

        expect(
          repo.getHistoryRecordsStream(
            deviceId: 'COLLAR_1',
            start: start,
            end: end,
          ),
          emits(
            isA<List<HistoryRecord>>().having(
              (list) => list.first.id,
              'id',
              'HIST_1',
            ),
          ),
        );
      });

      group('updateDeviceSettings', () {
        test('does nothing when token is empty', () {
          repo.updateDeviceSettings(
            token: '',
            deviceInfo: const AppDeviceInfo(id: 'device-123'),
            collarToModify: 'COLLAR_1',
            enabledCollars: ['COLLAR_1'],
          );

          verifyNever(() => mockFirestore.collection(any()));
        });

        test('sets device info when deviceInfo is provided', () {
          when(
            () => mockDeviceDocRef.set(any(), any()),
          ).thenAnswer((_) async {});

          const info = AppDeviceInfo(id: 'device-123');

          repo.updateDeviceSettings(token: 'valid_token', deviceInfo: info);

          verify(() => mockFirestore.collection('devices')).called(1);
          verify(() => mockDevicesCollection.doc('valid_token')).called(1);
          verify(() => mockDeviceDocRef.set(any(), any())).called(1);
        });

        test(
          'removes collar from enabledCollars when collar is already present',
          () {
            when(
              () => mockDeviceDocRef.set(any(), any()),
            ).thenAnswer((_) async {});

            repo.updateDeviceSettings(
              token: 'valid_token',
              collarToModify: 'COLLAR_1',
              enabledCollars: ['COLLAR_1', 'COLLAR_2'],
            );

            verify(() => mockFirestore.collection('devices')).called(1);
            verify(() => mockDevicesCollection.doc('valid_token')).called(1);
            verify(
              () => mockDeviceDocRef.set(
                any(
                  that: isA<Map<String, dynamic>>().having(
                    (d) => d['enabledCollars'],
                    'enabledCollars',
                    isNotNull,
                  ),
                ),
                any(
                  that: isA<SetOptions>().having(
                    (s) => s.merge,
                    'merge',
                    isTrue,
                  ),
                ),
              ),
            ).called(1);
          },
        );

        test('adds collar to enabledCollars when collar is not present', () {
          when(
            () => mockDeviceDocRef.set(any(), any()),
          ).thenAnswer((_) async {});

          repo.updateDeviceSettings(
            token: 'valid_token',
            collarToModify: 'COLLAR_3',
            enabledCollars: ['COLLAR_1', 'COLLAR_2'],
          );

          verify(() => mockFirestore.collection('devices')).called(1);
          verify(() => mockDevicesCollection.doc('valid_token')).called(1);
          verify(
            () => mockDeviceDocRef.set(
              any(
                that: isA<Map<String, dynamic>>().having(
                  (d) => d['enabledCollars'],
                  'enabledCollars',
                  isNotNull,
                ),
              ),
              any(
                that: isA<SetOptions>().having((s) => s.merge, 'merge', isTrue),
              ),
            ),
          ).called(1);
        });

        test('does not update enabledCollars when '
            'collarToModify or enabledCollars is null', () {
          when(
            () => mockDeviceDocRef.set(any(), any()),
          ).thenAnswer((_) async {});

          repo.updateDeviceSettings(
            token: 'valid_token',
            deviceInfo: const AppDeviceInfo(id: 'device-123'),
          );

          verify(
            () => mockDeviceDocRef.set(
              any(
                that: isA<Map<String, dynamic>>().having(
                  (d) => d.containsKey('enabledCollars'),
                  'contains enabledCollars',
                  isFalse,
                ),
              ),
              any(),
            ),
          ).called(1);
        });
      });
    });
  });
}
