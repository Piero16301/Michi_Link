import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/home/widgets/metric_card.dart';

import '../../helpers/helpers.dart';

void main() {
  group('MetricCard', () {
    testWidgets('renders child widget with correct container layout', (
      tester,
    ) async {
      await tester.pumpApp(const MetricCard(child: Text('Metric Content')));

      expect(find.byType(MetricCard), findsOneWidget);
      expect(find.text('Metric Content'), findsOneWidget);
    });
  });
}
