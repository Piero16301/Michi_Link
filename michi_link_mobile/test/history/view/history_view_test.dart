import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/history/history.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/helpers.dart';

class MockHistoryCubit extends MockCubit<HistoryState>
    implements HistoryCubit {}

void main() {
  group('HistoryView', () {
    late MockHistoryCubit historyCubit;

    setUpAll(() {
      setupServiceLocator(Environment.mock);
    });

    setUp(() {
      historyCubit = MockHistoryCubit();
      when(() => historyCubit.state).thenReturn(
        HistoryState(
          collarId: 'COLLAR_1',
          selectedDate: DateTime(2026, 10, 22),
        ),
      );
      when(() => historyCubit.stream).thenAnswer(
        (_) => Stream.value(
          HistoryState(
            collarId: 'COLLAR_1',
            selectedDate: DateTime(2026, 10, 22),
          ),
        ),
      );
    });

    testWidgets('renders HistoryView with map, summary badge and filter card', (
      tester,
    ) async {
      await tester.pumpApp(
        BlocProvider<HistoryCubit>.value(
          value: historyCubit,
          child: const HistoryView(collarId: 'COLLAR_1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HistoryView), findsOneWidget);
      expect(find.byType(HistoryMapView), findsOneWidget);
      expect(find.byType(HistoryFilterCard), findsOneWidget);
      expect(find.byType(RouteSummaryFloatingBadge), findsOneWidget);

      await tester.tap(find.byType(RouteSummaryFloatingBadge));
      verify(() => historyCubit.selectRecord(any())).called(1);
    });

    testWidgets(
      'renders HistoryRecordCarousel when selectedRecord is present',
      (tester) async {
        final selected = HistoryRecord(
          id: '1',
          coords: const CollarCoords(lat: 40.6892, lon: -74.0445, altM: 0),
          timestamp: DateTime(2026, 10, 22, 10),
          radio: const CollarRadio(
            distanceHomeM: 10,
            packetsLostGap: 0,
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
          expireAt: DateTime(2026, 10, 23),
        );

        when(() => historyCubit.state).thenReturn(
          HistoryState(
            collarId: 'COLLAR_1',
            selectedDate: DateTime(2026, 10, 22),
            selectedRecord: selected,
          ),
        );
        when(() => historyCubit.stream).thenAnswer(
          (_) => Stream.value(
            HistoryState(
              collarId: 'COLLAR_1',
              selectedDate: DateTime(2026, 10, 22),
              selectedRecord: selected,
            ),
          ),
        );

        await tester.pumpApp(
          BlocProvider<HistoryCubit>.value(
            value: historyCubit,
            child: const HistoryView(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(HistoryRecordCarousel), findsOneWidget);
      },
    );
  });
}
