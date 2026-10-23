import 'package:flutter_test/flutter_test.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/home/widgets/home_content_view.dart';
import 'package:michi_link_mobile/home/widgets/home_map_view.dart';
import 'package:michi_link_mobile/home/widgets/home_telemetry_panel.dart';

import '../../helpers/helpers.dart';

void main() {
  group('HomeContentView', () {
    setUpAll(() {
      setupServiceLocator(Environment.mock);
    });

    testWidgets('renders HomeMapView and HomeTelemetryPanel on stream data', (
      tester,
    ) async {
      await tester.pumpApp(const HomeContentView(collarId: 'COLLAR_1'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeContentView), findsOneWidget);
      expect(find.byType(HomeMapView), findsOneWidget);
      expect(find.byType(HomeTelemetryPanel), findsOneWidget);
    });
  });
}
