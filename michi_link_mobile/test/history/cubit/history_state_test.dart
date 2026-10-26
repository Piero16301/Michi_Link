import 'package:flutter_test/flutter_test.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/history/history.dart';

void main() {
  group('HistoryState', () {
    test('supports value equality', () {
      expect(const HistoryState(), equals(const HistoryState()));
    });

    test('calculates effectiveDate, startDateTime and endDateTime', () {
      final date = DateTime(2026, 5, 10);
      final state = HistoryState(
        selectedDate: date,
        startHour: 8.5, // 08:30
        endHour: 18.25, // 18:15
      );

      expect(state.effectiveDate, date);
      expect(state.startDateTime, DateTime(2026, 5, 10, 8, 30));
      expect(state.endDateTime.hour, 18);
      expect(state.endDateTime.minute, 15);
    });

    test('endDateTime handles hour >= 24', () {
      final date = DateTime(2026, 5, 10);
      final state = HistoryState(selectedDate: date);

      expect(state.endDateTime, DateTime(2026, 5, 10, 23, 59, 59, 999));
    });

    test(
      'copyWith updates fields and clears selectedRecord when closure returns '
      'null',
      () {
        final record = HistoryRecord.fromJson(const {
          'id': 'rec_1',
          'coords': {'lat': 0, 'lon': 0, 'alt_m': 0},
        });

        final state = HistoryState(
          deviceId: 'COLLAR_1',
          selectedRecord: record,
        );

        final updated = state.copyWith(
          deviceId: 'COLLAR_2',
          selectedRecord: () => null,
        );

        expect(updated.deviceId, 'COLLAR_2');
        expect(updated.selectedRecord, isNull);
      },
    );

    test(
      'copyWith retains current selectedRecord when selectedRecord callback is '
      'not provided',
      () {
        final record = HistoryRecord.fromJson(const {
          'id': 'rec_1',
          'coords': {'lat': 0, 'lon': 0, 'alt_m': 0},
        });
        final state = HistoryState(
          deviceId: 'COLLAR_1',
          selectedRecord: record,
        );

        final updated = state.copyWith(
          deviceId: 'COLLAR_2',
          selectedDate: DateTime(2026, 6),
          startHour: 10,
          endHour: 20,
        );

        expect(updated.deviceId, 'COLLAR_2');
        expect(updated.selectedDate, DateTime(2026, 6));
        expect(updated.startHour, 10);
        expect(updated.endHour, 20);
        expect(updated.selectedRecord, record);
      },
    );

    test('effectiveDate defaults to today when selectedDate is null', () {
      const state = HistoryState();
      final now = DateTime.now();

      expect(state.effectiveDate.year, now.year);
      expect(state.effectiveDate.month, now.month);
      expect(state.effectiveDate.day, now.day);
    });

    test('props contains all relevant fields', () {
      final state = HistoryState(
        deviceId: 'COLLAR_1',
        selectedDate: DateTime(2026),
        startHour: 5,
        endHour: 10,
      );

      expect(
        state.props,
        equals(['COLLAR_1', DateTime(2026), 5.0, 10.0, null]),
      );
    });
  });
}
