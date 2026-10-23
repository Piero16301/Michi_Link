import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';

import '../../helpers/helpers.dart';

void main() {
  group('AppFunctions', () {
    testWidgets('showSnackBar displays snackbar for each type', (tester) async {
      await tester.pumpApp(
        Scaffold(
          body: Builder(
            builder: (context) {
              return Column(
                children: [
                  for (final type in SnackBarType.values)
                    ElevatedButton(
                      key: ValueKey(type),
                      onPressed: () {
                        AppFunctions.showSnackBar(
                          context,
                          message: 'Test message for ${type.name}',
                          type: type,
                        );
                      },
                      child: Text(type.name),
                    ),
                ],
              );
            },
          ),
        ),
      );

      for (final type in SnackBarType.values) {
        await tester.tap(find.byKey(ValueKey(type)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Test message for ${type.name}'), findsOneWidget);
        expect(find.byType(SnackBar), findsOneWidget);

        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
      }
    });
  });
}
