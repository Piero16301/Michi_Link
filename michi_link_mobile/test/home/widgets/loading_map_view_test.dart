import 'package:flutter_test/flutter_test.dart';
import 'package:michi_link_mobile/home/widgets/loading_map_view.dart';
import 'package:shimmer/shimmer.dart';

import '../../helpers/helpers.dart';

void main() {
  group('LoadingMapView', () {
    testWidgets('renders shimmer placeholders and app bar', (tester) async {
      await tester.pumpApp(const LoadingMapView(deviceId: 'COLLAR_1'));

      expect(find.byType(LoadingMapView), findsOneWidget);
      expect(find.byType(Shimmer), findsWidgets);
    });
  });
}
