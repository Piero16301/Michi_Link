import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/history/widgets/history_selected_record_card.dart';

import '../../helpers/helpers.dart';

void main() {
  group('RouteSummaryFloatingBadge', () {
    testWidgets('renders count and time span when provided', (tester) async {
      var tapped = false;
      final start = DateTime(2026, 10, 22, 10);
      final end = DateTime(2026, 10, 22, 12, 30);

      await tester.pumpApp(
        Scaffold(
          body: RouteSummaryFloatingBadge(
            count: 25,
            startTime: start,
            endTime: end,
            onTap: () => tapped = true,
          ),
        ),
      );

      expect(find.byType(RouteSummaryFloatingBadge), findsOneWidget);
      expect(find.text('•  10:00 - 12:30'), findsOneWidget);

      await tester.tap(find.byType(RouteSummaryFloatingBadge));
      expect(tapped, isTrue);
    });

    testWidgets('renders count without time span when times are null', (
      tester,
    ) async {
      await tester.pumpApp(
        const Scaffold(body: RouteSummaryFloatingBadge(count: 5)),
      );

      expect(find.byType(RouteSummaryFloatingBadge), findsOneWidget);
      expect(find.text('•  10:00 - 12:30'), findsNothing);
    });
  });

  group('SelectedRecordFloatingCard', () {
    final recordFixed = HistoryRecord(
      id: 'rec-1',
      coords: const CollarCoords(altM: 120.5, lat: -12.046374, lon: -77.042793),
      radio: const CollarRadio(
        distanceHomeM: 25.4,
        packetsLostGap: 3,
        rssi: -75,
        snr: 8.5,
      ),
      seq: 101,
      status: const CollarStatus(
        batteryPct: 85,
        batteryV: 4.10,
        gpsFix: true,
        sats: 7,
      ),
      expireAt: DateTime(2026, 10, 23),
      timestamp: DateTime(2026, 10, 22, 15),
    );

    final recordNoFix = HistoryRecord(
      id: 'rec-2',
      coords: const CollarCoords(altM: 0, lat: 0, lon: 0),
      radio: const CollarRadio(
        distanceHomeM: 0,
        packetsLostGap: 0,
        rssi: -90,
        snr: 2,
      ),
      seq: 102,
      status: const CollarStatus(
        batteryPct: 15,
        batteryV: 3.5,
        gpsFix: false,
        sats: 0,
      ),
      expireAt: DateTime(2026, 10, 23),
      timestamp: DateTime(2026, 10, 22, 15, 5),
    );

    testWidgets('renders telemetry and triggers onClose', (tester) async {
      var closed = false;
      await tester.pumpApp(
        Scaffold(
          body: SelectedRecordFloatingCard(
            record: recordFixed,
            onClose: () => closed = true,
          ),
        ),
      );

      expect(find.byType(SelectedRecordFloatingCard), findsOneWidget);
      expect(find.textContaining('101'), findsOneWidget);
      expect(find.textContaining('15:00:00'), findsOneWidget);

      await tester.tap(find.byType(InkWell));
      expect(closed, isTrue);
    });

    testWidgets('renders correctly with no gps fix and zero packet loss', (
      tester,
    ) async {
      await tester.pumpApp(
        Scaffold(
          body: SelectedRecordFloatingCard(record: recordNoFix, onClose: () {}),
        ),
      );

      expect(find.byType(SelectedRecordFloatingCard), findsOneWidget);
      expect(find.textContaining('102'), findsOneWidget);
    });
  });
}
