import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/collars/collars.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_app.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

class MockAppCubit extends MockCubit<AppState> implements AppCubit {}

void main() {
  group('CollarCard', () {
    late MockDatabaseService databaseService;
    late MockAppCubit appCubit;
    late StreamController<CollarModel> streamController;

    setUp(() async {
      databaseService = MockDatabaseService();
      appCubit = MockAppCubit();
      streamController = StreamController<CollarModel>.broadcast();

      when(() => appCubit.state).thenReturn(const AppState());
      when(
        () => databaseService.getCollarStream(deviceId: any(named: 'deviceId')),
      ).thenAnswer((_) => streamController.stream);

      if (getIt.isRegistered<DatabaseService>()) {
        await getIt.unregister<DatabaseService>();
      }
      getIt.registerSingleton<DatabaseService>(databaseService);
    });

    tearDown(() async {
      await streamController.close();
      if (getIt.isRegistered<DatabaseService>()) {
        getIt.unregister<DatabaseService>();
      }
    });

    testWidgets('renders LoadingCollarCard when stream has no data yet', (
      tester,
    ) async {
      await tester.pumpApp(
        BlocProvider<AppCubit>.value(
          value: appCubit,
          child: const Scaffold(body: CollarCard(deviceId: 'COLLAR_TEST')),
        ),
      );

      expect(find.byType(LoadingCollarCard), findsOneWidget);
    });

    testWidgets('renders SuccessCollarCard when stream emits collar data', (
      tester,
    ) async {
      await tester.pumpApp(
        BlocProvider<AppCubit>.value(
          value: appCubit,
          child: const Scaffold(
            body: SingleChildScrollView(
              child: CollarCard(deviceId: 'COLLAR_TEST'),
            ),
          ),
        ),
      );

      final collar = CollarModel.fromJson(const {
        'device_id': 'COLLAR_TEST',
        'name': 'Michi Stream',
        'is_online': true,
      });

      streamController.add(collar);
      await tester.pump();

      expect(find.byType(SuccessCollarCard), findsOneWidget);
      expect(find.text('Michi Stream'), findsOneWidget);
    });

    testWidgets('renders SizedBox.shrink on stream error', (tester) async {
      await tester.pumpApp(
        BlocProvider<AppCubit>.value(
          value: appCubit,
          child: const Scaffold(body: CollarCard(deviceId: 'COLLAR_TEST')),
        ),
      );

      streamController.addError(Exception('database error'));
      await tester.pump();

      expect(find.byType(SuccessCollarCard), findsNothing);
      expect(find.byType(LoadingCollarCard), findsNothing);
    });
  });
}
