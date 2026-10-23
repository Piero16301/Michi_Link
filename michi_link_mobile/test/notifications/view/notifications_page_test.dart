import 'package:flutter_test/flutter_test.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/notifications/notifications.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('NotificationsPage', () {
    setUpAll(() {
      setupServiceLocator(Environment.mock);
    });

    testWidgets('renders NotificationsView', (tester) async {
      await tester.pumpApp(const NotificationsPage(collarId: 'COLLAR_TEST'));

      expect(find.byType(NotificationsView), findsOneWidget);
    });
  });
}
