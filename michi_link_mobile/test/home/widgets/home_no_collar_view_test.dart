import 'package:flutter_test/flutter_test.dart';
import 'package:michi_link_mobile/home/widgets/home_no_collar_view.dart';

import '../../helpers/helpers.dart';

void main() {
  group('HomeNoCollarView', () {
    testWidgets('renders title, description and action buttons', (
      tester,
    ) async {
      await tester.pumpApp(const HomeNoCollarView());

      expect(find.byType(HomeNoCollarView), findsOneWidget);
      expect(find.text('Aún no tienes un collar agregado'), findsOneWidget);
      expect(find.text('Ir a mascotas'), findsOneWidget);
    });
  });
}
