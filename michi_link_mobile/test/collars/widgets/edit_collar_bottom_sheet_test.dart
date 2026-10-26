import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/collars/collars.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_app.dart';

class MockCollarsCubit extends MockCubit<CollarsState>
    implements CollarsCubit {}

void main() {
  setUpAll(() {
    registerFallbackValue(CatBreed.persian);
  });

  group('EditCollarBottomSheet', () {
    late MockCollarsCubit collarsCubit;
    late CollarModel collar;

    setUp(() {
      collarsCubit = MockCollarsCubit();
      when(() => collarsCubit.state).thenReturn(const CollarsState());
      collar = CollarModel.fromJson(const {
        'device_id': 'COLLAR_TEST_1234',
        'name': 'Michi Old Name',
        'is_online': true,
      }).copyWith(breed: CatBreed.siamese);
    });

    testWidgets('allows editing name and updating collar', (tester) async {
      await tester.pumpApp(
        BlocProvider<CollarsCubit>.value(
          value: collarsCubit,
          child: Builder(
            builder: (context) {
              return Scaffold(
                body: SizedBox(
                  height: 600,
                  child: EditCollarBottomSheet(
                    parentContext: context,
                    collar: collar,
                  ),
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Michi Old Name'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Michi New Name');
      await tester.pumpAndSettle();

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -250),
      );
      await tester.pumpAndSettle();

      final updateBtn = find.text('Actualizar Datos');
      expect(updateBtn, findsOneWidget);
      await tester.tap(updateBtn);
      await tester.pumpAndSettle();

      verify(
        () => collarsCubit.updateCollar(
          deviceId: 'COLLAR_TEST_1234',
          name: 'Michi New Name',
          breed: CatBreed.siamese,
        ),
      ).called(1);
    });

    testWidgets('unlinking collar opens dialog and unlinks when confirmed', (
      tester,
    ) async {
      await tester.pumpApp(
        BlocProvider<CollarsCubit>.value(
          value: collarsCubit,
          child: Builder(
            builder: (context) {
              return Scaffold(
                body: SizedBox(
                  height: 600,
                  child: EditCollarBottomSheet(
                    parentContext: context,
                    collar: collar,
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();

      final unlinkBtn = find.text('Desvincular collar');
      expect(unlinkBtn, findsOneWidget);
      await tester.tap(unlinkBtn);
      await tester.pumpAndSettle();

      // Dialog is shown
      expect(find.text('¿Desvincular collar?'), findsOneWidget);

      // Tap confirm button
      final confirmBtn = find.text('Desvincular');
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      verify(() => collarsCubit.removeCollar('COLLAR_TEST_1234')).called(1);
    });
  });
}
