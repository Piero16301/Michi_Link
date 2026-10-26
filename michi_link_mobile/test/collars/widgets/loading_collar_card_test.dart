import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/collars/collars.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('LoadingCollarCard', () {
    testWidgets('renders loading shimmer and shortId', (tester) async {
      await tester.pumpApp(
        const Scaffold(body: LoadingCollarCard(deviceId: 'COLLAR_1234')),
      );

      expect(find.byType(LoadingCollarCard), findsOneWidget);
      expect(find.text('ID: ...1234'), findsOneWidget);
    });

    testWidgets('formats shortId when no underscore is present', (
      tester,
    ) async {
      await tester.pumpApp(
        const Scaffold(body: LoadingCollarCard(deviceId: 'ABCD')),
      );

      expect(find.text('ID: ...ABCD'), findsOneWidget);
    });
  });
}
