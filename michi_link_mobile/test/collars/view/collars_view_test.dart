import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/collars/collars.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_app.dart';

class MockAppCubit extends MockCubit<AppState> implements AppCubit {}

class MockCollarsCubit extends MockCubit<CollarsState>
    implements CollarsCubit {}

void main() {
  group('CollarsView', () {
    late MockAppCubit appCubit;
    late MockCollarsCubit collarsCubit;

    setUpAll(() {
      setupServiceLocator(Environment.mock);
    });

    setUp(() {
      appCubit = MockAppCubit();
      collarsCubit = MockCollarsCubit();
      when(() => appCubit.state).thenReturn(const AppState());
      when(
        () => appCubit.stream,
      ).thenAnswer((_) => Stream.value(const AppState()));
      when(() => collarsCubit.state).thenReturn(const CollarsState());
      when(
        () => collarsCubit.stream,
      ).thenAnswer((_) => Stream.value(const CollarsState()));
    });

    testWidgets('renders empty state when there are no collars', (
      tester,
    ) async {
      await tester.pumpApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<AppCubit>.value(value: appCubit),
            BlocProvider<CollarsCubit>.value(value: collarsCubit),
          ],
          child: const CollarsView(),
        ),
      );

      expect(find.text('Aún no hay collares vinculados'), findsOneWidget);
      expect(find.text('Vincular nuevo collar'), findsOneWidget);
    });

    testWidgets('renders list with CollarCard when collars exist', (
      tester,
    ) async {
      when(() => collarsCubit.state).thenReturn(
        const CollarsState(collars: ['COLLAR_TEST_1', 'COLLAR_TEST_2']),
      );
      when(() => collarsCubit.stream).thenAnswer(
        (_) => Stream.value(
          const CollarsState(collars: ['COLLAR_TEST_1', 'COLLAR_TEST_2']),
        ),
      );

      await tester.pumpApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<AppCubit>.value(value: appCubit),
            BlocProvider<CollarsCubit>.value(value: collarsCubit),
          ],
          child: const CollarsView(),
        ),
      );

      expect(find.byType(CollarCard), findsNWidgets(2));
    });

    testWidgets(
      'opens AddCollarBottomSheet when Vincular nuevo collar is tapped',
      (tester) async {
        await tester.pumpApp(
          MultiBlocProvider(
            providers: [
              BlocProvider<AppCubit>.value(value: appCubit),
              BlocProvider<CollarsCubit>.value(value: collarsCubit),
            ],
            child: const CollarsView(),
          ),
        );

        await tester.tap(find.text('Vincular nuevo collar'));
        await tester.pumpAndSettle();

        expect(find.byType(AddCollarBottomSheet), findsOneWidget);
      },
    );
  });
}
