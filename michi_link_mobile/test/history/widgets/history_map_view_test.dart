import 'package:expressive_kit/expressive_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/history/widgets/history_map_view.dart';

import '../../helpers/helpers.dart';

void main() {
  group('HistoryMapView', () {
    final record1 = HistoryRecord(
      id: 'rec-1',
      coords: const CollarCoords(altM: 100, lat: -12.04, lon: -77.04),
      radio: const CollarRadio(
        distanceHomeM: 10,
        packetsLostGap: 0,
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

    testWidgets('renders GoogleMap and empty state badge when records empty', (
      tester,
    ) async {
      await tester.pumpApp(const HistoryMapView(records: []));

      expect(find.byType(GoogleMap), findsOneWidget);
      expect(find.text('Sin registros de historial'), findsOneWidget);
    });

    testWidgets('renders map controls and handles taps', (tester) async {
      await tester.pumpApp(
        HistoryMapView(records: [record1, record2], selectedRecord: record1),
      );

      expect(find.byType(GoogleMap), findsOneWidget);
      expect(find.text('Sin registros de historial'), findsNothing);

      // Buttons for zoom in, zoom out, fit route
      final buttons = find.byType(ExpressiveIconButton);
      expect(buttons, findsWidgets);

      for (var i = 0; i < buttons.evaluate().length; i++) {
        await tester.tap(buttons.at(i));
        await tester.pump();
      }
    });

    testWidgets('updates when new selectedRecord is passed', (tester) async {
      await tester.pumpApp(
        HistoryMapView(records: [record1, record2], selectedRecord: record1),
      );

      await tester.pumpApp(
        HistoryMapView(records: [record1, record2], selectedRecord: record2),
      );
      await tester.pump();

      expect(find.byType(GoogleMap), findsOneWidget);
    });
  });
}
