import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/home/home.dart';

import '../../helpers/helpers.dart';

void main() {
  group('HomePage', () {
    setUpAll(() {
      setupServiceLocator(Environment.mock);
    });

    testWidgets('renders HomePage with BlocProvider and builds HomeView', (
      tester,
    ) async {
      await tester.pumpApp(
        BlocProvider(create: (_) => AppCubit(), child: const HomePage()),
      );

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(HomeView), findsOneWidget);
    });
  });
}
