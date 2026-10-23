import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/history/widgets/history_record_carousel.dart';

import '../../helpers/helpers.dart';

void main() {
  group('HistoryRecordCarousel', () {
    final record1 = HistoryRecord(
      id: 'rec-1',
      coords: const CollarCoords(altM: 100, lat: -12.04, lon: -77.04),
      radio: const CollarRadio(
        distanceHomeM: 10,
        packetsLostGap: 1,
        rssi: -70,
        snr: 9,
      ),
      seq: 1,
      status: const CollarStatus(
        batteryPct: 90,
        batteryV: 4.15,
        gpsFix: true,
        sats: 8,
      ),
      expireAt: DateTime(2026, 10, 23),
      timestamp: DateTime(2026, 10, 22, 10),
    );

    final record2 = HistoryRecord(
      id: 'rec-2',
      coords: const CollarCoords(altM: 105, lat: -12.05, lon: -77.05),
      radio: const CollarRadio(
        distanceHomeM: 20,
        packetsLostGap: 0,
        rssi: -75,
        snr: 8,
      ),
      seq: 2,
      status: const CollarStatus(
        batteryPct: 88,
        batteryV: 4.10,
        gpsFix: true,
        sats: 6,
      ),
      expireAt: DateTime(2026, 10, 23),
      timestamp: DateTime(2026, 10, 22, 10, 5),
    );

    testWidgets('renders empty shrink widget when records list is empty', (
      tester,
    ) async {
      await tester.pumpApp(
        Scaffold(
          body: HistoryRecordCarousel(
            records: const [],
            onClose: () {},
            onRecordSelected: (_) {},
          ),
        ),
      );

      expect(find.byType(PageView), findsNothing);
    });

    testWidgets('renders page view and handles close and selection', (
      tester,
    ) async {
      var closed = false;
      HistoryRecord? selected;

      await tester.pumpApp(
        Scaffold(
          body: SizedBox(
            height: 140,
            child: HistoryRecordCarousel(
              records: [record1, record2],
              selectedRecord: record1,
              onClose: () => closed = true,
              onRecordSelected: (rec) => selected = rec,
            ),
          ),
        ),
      );

      expect(find.byType(PageView), findsOneWidget);
      expect(find.textContaining('1'), findsWidgets);

      // Close button
      await tester.tap(find.byType(InkWell).first);
      expect(closed, isTrue);

      // Swipe to next record
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(selected, record2);
    });

    testWidgets('animates to newly selected record when updated', (
      tester,
    ) async {
      HistoryRecord? currentSelected = record1;
      late StateSetter setStateCallback;

      await tester.pumpApp(
        Scaffold(
          body: SizedBox(
            height: 140,
            child: StatefulBuilder(
              builder: (context, setState) {
                setStateCallback = setState;
                return HistoryRecordCarousel(
                  records: [record1, record2],
                  selectedRecord: currentSelected,
                  onClose: () {},
                  onRecordSelected: (_) {},
                );
              },
            ),
          ),
        ),
      );

      expect(find.textContaining('1'), findsWidgets);

      setStateCallback(() {
        currentSelected = record2;
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('2'), findsWidgets);
    });
  });
}
