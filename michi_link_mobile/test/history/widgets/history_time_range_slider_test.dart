import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/history/widgets/history_time_range_slider.dart';

import '../../helpers/helpers.dart';

void main() {
  group('HistoryTimeRangeSlider', () {
    testWidgets('renders all day state without reset button', (tester) async {
      await tester.pumpApp(
        Scaffold(
          body: HistoryTimeRangeSlider(
            startHour: 0,
            endHour: 24,
            onRangeChanged: (start, end) {},
          ),
        ),
      );

      expect(find.byType(HistoryTimeRangeSlider), findsOneWidget);
      expect(find.text('00:00 - 24:00'), findsOneWidget);
      expect(find.byType(RangeSlider), findsOneWidget);
    });

    testWidgets('renders partial day and resets when tapping all day button', (
      tester,
    ) async {
      double? changedStart;
      double? changedEnd;

      await tester.pumpApp(
        Scaffold(
          body: HistoryTimeRangeSlider(
            startHour: 8,
            endHour: 18,
            onRangeChanged: (start, end) {
              changedStart = start;
              changedEnd = end;
            },
          ),
        ),
      );

      expect(find.text('08:00 - 18:00'), findsOneWidget);

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(changedStart, 0);
      expect(changedEnd, 24);
    });

    testWidgets('updates values when widget updates', (tester) async {
      double start = 4;
      double end = 12;
      late StateSetter setState;

      await tester.pumpApp(
        Scaffold(
          body: StatefulBuilder(
            builder: (context, setS) {
              setState = setS;
              return HistoryTimeRangeSlider(
                startHour: start,
                endHour: end,
                onRangeChanged: (_, _) {},
              );
            },
          ),
        ),
      );

      expect(find.text('04:00 - 12:00'), findsOneWidget);

      setState(() {
        start = 10;
        end = 20;
      });
      await tester.pump();

      expect(find.text('10:00 - 20:00'), findsOneWidget);
    });
  });
}
