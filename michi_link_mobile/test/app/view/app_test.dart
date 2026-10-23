import 'package:flutter_test/flutter_test.dart';
import 'package:michi_link_mobile/app/app.dart';

void main() {
  group('AppPage', () {
    setUpAll(() {
      if (!getIt.isRegistered<AnalyticsService>()) {
        setupServiceLocator(Environment.mock);
      }
    });

    testWidgets('renders AppPage and builds AppView', (tester) async {
      await tester.pumpWidget(const AppPage());
      await tester.pump();

      expect(find.byType(AppPage), findsOneWidget);
      expect(find.byType(AppView), findsOneWidget);
    });
  });
}
