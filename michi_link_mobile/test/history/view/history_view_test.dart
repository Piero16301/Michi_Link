import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:expressive_kit/expressive_kit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/history/history.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shimmer/shimmer.dart';

import '../../helpers/helpers.dart';

class MockGoRouter extends Mock implements GoRouter {}

class MockHistoryCubit extends MockCubit<HistoryState>
    implements HistoryCubit {}

class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  group('HistoryView', () {
    late MockHistoryCubit historyCubit;
    late MockDatabaseService databaseService;
    late StreamController<List<HistoryRecord>> historyStreamController;

    final sampleRecord1 = HistoryRecord(
      id: '1',
      coords: const CollarCoords(lat: 40.6892, lon: -74.0445, altM: 10),
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

    final sampleRecord2 = HistoryRecord(
      id: '2',
      coords: const CollarCoords(lat: 40.6900, lon: -74.0450, altM: 12),
      timestamp: DateTime(2026, 10, 22, 11),
      radio: const CollarRadio(
        distanceHomeM: 15,
        packetsLostGap: 0,
        rssi: 12,
        snr: 11,
      ),
      seq: 11,
      status: const CollarStatus(
        batteryPct: 38,
        batteryV: 3.65,
        gpsFix: true,
        sats: 9,
      ),
      expireAt: DateTime(2026, 10, 23),
    );

    setUp(() async {
      historyCubit = MockHistoryCubit();
      databaseService = MockDatabaseService();
      historyStreamController =
          StreamController<List<HistoryRecord>>.broadcast();

      when(() => historyCubit.state).thenReturn(
        HistoryState(
          deviceId: 'COLLAR_1',
          selectedDate: DateTime(2026, 10, 22),
        ),
      );
      when(() => historyCubit.stream).thenAnswer(
        (_) => Stream.value(
          HistoryState(
            deviceId: 'COLLAR_1',
            selectedDate: DateTime(2026, 10, 22),
          ),
        ),
      );

      when(
        () => databaseService.getHistoryRecordsStream(
          deviceId: any(named: 'deviceId'),
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      ).thenAnswer((_) => historyStreamController.stream);

      if (getIt.isRegistered<DatabaseService>()) {
        await getIt.unregister<DatabaseService>();
      }
      getIt.registerSingleton<DatabaseService>(databaseService);
    });

    tearDown(() async {
      await historyStreamController.close();
      if (getIt.isRegistered<DatabaseService>()) {
        await getIt.unregister<DatabaseService>();
      }
    });

    tearDownAll(() {
      setupServiceLocator(Environment.mock);
    });

    testWidgets('renders HistoryView with map, summary badge and filter card', (
      tester,
    ) async {
      await tester.pumpApp(
        BlocProvider<HistoryCubit>.value(
          value: historyCubit,
          child: const HistoryView(deviceId: 'COLLAR_1'),
        ),
      );

      historyStreamController.add([sampleRecord1, sampleRecord2]);
      await tester.pumpAndSettle();

      expect(find.byType(HistoryView), findsOneWidget);
      expect(find.byType(HistoryMapView), findsOneWidget);
      expect(find.byType(HistoryFilterCard), findsOneWidget);
      expect(find.byType(RouteSummaryFloatingBadge), findsOneWidget);

      await tester.tap(find.byType(RouteSummaryFloatingBadge));
      verify(() => historyCubit.selectRecord(any())).called(1);
    });

    testWidgets(
      'renders HistoryRecordCarousel when selectedRecord is present and '
      'handles close',
      (tester) async {
        when(() => historyCubit.state).thenReturn(
          HistoryState(
            deviceId: 'COLLAR_1',
            selectedDate: DateTime(2026, 10, 22),
            selectedRecord: sampleRecord1,
          ),
        );
        when(() => historyCubit.stream).thenAnswer(
          (_) => Stream.value(
            HistoryState(
              deviceId: 'COLLAR_1',
              selectedDate: DateTime(2026, 10, 22),
              selectedRecord: sampleRecord1,
            ),
          ),
        );

        await tester.pumpApp(
          BlocProvider<HistoryCubit>.value(
            value: historyCubit,
            child: const HistoryView(),
          ),
        );

        historyStreamController.add([sampleRecord1, sampleRecord2]);
        await tester.pumpAndSettle();

        expect(find.byType(HistoryRecordCarousel), findsOneWidget);

        // Tap close button in carousel
        final closeButton = find.descendant(
          of: find.byType(HistoryRecordCarousel),
          matching: find.byType(InkWell),
        );
        await tester.tap(closeButton.first);
        verify(() => historyCubit.selectRecord(null)).called(1);
      },
    );

    testWidgets('renders loading shimmer state in light mode', (tester) async {
      await tester.pumpApp(
        BlocProvider<HistoryCubit>.value(
          value: historyCubit,
          child: const HistoryView(deviceId: 'COLLAR_1'),
        ),
      );
      await tester.pump();

      expect(find.byType(Shimmer), findsOneWidget);
      expect(find.byType(HugeIcon), findsWidgets);
    });

    testWidgets('renders loading shimmer state in dark mode', (tester) async {
      await tester.pumpApp(
        Theme(
          data: ThemeData.dark(),
          child: BlocProvider<HistoryCubit>.value(
            value: historyCubit,
            child: const HistoryView(deviceId: 'COLLAR_1'),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Shimmer), findsOneWidget);
    });

    testWidgets('renders error view when stream emits an error', (
      tester,
    ) async {
      await tester.pumpApp(
        BlocProvider<HistoryCubit>.value(
          value: historyCubit,
          child: const HistoryView(deviceId: 'COLLAR_1'),
        ),
      );

      historyStreamController.addError(Exception('Firestore error'));
      await tester.pumpAndSettle();

      expect(find.byType(HistoryMapView), findsNothing);
      expect(find.text('Desconectado'), findsOneWidget);
      expect(find.byType(HugeIcon), findsWidgets);
    });

    testWidgets('handles back button tap', (tester) async {
      final goRouter = MockGoRouter();
      when(goRouter.pop).thenReturn(null);

      await tester.pumpApp(
        InheritedGoRouter(
          goRouter: goRouter,
          child: BlocProvider<HistoryCubit>.value(
            value: historyCubit,
            child: const HistoryView(deviceId: 'COLLAR_1'),
          ),
        ),
      );
      historyStreamController.add([sampleRecord1]);
      await tester.pumpAndSettle();

      final backButton = find.descendant(
        of: find.byType(ExpressiveTopAppBar),
        matching: find.byType(ExpressiveIconButton),
      );
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      verify(goRouter.pop).called(1);
    });

    testWidgets(
      'does not render badge or carousel when validRecords is empty',
      (tester) async {
        final zeroCoordsRecord = HistoryRecord(
          id: 'zero',
          coords: const CollarCoords(lat: 0, lon: 0, altM: 0),
          timestamp: DateTime(2026, 10, 22, 10),
          radio: const CollarRadio(
            distanceHomeM: 0,
            packetsLostGap: 0,
            rssi: 0,
            snr: 0,
          ),
          seq: 0,
          status: const CollarStatus(
            batteryPct: 50,
            batteryV: 3.8,
            gpsFix: false,
            sats: 0,
          ),
          expireAt: DateTime(2026, 10, 23),
        );

        await tester.pumpApp(
          BlocProvider<HistoryCubit>.value(
            value: historyCubit,
            child: const HistoryView(deviceId: 'COLLAR_1'),
          ),
        );

        historyStreamController.add([zeroCoordsRecord]);
        await tester.pumpAndSettle();

        expect(find.byType(RouteSummaryFloatingBadge), findsNothing);
        expect(find.byType(HistoryRecordCarousel), findsNothing);
      },
    );

    testWidgets('delegates onRecordSelected from HistoryMapView to cubit', (
      tester,
    ) async {
      await tester.pumpApp(
        BlocProvider<HistoryCubit>.value(
          value: historyCubit,
          child: const HistoryView(deviceId: 'COLLAR_1'),
        ),
      );

      historyStreamController.add([sampleRecord1]);
      await tester.pumpAndSettle();

      final mapWidget = tester.widget<HistoryMapView>(
        find.byType(HistoryMapView),
      );
      mapWidget.onRecordSelected?.call(sampleRecord1);

      verify(() => historyCubit.selectRecord(sampleRecord1)).called(1);
    });

    testWidgets('delegates filter card actions to cubit', (tester) async {
      await tester.pumpApp(
        BlocProvider<HistoryCubit>.value(
          value: historyCubit,
          child: const HistoryView(deviceId: 'COLLAR_1'),
        ),
      );

      historyStreamController.add([sampleRecord1]);
      await tester.pumpAndSettle();

      final filterCard = tester.widget<HistoryFilterCard>(
        find.byType(HistoryFilterCard),
      );

      filterCard.onPreviousDate();
      verify(() => historyCubit.previousDay()).called(1);

      filterCard.onNextDate();
      verify(() => historyCubit.nextDay()).called(1);

      filterCard.onDateSelected(DateTime(2026, 10, 20));
      verify(() => historyCubit.selectDate(DateTime(2026, 10, 20))).called(1);

      filterCard.onTimeRangeChanged(8, 20);
      verify(() => historyCubit.changeTimeRange(8, 20)).called(1);
    });
  });
}
