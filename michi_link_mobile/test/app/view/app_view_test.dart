import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:mocktail/mocktail.dart';

class MockAppCubit extends Mock implements AppCubit {}

void main() {
  group('AppView', () {
    late AppCubit appCubit;

    setUpAll(() {
      if (!getIt.isRegistered<AnalyticsService>()) {
        setupServiceLocator(Environment.mock);
      }
    });

    setUp(() {
      appCubit = AppCubit();
    });

    tearDown(() async {
      await appCubit.close();
    });

    testWidgets('renders MaterialApp.router with AppState', (tester) async {
      await tester.pumpWidget(
        BlocProvider<AppCubit>.value(value: appCubit, child: const AppView()),
      );
      await tester.pump();

      expect(find.byType(AppView), findsOneWidget);
    });
  });
}
