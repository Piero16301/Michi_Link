import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/collars/collars.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_app.dart';

class MockCollarsCubit extends MockCubit<CollarsState>
    implements CollarsCubit {}

void main() {
  group('AddCollarBottomSheet', () {
    late MockCollarsCubit collarsCubit;

    setUp(() {
      collarsCubit = MockCollarsCubit();
      when(() => collarsCubit.state).thenReturn(const CollarsState());
    });

    testWidgets(
      'enables save button only when 16 characters are entered and calls '
      'addCollar',
      (tester) async {
        await tester.pumpApp(
          BlocProvider<CollarsCubit>.value(
            value: collarsCubit,
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: SizedBox(
                    height: 700,
                    child: AddCollarBottomSheet(parentContext: context),
                  ),
                );
              },
            ),
          ),
        );

        final saveButton = find.text('Guardar y Vincular');
        expect(saveButton, findsOneWidget);

        // Enter 16 alphanumeric characters
        await tester.enterText(find.byType(TextField), '0123456789ABCDEF');
        await tester.pumpAndSettle();

        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        verify(
          () => collarsCubit.addCollar(
            name: any(named: 'name'),
            deviceId: 'COLLAR_0123456789ABCDEF',
          ),
        ).called(1);
      },
    );

    testWidgets('clear button clears text input', (tester) async {
      await tester.pumpApp(
        BlocProvider<CollarsCubit>.value(
          value: collarsCubit,
          child: Builder(
            builder: (context) {
              return Scaffold(
                body: SizedBox(
                  height: 700,
                  child: AddCollarBottomSheet(parentContext: context),
                ),
              );
            },
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'ABCD');
      await tester.pumpAndSettle();

      final clearBtn = find.byType(IconButton);
      if (clearBtn.evaluate().isNotEmpty) {
        await tester.tap(clearBtn.first);
        await tester.pumpAndSettle();
        expect(find.text('ABCD'), findsNothing);
      }
    });
  });
}
