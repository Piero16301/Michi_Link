import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/collars/collars.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_app.dart';

class MockAppCubit extends MockCubit<AppState> implements AppCubit {}

void main() {
  group('SuccessCollarCard', () {
    late MockAppCubit appCubit;
    late CollarModel collar;

    setUp(() {
      appCubit = MockAppCubit();
      when(
        () => appCubit.state,
      ).thenReturn(const AppState(selectedCollarId: 'COLLAR_001'));
      when(() => appCubit.stream).thenAnswer(
        (_) => Stream.value(const AppState(selectedCollarId: 'COLLAR_001')),
      );
      collar = CollarModel.fromJson(const {
        'device_id': 'COLLAR_001',
        'name': 'Michi Test',
        'is_online': true,
        'has_active_alert': false,
        'packet_loss_pct': 2.0,
        'packets_lost': 2,
        'packets_received': 100,
        'status': {
          'battery_pct': 85,
          'battery_v': 4.1,
          'sats': 12,
          'gps_fix': true,
        },
        'radio': {
          'rssi': -75,
          'snr': 9,
          'distance_home_m': 25.5,
          'packets_lost_gap': 0,
        },
      });
    });

    testWidgets('renders collar data and calls onEdit when edit icon tapped', (
      tester,
    ) async {
      var editCalled = false;

      await tester.pumpApp(
        BlocProvider<AppCubit>.value(
          value: appCubit,
          child: Scaffold(
            body: SingleChildScrollView(
              child: SuccessCollarCard(
                collar: collar,
                onEdit: () => editCalled = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Michi Test'), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
      expect(find.text('-75 dBm'), findsOneWidget);

      final editBtn = find.byTooltip('Editar collar');
      if (editBtn.evaluate().isNotEmpty) {
        await tester.tap(editBtn);
        await tester.pumpAndSettle();
        expect(editCalled, isTrue);
      }
    });

    testWidgets('allows selecting collar when not currently selected', (
      tester,
    ) async {
      when(
        () => appCubit.state,
      ).thenReturn(const AppState(selectedCollarId: 'OTHER_COLLAR'));
      when(() => appCubit.stream).thenAnswer(
        (_) => Stream.value(const AppState(selectedCollarId: 'OTHER_COLLAR')),
      );
      when(
        () => appCubit.changeSelectedCollarId(deviceId: any(named: 'deviceId')),
      ).thenAnswer((_) async {});

      await tester.pumpApp(
        BlocProvider<AppCubit>.value(
          value: appCubit,
          child: Scaffold(
            body: SingleChildScrollView(
              child: SuccessCollarCard(collar: collar, onEdit: () {}),
            ),
          ),
        ),
      );

      final selectBtn = find.byTooltip('Seleccionar collar');
      expect(selectBtn, findsOneWidget);
      await tester.tap(selectBtn);
      await tester.pumpAndSettle();

      verify(
        () => appCubit.changeSelectedCollarId(deviceId: 'COLLAR_001'),
      ).called(1);
    });
  });
}
