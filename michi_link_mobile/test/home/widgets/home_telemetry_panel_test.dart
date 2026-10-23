import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/home/widgets/collar_config_bottom_sheet.dart';
import 'package:michi_link_mobile/home/widgets/home_telemetry_panel.dart';

import '../../helpers/helpers.dart';

void main() {
  group('HomeTelemetryPanel', () {
    final collar = CollarModel(
      deviceId: 'COLLAR_TEST_1',
      name: 'Michi Test',
      breed: CatBreed.europeanOrangeWhite,
      isOnline: true,
      hasActiveAlert: false,
      packetLossPct: 0,
      packetsLost: 0,
      packetsReceived: 100,
      lastSeen: DateTime(2026, 10, 22, 12),
      config: const CollarConfig(
        maxDistanceM: 100,
        minBatteryPct: 20,
        requireGpsFix: false,
        notifLanguage: 'es',
      ),
      coords: const CollarCoords(lat: -12.0463, lon: -77.0427, altM: 100),
      baseCoords: const CollarCoords(lat: -12.0460, lon: -77.0420, altM: 100),
      radio: const CollarRadio(
        distanceHomeM: 35.5,
        packetsLostGap: 0,
        rssi: -70,
        snr: 9.5,
      ),
      status: const CollarStatus(
        batteryPct: 85,
        batteryV: 4.12,
        gpsFix: true,
        sats: 8,
      ),
      seq: 10,
    );

    setUpAll(() {
      setupServiceLocator(Environment.mock);
    });

    testWidgets('renders telemetry metrics and opens config modal', (
      tester,
    ) async {
      await tester.pumpApp(Scaffold(body: HomeTelemetryPanel(collar: collar)));

      expect(find.byType(HomeTelemetryPanel), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
      expect(find.text('Configurar'), findsOneWidget);

      await tester.tap(find.text('Configurar'));
      await tester.pumpAndSettle();

      expect(find.byType(CollarConfigBottomSheet), findsOneWidget);
    });
  });
}
