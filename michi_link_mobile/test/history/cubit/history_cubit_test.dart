import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/history/history.dart';

void main() {
  group('HistoryCubit', () {
    final testDate = DateTime(2026, 10, 15);

    test('initial state has correct defaults (last hour of current day)', () {
      final cubit = HistoryCubit(collarId: 'collar_123', initialDate: testDate);

      final now = DateTime.now();
      expect(cubit.state.collarId, equals('collar_123'));
      expect(cubit.state.selectedDate, equals(testDate));
      expect(
        cubit.state.startHour,
        equals(now.hour.toDouble().clamp(0.0, 23.0)),
      );
      expect(
        cubit.state.endHour,
        equals((now.hour + 1).toDouble().clamp(1.0, 24.0)),
      );
      expect(cubit.state.selectedRecord, isNull);
      unawaited(cubit.close());
    });

    test('initial state accepts explicit startHour and endHour', () {
      final cubit = HistoryCubit(
        collarId: 'collar_123',
        initialDate: testDate,
        initialStartHour: 8,
        initialEndHour: 12,
      );

      expect(cubit.state.startHour, equals(8));
      expect(cubit.state.endHour, equals(12));
      unawaited(cubit.close());
    });

    blocTest<HistoryCubit, HistoryState>(
      'selectDate updates selectedDate',
      build: () => HistoryCubit(collarId: 'collar_123', initialDate: testDate),
      act: (cubit) => cubit.selectDate(DateTime(2026, 10, 10)),
      expect: () => [
        isA<HistoryState>().having(
          (s) => s.selectedDate,
          'selectedDate',
          DateTime(2026, 10, 10),
        ),
      ],
    );

    blocTest<HistoryCubit, HistoryState>(
      'previousDay decrements date by 1 day',
      build: () => HistoryCubit(collarId: 'collar_123', initialDate: testDate),
      act: (cubit) => cubit.previousDay(),
      expect: () => [
        isA<HistoryState>().having(
          (s) => s.selectedDate,
          'selectedDate',
          DateTime(2026, 10, 14),
        ),
      ],
    );

    blocTest<HistoryCubit, HistoryState>(
      'changeTimeRange updates startHour and endHour',
      build: () => HistoryCubit(collarId: 'collar_123', initialDate: testDate),
      act: (cubit) => cubit.changeTimeRange(8, 16),
      expect: () => [
        isA<HistoryState>()
            .having((s) => s.startHour, 'startHour', 8)
            .having((s) => s.endHour, 'endHour', 16),
      ],
    );

    test(
      'initial state defaults to now when no optional arguments provided',
      () {
        final cubit = HistoryCubit(collarId: 'collar_456');
        final now = DateTime.now();

        expect(cubit.state.collarId, equals('collar_456'));
        expect(cubit.state.selectedDate?.year, equals(now.year));
        expect(cubit.state.selectedDate?.month, equals(now.month));
        expect(cubit.state.selectedDate?.day, equals(now.day));
        expect(
          cubit.state.startHour,
          equals(now.hour.toDouble().clamp(0.0, 23.0)),
        );
        expect(
          cubit.state.endHour,
          equals((now.hour + 1).toDouble().clamp(1.0, 24.0)),
        );
        unawaited(cubit.close());
      },
    );

    blocTest<HistoryCubit, HistoryState>(
      'selectDate does not emit when clean date matches current selectedDate',
      build: () => HistoryCubit(collarId: 'collar_123', initialDate: testDate),
      act: (cubit) => cubit.selectDate(DateTime(2026, 10, 15, 14, 30)),
      expect: () => <HistoryState>[],
    );

    blocTest<HistoryCubit, HistoryState>(
      'nextDay increments date when next day is not after today',
      build: () => HistoryCubit(collarId: 'collar_123', initialDate: testDate),
      act: (cubit) => cubit.nextDay(),
      expect: () => [
        isA<HistoryState>().having(
          (s) => s.selectedDate,
          'selectedDate',
          DateTime(2026, 10, 16),
        ),
      ],
    );

    blocTest<HistoryCubit, HistoryState>(
      'nextDay does not advance when next day is after today',
      build: () {
        final now = DateTime.now();
        return HistoryCubit(
          collarId: 'collar_123',
          initialDate: DateTime(now.year, now.month, now.day),
        );
      },
      act: (cubit) => cubit.nextDay(),
      expect: () => <HistoryState>[],
    );

    blocTest<HistoryCubit, HistoryState>(
      'changeTimeRange does not emit when startHour and endHour are identical',
      build: () => HistoryCubit(
        collarId: 'collar_123',
        initialDate: testDate,
        initialStartHour: 8,
        initialEndHour: 16,
      ),
      act: (cubit) => cubit.changeTimeRange(8, 16),
      expect: () => <HistoryState>[],
    );

    blocTest<HistoryCubit, HistoryState>(
      'selectRecord updates selectedRecord',
      build: () => HistoryCubit(collarId: 'collar_123', initialDate: testDate),
      act: (cubit) {
        final record = HistoryRecord(
          id: 'rec_1',
          coords: const CollarCoords(lat: 40.7, lon: -74, altM: 10),
          radio: const CollarRadio(
            distanceHomeM: 20,
            packetsLostGap: 0,
            rssi: -80,
            snr: 8.5,
          ),
          seq: 1,
          status: const CollarStatus(
            batteryPct: 90,
            batteryV: 4.1,
            gpsFix: true,
            sats: 8,
          ),
          expireAt: DateTime.now().add(const Duration(days: 7)),
          timestamp: DateTime(2026, 10, 15, 12),
        );
        cubit.selectRecord(record);
      },
      expect: () => [
        isA<HistoryState>().having(
          (s) => s.selectedRecord?.id,
          'selectedRecord.id',
          'rec_1',
        ),
      ],
    );

    blocTest<HistoryCubit, HistoryState>(
      'selectRecord with null clears selectedRecord',
      build: () => HistoryCubit(collarId: 'collar_123', initialDate: testDate),
      act: (cubit) => cubit.selectRecord(null),
      expect: () => [
        isA<HistoryState>().having(
          (s) => s.selectedRecord,
          'selectedRecord',
          isNull,
        ),
      ],
    );
  });
}
