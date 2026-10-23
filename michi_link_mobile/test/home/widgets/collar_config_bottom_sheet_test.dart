import 'package:expressive_kit/expressive_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/home/widgets/collar_config_bottom_sheet.dart';

import '../../helpers/helpers.dart';

void main() {
  group('CollarConfigBottomSheet', () {
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

    testWidgets('renders configuration options and handles save', (
      tester,
    ) async {
      await tester.pumpApp(
        Scaffold(
          body: SizedBox(
            height: 800,
            child: Builder(
              builder: (context) => CollarConfigBottomSheet(
                parentContext: context,
                collar: collar,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CollarConfigBottomSheet), findsOneWidget);
      expect(find.textContaining('Michi Test'), findsOneWidget);
      expect(find.text('Guardar configuración'), findsOneWidget);

      await tester.ensureVisible(find.text('Guardar configuración'));
      await tester.tap(find.text('Guardar configuración'));
      await tester.pumpAndSettle();
    });

    testWidgets('toggles require GPS fix switch', (tester) async {
      await tester.pumpApp(
        Scaffold(
          body: SizedBox(
            height: 800,
            child: Builder(
              builder: (context) => CollarConfigBottomSheet(
                parentContext: context,
                collar: collar,
              ),
            ),
          ),
        ),
      );

      final switchFinder = find.byType(ExpressiveSwitch);
      expect(switchFinder, findsOneWidget);

      await tester.ensureVisible(switchFinder);
      await tester.tap(switchFinder);
      await tester.pump();
    });

    testWidgets('renders disconnected status when collar is offline', (
      tester,
    ) async {
      final offlineCollar = CollarModel(
        deviceId: 'COLLAR_TEST_2',
        name: 'Michi Offline',
        breed: CatBreed.siamese,
        isOnline: false,
        hasActiveAlert: false,
        packetLossPct: 100,
        packetsLost: 10,
        packetsReceived: 0,
        lastSeen: DateTime(2026, 10, 22, 10),
        config: const CollarConfig(
          maxDistanceM: 50,
          minBatteryPct: 10,
          requireGpsFix: true,
          notifLanguage: 'en',
        ),
        coords: const CollarCoords(lat: 0, lon: 0, altM: 0),
        baseCoords: const CollarCoords(lat: 0, lon: 0, altM: 0),
        radio: const CollarRadio(
          distanceHomeM: 0,
          packetsLostGap: 0,
          rssi: 0,
          snr: 0,
        ),
        status: const CollarStatus(
          batteryPct: 10,
          batteryV: 3.5,
          gpsFix: false,
          sats: 0,
        ),
        seq: 1,
      );

      await tester.pumpApp(
        Scaffold(
          body: SizedBox(
            height: 800,
            child: Builder(
              builder: (context) => CollarConfigBottomSheet(
                parentContext: context,
                collar: offlineCollar,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Desconectado'), findsOneWidget);
    });

    testWidgets('handles cancel button press', (tester) async {
      await tester.pumpApp(
        Scaffold(
          body: SizedBox(
            height: 800,
            child: Builder(
              builder: (context) => CollarConfigBottomSheet(
                parentContext: context,
                collar: collar,
              ),
            ),
          ),
        ),
      );

      final cancelFinder = find.text('Cancelar');
      expect(cancelFinder, findsOneWidget);

      await tester.ensureVisible(cancelFinder);
      await tester.tap(cancelFinder);
      await tester.pumpAndSettle();
    });

    testWidgets('updates sliders for maxDistance and minBatteryPct', (
      tester,
    ) async {
      await tester.pumpApp(
        Scaffold(
          body: SizedBox(
            height: 800,
            child: Builder(
              builder: (context) => CollarConfigBottomSheet(
                parentContext: context,
                collar: collar,
              ),
            ),
          ),
        ),
      );

      final sliders = find.byType(ExpressiveSlider);
      expect(sliders, findsNWidgets(2));

      final slider1 = tester.widget<ExpressiveSlider>(sliders.at(0));
      slider1.onChanged?.call(250);

      final slider2 = tester.widget<ExpressiveSlider>(sliders.at(1));
      slider2.onChanged?.call(15);

      await tester.pump();
      expect(find.text('250 m'), findsOneWidget);
      expect(find.text('15%'), findsOneWidget);
    });

    testWidgets('opens language modal and selects another language', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpApp(
        Scaffold(
          body: SizedBox(
            height: 1000,
            child: Builder(
              builder: (context) => CollarConfigBottomSheet(
                parentContext: context,
                collar: collar,
              ),
            ),
          ),
        ),
      );

      // Tap on the language selector ink well
      final languageSelector = find.byWidgetPredicate(
        (widget) =>
            widget is InkWell &&
            widget.borderRadius == BorderRadius.circular(16),
      );
      expect(languageSelector, findsOneWidget);

      await tester.ensureVisible(languageSelector);
      await tester.tap(languageSelector);
      await tester.pumpAndSettle();

      expect(find.text('Seleccionar idioma'), findsOneWidget);

      // Tap the first available language ListTile in the modal
      final listTiles = find.byType(ListTile);
      expect(listTiles, findsWidgets);

      await tester.tap(listTiles.first);
      await tester.pumpAndSettle();

      // Modal closed and language updated
      expect(find.text('Seleccionar idioma'), findsNothing);
    });
  });
}
