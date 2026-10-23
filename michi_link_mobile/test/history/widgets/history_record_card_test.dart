import 'package:flutter_test/flutter_test.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/history/history.dart';

import '../../helpers/helpers.dart';

void main() {
  group('HistoryRecordCard', () {
    final recordFixed = HistoryRecord(
      id: 'rec-1',
      coords: const CollarCoords(altM: 120.5, lat: -12.046374, lon: -77.042793),
      radio: const CollarRadio(
        distanceHomeM: 25.4,
        packetsLostGap: 2,
        rssi: -75,
        snr: 8.5,
      ),
      seq: 42,
      status: const CollarStatus(
        batteryPct: 88,
        batteryV: 4.12,
        gpsFix: true,
        sats: 8,
      ),
      expireAt: DateTime(2026, 10, 23),
      timestamp: DateTime(2026, 10, 22, 14, 30, 45),
    );

    final recordNoFix = HistoryRecord(
      id: 'rec-2',
      coords: const CollarCoords(altM: 0, lat: 0, lon: 0),
      radio: const CollarRadio(
        distanceHomeM: 0,
        packetsLostGap: 0,
        rssi: -90,
        snr: 2.1,
      ),
      seq: 43,
      status: const CollarStatus(
        batteryPct: 20,
        batteryV: 3.65,
        gpsFix: false,
        sats: 0,
      ),
      expireAt: DateTime(2026, 10, 23),
      timestamp: DateTime(2026, 10, 22, 14, 31),
    );

    testWidgets('renders record information correctly when gps is fixed', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpApp(
        HistoryRecordCard(
          record: recordFixed,
          isSelected: true,
          onTap: () => tapped = true,
        ),
      );

      expect(find.byType(HistoryRecordCard), findsOneWidget);
      expect(find.textContaining('Paquete #42'), findsOneWidget);
      expect(find.text('14:30:45'), findsOneWidget);

      await tester.tap(find.byType(HistoryRecordCard));
      expect(tapped, isTrue);
    });

    testWidgets('renders correctly when gps has no fix and unselected', (
      tester,
    ) async {
      await tester.pumpApp(HistoryRecordCard(record: recordNoFix));

      expect(find.byType(HistoryRecordCard), findsOneWidget);
      expect(find.textContaining('Paquete #43'), findsOneWidget);
      expect(find.text('14:31:00'), findsOneWidget);
    });
  });
}
