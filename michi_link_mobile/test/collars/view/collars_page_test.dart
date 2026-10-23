import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/collars/collars.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('CollarsPage', () {
    setUpAll(() {
      setupServiceLocator(Environment.mock);
    });

    testWidgets('renders CollarsView', (tester) async {
      await tester.pumpApp(
        BlocProvider<AppCubit>(
          create: (_) => AppCubit(),
          child: const CollarsPage(),
        ),
      );

      expect(find.byType(CollarsView), findsOneWidget);
    });
  });
}
