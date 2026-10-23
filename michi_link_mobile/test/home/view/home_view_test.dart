import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/home/home.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/helpers.dart';

class MockAppCubit extends MockCubit<AppState> implements AppCubit {}

void main() {
  group('HomeView', () {
    late MockAppCubit appCubit;

    setUpAll(() {
      setupServiceLocator(Environment.mock);
    });

    setUp(() {
      appCubit = MockAppCubit();
      when(() => appCubit.state).thenReturn(const AppState());
      when(
        () => appCubit.stream,
      ).thenAnswer((_) => Stream.value(const AppState()));
    });

    testWidgets('renders HomeNoCollarView when selectedCollarId is null', (
      tester,
    ) async {
      await tester.pumpApp(
        BlocProvider<AppCubit>.value(value: appCubit, child: const HomeView()),
      );

      expect(find.byType(HomeView), findsOneWidget);
      expect(find.byType(HomeNoCollarView), findsOneWidget);
    });

    testWidgets('renders HomeContentView when selectedCollarId is present', (
      tester,
    ) async {
      when(
        () => appCubit.state,
      ).thenReturn(const AppState(selectedCollarId: 'COLLAR_1'));
      when(() => appCubit.stream).thenAnswer(
        (_) => Stream.value(const AppState(selectedCollarId: 'COLLAR_1')),
      );

      await tester.pumpApp(
        BlocProvider<AppCubit>.value(value: appCubit, child: const HomeView()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeView), findsOneWidget);
      expect(find.byType(HomeContentView), findsOneWidget);
    });
  });
}
