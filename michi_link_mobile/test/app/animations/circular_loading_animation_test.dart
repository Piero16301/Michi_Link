import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';

import '../../helpers/helpers.dart';

void main() {
  group('CircularLoadingAnimation', () {
    testWidgets('renders animation with centerWidget and custom colors', (
      tester,
    ) async {
      await tester.pumpApp(
        const CircularLoadingAnimation(
          outerCircleColor: Colors.blue,
          innerCircleColor: Colors.amber,
          backgroundColor: Colors.black,
          size: 100,
          centerWidget: Text('Loading...'),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);

      // Advance animation
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Loading...'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1500));
    });

    testWidgets('renders without centerWidget', (tester) async {
      await tester.pumpApp(
        const CircularLoadingAnimation(
          outerCircleColor: Colors.blue,
          innerCircleColor: Colors.amber,
          backgroundColor: Colors.white,
        ),
      );

      expect(find.byType(CircularLoadingAnimation), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
