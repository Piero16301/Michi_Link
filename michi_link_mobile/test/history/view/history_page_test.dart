import 'package:flutter_test/flutter_test.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/history/history.dart';

import '../../helpers/helpers.dart';

void main() {
  group('HistoryPage', () {
    setUpAll(() {
      setupServiceLocator(Environment.mock);
    });

    testWidgets('renders HistoryPage and builds HistoryView', (tester) async {
      await tester.pumpApp(const HistoryPage(collarId: 'COLLAR_TEST_PAGE'));
      await tester.pumpAndSettle();

      expect(find.byType(HistoryPage), findsOneWidget);
      expect(find.byType(HistoryView), findsOneWidget);
    });
  });
}
