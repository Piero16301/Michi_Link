import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/collars/collars.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('CatBreedSelector', () {
    testWidgets('renders all breeds and handles tap selection', (tester) async {
      CatBreed? selected;

      await tester.pumpApp(
        Scaffold(
          body: CatBreedSelector(
            selectedBreed: CatBreed.defaultBreed,
            onBreedSelected: (breed) => selected = breed,
          ),
        ),
      );

      expect(find.byType(CatBreedSelector), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);

      await tester.tap(
        find.text(
          CatBreed.persian.displayName(
            tester.element(find.byType(CatBreedSelector)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(selected, CatBreed.persian);
    });
  });
}
