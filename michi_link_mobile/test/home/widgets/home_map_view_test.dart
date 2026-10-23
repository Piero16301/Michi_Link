import 'package:expressive_kit/expressive_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/home/widgets/home_map_view.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../../helpers/helpers.dart';

class MockGoogleMapController extends Mock implements GoogleMapController {}

class FakeCameraUpdate extends Fake implements CameraUpdate {}

class MockGeolocatorPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements GeolocatorPlatform {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeCameraUpdate());
    registerFallbackValue(const LatLng(0, 0));
  });

  group('HomeMapView', () {
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

    testWidgets('renders GoogleMap and floating action buttons', (
      tester,
    ) async {
      await tester.pumpApp(Scaffold(body: HomeMapView(collar: collar)));

      expect(find.byType(HomeMapView), findsOneWidget);
      expect(find.byType(GoogleMap), findsOneWidget);

      final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      for (final marker in googleMap.markers) {
        marker.onTap?.call();
      }
      await tester.pump();
    });

    testWidgets('handles widget updates with new coordinates', (tester) async {
      final updatedCollar = CollarModel(
        deviceId: 'COLLAR_TEST_1',
        name: 'Michi Test 2',
        breed: CatBreed.siamese,
        isOnline: true,
        hasActiveAlert: false,
        packetLossPct: 0,
        packetsLost: 0,
        packetsReceived: 101,
        lastSeen: DateTime(2026, 10, 22, 12, 1),
        config: const CollarConfig(
          maxDistanceM: 100,
          minBatteryPct: 20,
          requireGpsFix: false,
          notifLanguage: 'es',
        ),
        coords: const CollarCoords(lat: -12.0480, lon: -77.0450, altM: 102),
        baseCoords: const CollarCoords(lat: -12.0460, lon: -77.0420, altM: 100),
        radio: const CollarRadio(
          distanceHomeM: 55,
          packetsLostGap: 0,
          rssi: -78,
          snr: 7.5,
        ),
        status: const CollarStatus(
          batteryPct: 84,
          batteryV: 4.10,
          gpsFix: true,
          sats: 9,
        ),
        seq: 11,
      );

      await tester.pumpApp(Scaffold(body: HomeMapView(collar: collar)));

      await tester.pumpApp(Scaffold(body: HomeMapView(collar: updatedCollar)));
      await tester.pump();

      expect(find.byType(GoogleMap), findsOneWidget);
    });

    testWidgets('handles onMapCreated, camera movement, and controls', (
      tester,
    ) async {
      final controller = MockGoogleMapController();
      when(() => controller.animateCamera(any())).thenAnswer((_) async {});
      when(() => controller.moveCamera(any())).thenAnswer((_) async {});
      when(
        () => controller.getScreenCoordinate(any()),
      ).thenAnswer((_) async => const ScreenCoordinate(x: 150, y: 250));

      await tester.pumpApp(Scaffold(body: HomeMapView(collar: collar)));

      final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));

      // Trigger map created
      googleMap.onMapCreated?.call(controller);
      await tester.pump();

      // Trigger camera move
      googleMap.onCameraMove?.call(
        const CameraPosition(
          target: LatLng(-12.0460, -77.0420),
          zoom: 17,
          bearing: 45,
        ),
      );
      await tester.pump();

      // Tap all action buttons with map controller attached
      final buttons = find.byType(ExpressiveIconButton);
      for (var i = 0; i < buttons.evaluate().length; i++) {
        await tester.tap(buttons.at(i));
        await tester.pump();
      }
    });

    testWidgets('handles marker taps and callout bubbles', (tester) async {
      final controller = MockGoogleMapController();
      when(() => controller.animateCamera(any())).thenAnswer((_) async {});
      when(() => controller.moveCamera(any())).thenAnswer((_) async {});
      when(
        () => controller.getScreenCoordinate(any()),
      ).thenAnswer((_) async => const ScreenCoordinate(x: 150, y: 250));

      await tester.pumpApp(Scaffold(body: HomeMapView(collar: collar)));

      final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      googleMap.onMapCreated?.call(controller);
      await tester.pumpAndSettle();

      // Tap base station marker
      final baseMarker = googleMap.markers.firstWhere(
        (m) => m.markerId.value == 'base_station',
      );
      baseMarker.onTap?.call();
      await tester.pumpAndSettle();

      expect(find.text('Mi ubicación'), findsOneWidget);

      // Trigger camera move while marker is selected
      googleMap.onCameraMove?.call(
        const CameraPosition(target: LatLng(-12.0460, -77.0420), zoom: 16),
      );
      await tester.pumpAndSettle();

      // Tap callout bubble directly to dismiss it
      await tester.tap(find.text('Mi ubicación'));
      await tester.pumpAndSettle();
      expect(find.text('Mi ubicación'), findsNothing);

      // Tap map to dismiss callout
      baseMarker.onTap?.call();
      await tester.pumpAndSettle();
      expect(find.text('Mi ubicación'), findsOneWidget);
      googleMap.onTap?.call(const LatLng(-12.0460, -77.0420));
      await tester.pumpAndSettle();
      expect(find.text('Mi ubicación'), findsNothing);

      // Tap cat location marker
      final catMarker = googleMap.markers.firstWhere(
        (m) => m.markerId.value == 'cat_location',
      );
      catMarker.onTap?.call();
      await tester.pumpAndSettle();

      expect(find.text('Michi Test'), findsOneWidget);

      // Trigger camera move while cat marker is selected
      googleMap.onCameraMove?.call(
        const CameraPosition(target: LatLng(-12.0463, -77.0427), zoom: 16),
      );
      await tester.pumpAndSettle();

      // Tap same marker again to toggle off
      catMarker.onTap?.call();
      await tester.pumpAndSettle();
      expect(find.text('Michi Test'), findsNothing);
    });

    testWidgets('renders dark mode map style and zero-coordinates collar', (
      tester,
    ) async {
      final zeroCollar = CollarModel(
        deviceId: 'COLLAR_ZERO',
        name: 'Zero Michi',
        breed: CatBreed.siamese,
        isOnline: false,
        hasActiveAlert: false,
        packetLossPct: 0,
        packetsLost: 0,
        packetsReceived: 0,
        lastSeen: DateTime(2026, 10, 22),
        config: const CollarConfig(
          maxDistanceM: 0,
          minBatteryPct: 10,
          requireGpsFix: false,
          notifLanguage: 'es',
        ),
        coords: const CollarCoords(lat: 0, lon: 0, altM: 0),
        baseCoords: const CollarCoords(lat: -12, lon: -77, altM: 0),
        radio: const CollarRadio(
          distanceHomeM: 0,
          packetsLostGap: 0,
          rssi: 0,
          snr: 0,
        ),
        status: const CollarStatus(
          batteryPct: 50,
          batteryV: 3.8,
          gpsFix: false,
          sats: 0,
        ),
        seq: 0,
      );

      await tester.pumpApp(
        Theme(
          data: ThemeData.dark(),
          child: Scaffold(body: HomeMapView(collar: zeroCollar)),
        ),
      );

      final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
      expect(map.style, equals(AppMapStyles.darkM3));
      expect(map.circles, isEmpty);
      expect(
        map.markers.any((m) => m.markerId.value == 'cat_location'),
        isFalse,
      );
    });

    testWidgets('shows snackbar when location service is disabled', (
      tester,
    ) async {
      final mockGeolocator = MockGeolocatorPlatform();
      final originalPlatform = GeolocatorPlatform.instance;
      GeolocatorPlatform.instance = mockGeolocator;
      addTearDown(() => GeolocatorPlatform.instance = originalPlatform);

      when(
        mockGeolocator.isLocationServiceEnabled,
      ).thenAnswer((_) async => false);
      when(
        mockGeolocator.checkPermission,
      ).thenAnswer((_) async => LocationPermission.denied);
      when(mockGeolocator.openLocationSettings).thenAnswer((_) async => true);

      await tester.pumpApp(Scaffold(body: HomeMapView(collar: collar)));
      await tester.pumpAndSettle();

      final myLocationButton = find.byWidgetPredicate(
        (widget) =>
            widget is ExpressiveIconButton && widget.tooltip == 'Mi ubicación',
      );
      expect(myLocationButton, findsOneWidget);

      await tester.tap(myLocationButton);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Ajustes'), findsOneWidget);

      await tester.tap(find.text('Ajustes'));
      await tester.pumpAndSettle();
      verify(mockGeolocator.openLocationSettings).called(1);
    });

    testWidgets(
      'shows snackbar and opens app settings when location denied forever',
      (tester) async {
        final mockGeolocator = MockGeolocatorPlatform();
        final originalPlatform = GeolocatorPlatform.instance;
        GeolocatorPlatform.instance = mockGeolocator;
        addTearDown(() => GeolocatorPlatform.instance = originalPlatform);

        when(
          mockGeolocator.isLocationServiceEnabled,
        ).thenAnswer((_) async => true);
        when(
          mockGeolocator.checkPermission,
        ).thenAnswer((_) async => LocationPermission.deniedForever);
        when(mockGeolocator.openAppSettings).thenAnswer((_) async => true);

        await tester.pumpApp(Scaffold(body: HomeMapView(collar: collar)));
        await tester.pumpAndSettle();

        final myLocationButton = find.byWidgetPredicate(
          (widget) =>
              widget is ExpressiveIconButton &&
              widget.tooltip == 'Mi ubicación',
        );

        await tester.tap(myLocationButton);
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('Ajustes'), findsOneWidget);

        await tester.tap(find.text('Ajustes'));
        await tester.pumpAndSettle();
        verify(mockGeolocator.openAppSettings).called(1);
      },
    );

    testWidgets('handles location denied then requested and denied forever', (
      tester,
    ) async {
      final mockGeolocator = MockGeolocatorPlatform();
      final originalPlatform = GeolocatorPlatform.instance;
      GeolocatorPlatform.instance = mockGeolocator;
      addTearDown(() => GeolocatorPlatform.instance = originalPlatform);

      when(
        mockGeolocator.isLocationServiceEnabled,
      ).thenAnswer((_) async => true);
      when(
        mockGeolocator.checkPermission,
      ).thenAnswer((_) async => LocationPermission.denied);
      when(
        mockGeolocator.requestPermission,
      ).thenAnswer((_) async => LocationPermission.deniedForever);

      await tester.pumpApp(Scaffold(body: HomeMapView(collar: collar)));
      await tester.pumpAndSettle();

      final myLocationButton = find.byWidgetPredicate(
        (widget) =>
            widget is ExpressiveIconButton && widget.tooltip == 'Mi ubicación',
      );

      await tester.tap(myLocationButton);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets(
      'handles permission granted, updates distance pill and navigates',
      (tester) async {
        final mockGeolocator = MockGeolocatorPlatform();
        final originalPlatform = GeolocatorPlatform.instance;
        GeolocatorPlatform.instance = mockGeolocator;
        addTearDown(() => GeolocatorPlatform.instance = originalPlatform);

        final controller = MockGoogleMapController();
        when(() => controller.animateCamera(any())).thenAnswer((_) async {});
        when(() => controller.moveCamera(any())).thenAnswer((_) async {});
        when(
          () => controller.getScreenCoordinate(any()),
        ).thenAnswer((_) async => const ScreenCoordinate(x: 150, y: 250));

        final position = Position(
          latitude: -12.0460,
          longitude: -77.0420,
          timestamp: DateTime(2026, 10, 22),
          accuracy: 5,
          altitude: 100,
          altitudeAccuracy: 1,
          heading: 0,
          headingAccuracy: 1,
          speed: 0,
          speedAccuracy: 0,
        );

        when(
          mockGeolocator.isLocationServiceEnabled,
        ).thenAnswer((_) async => true);
        when(
          mockGeolocator.checkPermission,
        ).thenAnswer((_) async => LocationPermission.whileInUse);
        when(
          () => mockGeolocator.getCurrentPosition(
            locationSettings: any(named: 'locationSettings'),
          ),
        ).thenAnswer((_) async => position);
        when(
          mockGeolocator.getLastKnownPosition,
        ).thenAnswer((_) async => position);
        when(
          () => mockGeolocator.distanceBetween(any(), any(), any(), any()),
        ).thenReturn(42);

        await tester.pumpApp(Scaffold(body: HomeMapView(collar: collar)));
        final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
        googleMap.onMapCreated?.call(controller);
        await tester.pumpAndSettle();

        final myLocationButton = find.byWidgetPredicate(
          (widget) =>
              widget is ExpressiveIconButton &&
              widget.tooltip == 'Mi ubicación',
        );

        await tester.tap(myLocationButton);
        await tester.pumpAndSettle();

        // Distance overlay button should now be visible
        final routeIcon = find.byWidgetPredicate(
          (w) => w is HugeIcon && w.icon == HugeIcons.strokeRoundedRoute01,
        );
        expect(routeIcon, findsOneWidget);

        // Tap the distance overlay to go to cat location
        await tester.tap(routeIcon);
        await tester.pumpAndSettle();

        // Open cat callout to verify distance subtitle
        final catMarker = googleMap.markers.firstWhere(
          (m) => m.markerId.value == 'cat_location',
        );
        catMarker.onTap?.call();
        await tester.pumpAndSettle();
        expect(find.text('Michi Test'), findsOneWidget);

        // Update widget with new coordinates while user position & cat selected
        final movedCollar = collar.copyWith(
          coords: const CollarCoords(lat: -12.0490, lon: -77.0470, altM: 105),
          breed: CatBreed.siamese,
        );
        await tester.pumpApp(Scaffold(body: HomeMapView(collar: movedCollar)));
        await tester.pumpAndSettle();
      },
    );
  });
}
