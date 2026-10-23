import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/history/history.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('LoadingHistoryCard', () {
    testWidgets('renders shimmer placeholders', (tester) async {
      await tester.pumpApp(const Scaffold(body: LoadingHistoryCard()));

      expect(find.byType(LoadingHistoryCard), findsOneWidget);
    });
  });
}
