import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/notifications/notifications.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('LoadingNotificationCard', () {
    testWidgets('renders shimmer placeholders', (tester) async {
      await tester.pumpApp(const Scaffold(body: LoadingNotificationCard()));

      expect(find.byType(LoadingNotificationCard), findsOneWidget);
    });
  });
}
