import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/collars/collars.dart';
import 'package:mocktail/mocktail.dart';

class MockLocalStorageService extends Mock implements LocalStorageService {}

class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  setUpAll(() {
    registerFallbackValue(CatBreed.persian);
  });

  group('CollarsCubit', () {
    late MockLocalStorageService localStorage;
    late MockDatabaseService databaseService;
    late StreamController<List<String>> collarsStreamController;

    setUp(() {
      localStorage = MockLocalStorageService();
      databaseService = MockDatabaseService();
      collarsStreamController = StreamController<List<String>>.broadcast();

      when(() => localStorage.getCollars()).thenReturn(['COLLAR_1']);
      when(
        () => localStorage.getCollarsStream(),
      ).thenAnswer((_) => collarsStreamController.stream);
      when(
        () => localStorage.saveCollars(collars: any(named: 'collars')),
      ).thenAnswer((_) async {});
      when(
        () =>
            localStorage.saveSelectedCollarId(collarId: any(named: 'collarId')),
      ).thenAnswer((_) async {});
      when(
        () => databaseService.updateCollar(
          collarId: any(named: 'collarId'),
          name: any(named: 'name'),
          breed: any(named: 'breed'),
        ),
      ).thenAnswer((_) async {});
    });

    tearDown(() async {
      await collarsStreamController.close();
    });

    test('initial state loads collars from local storage', () {
      final cubit = CollarsCubit(
        localStorage: localStorage,
        databaseService: databaseService,
      );

      expect(cubit.state.collars, equals(['COLLAR_1']));
      unawaited(cubit.close());
    });

    test('updates state when collars stream emits new list', () async {
      final cubit = CollarsCubit(
        localStorage: localStorage,
        databaseService: databaseService,
      );

      collarsStreamController.add(['COLLAR_1', 'COLLAR_2']);
      await pumpEventQueue();

      expect(cubit.state.collars, equals(['COLLAR_1', 'COLLAR_2']));
      unawaited(cubit.close());
    });

    group('addCollar', () {
      test('does nothing if collar is already in state', () {
        final cubit = CollarsCubit(
          localStorage: localStorage,
          databaseService: databaseService,
        )..addCollar(deviceId: 'COLLAR_1');

        verifyNever(
          () => localStorage.saveCollars(collars: any(named: 'collars')),
        );
        unawaited(cubit.close());
      });

      test('saves collar and sets selected if it is the first collar', () {
        when(() => localStorage.getCollars()).thenReturn([]);
        final cubit = CollarsCubit(
          localStorage: localStorage,
          databaseService: databaseService,
        )..addCollar(deviceId: 'NEW_COLLAR');

        verify(
          () => localStorage.saveCollars(collars: ['NEW_COLLAR']),
        ).called(1);
        verify(
          () => localStorage.saveSelectedCollarId(collarId: 'NEW_COLLAR'),
        ).called(1);
        unawaited(cubit.close());
      });

      test('saves collar and does not set selected if not first collar', () {
        final cubit = CollarsCubit(
          localStorage: localStorage,
          databaseService: databaseService,
        )..addCollar(deviceId: 'COLLAR_2');

        verify(
          () => localStorage.saveCollars(collars: ['COLLAR_1', 'COLLAR_2']),
        ).called(1);
        verifyNever(
          () => localStorage.saveSelectedCollarId(
            collarId: any(named: 'collarId'),
          ),
        );
        unawaited(cubit.close());
      });
    });

    group('updateCollar', () {
      test('calls databaseService.updateCollar', () {
        final cubit =
            CollarsCubit(
              localStorage: localStorage,
              databaseService: databaseService,
            )..updateCollar(
              collarId: 'COLLAR_1',
              name: 'Michi',
              breed: CatBreed.siamese,
            );

        verify(
          () => databaseService.updateCollar(
            collarId: 'COLLAR_1',
            name: 'Michi',
            breed: CatBreed.siamese,
          ),
        ).called(1);
        unawaited(cubit.close());
      });
    });

    group('removeCollar', () {
      test('does nothing if deviceId is not in list', () {
        final cubit = CollarsCubit(
          localStorage: localStorage,
          databaseService: databaseService,
        )..removeCollar('NON_EXISTENT');

        verifyNever(
          () => localStorage.saveCollars(collars: any(named: 'collars')),
        );
        unawaited(cubit.close());
      });

      test('removes collar and updates selectedCollarId if removed collar was '
          'selected', () {
        when(
          () => localStorage.getCollars(),
        ).thenReturn(['COLLAR_1', 'COLLAR_2']);
        when(() => localStorage.getSelectedCollarId()).thenReturn('COLLAR_1');

        final cubit = CollarsCubit(
          localStorage: localStorage,
          databaseService: databaseService,
        )..removeCollar('COLLAR_1');

        verify(() => localStorage.saveCollars(collars: ['COLLAR_2'])).called(1);
        verify(
          () => localStorage.saveSelectedCollarId(collarId: 'COLLAR_2'),
        ).called(1);
        unawaited(cubit.close());
      });

      test(
        'removes collar and sets selected to null when last collar removed',
        () {
          when(() => localStorage.getCollars()).thenReturn(['COLLAR_1']);
          when(() => localStorage.getSelectedCollarId()).thenReturn('COLLAR_1');

          final cubit = CollarsCubit(
            localStorage: localStorage,
            databaseService: databaseService,
          )..removeCollar('COLLAR_1');

          verify(() => localStorage.saveCollars(collars: [])).called(1);
          verify(() => localStorage.saveSelectedCollarId()).called(1);
          unawaited(cubit.close());
        },
      );

      test(
        'removes collar and does not change selected if different collar was '
        'selected',
        () {
          when(
            () => localStorage.getCollars(),
          ).thenReturn(['COLLAR_1', 'COLLAR_2']);
          when(() => localStorage.getSelectedCollarId()).thenReturn('COLLAR_2');

          final cubit = CollarsCubit(
            localStorage: localStorage,
            databaseService: databaseService,
          )..removeCollar('COLLAR_1');

          verify(
            () => localStorage.saveCollars(collars: ['COLLAR_2']),
          ).called(1);
          verifyNever(
            () => localStorage.saveSelectedCollarId(
              collarId: any(named: 'collarId'),
            ),
          );
          unawaited(cubit.close());
        },
      );
    });
  });
}
