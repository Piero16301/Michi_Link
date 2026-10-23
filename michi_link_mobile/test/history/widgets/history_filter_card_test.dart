import 'package:expressive_kit/expressive_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/history/widgets/history_filter_card.dart';

import '../../helpers/helpers.dart';

void main() {
  group('HistoryFilterCard', () {
    testWidgets('renders filter card and handles interactions', (tester) async {
      var prevCalled = false;
      var nextCalled = false;
      double? changedStart;
      double? changedEnd;

      final now = DateTime.now();

      await tester.pumpApp(
        Scaffold(
          body: HistoryFilterCard(
            selectedDate: now,
            isNextEnabled: true,
            onPreviousDate: () => prevCalled = true,
            onNextDate: () => nextCalled = true,
            onDateSelected: (_) {},
            startHour: 6,
            endHour: 22,
            onTimeRangeChanged: (start, end) {
              changedStart = start;
              changedEnd = end;
            },
          ),
        ),
      );

      expect(find.byType(HistoryFilterCard), findsOneWidget);
      expect(find.text('06:00 - 22:00'), findsOneWidget);

      final iconButtons = find.byType(ExpressiveIconButton);
      expect(iconButtons, findsNWidgets(2));

      await tester.tap(iconButtons.first);
      expect(prevCalled, isTrue);

      await tester.tap(iconButtons.last);
      expect(nextCalled, isTrue);

      // Tap "Todo el día"
      await tester.tap(find.byType(InkWell).at(3));
      expect(changedStart, 0);
      expect(changedEnd, 24);
    });

    testWidgets('opens DatePickerDialog on tapping date', (tester) async {
      DateTime? selected;
      await tester.pumpApp(
        Scaffold(
          body: HistoryFilterCard(
            selectedDate: DateTime(2025, 4),
            onPreviousDate: () {},
            onNextDate: () {},
            onDateSelected: (d) => selected = d,
            startHour: 0,
            endHour: 24,
            onTimeRangeChanged: (_, _) {},
          ),
        ),
      );

      await tester.tap(find.byType(InkWell).at(1));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tap(find.byType(TextButton).last);
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
    });

    testWidgets('updates when widget properties change', (tester) async {
      double start = 2;
      double end = 8;
      late StateSetter setState;

      await tester.pumpApp(
        Scaffold(
          body: StatefulBuilder(
            builder: (context, setS) {
              setState = setS;
              return HistoryFilterCard(
                selectedDate: DateTime(2025, 4),
                onPreviousDate: () {},
                onNextDate: () {},
                onDateSelected: (_) {},
                startHour: start,
                endHour: end,
                onTimeRangeChanged: (_, _) {},
              );
            },
          ),
        ),
      );

      expect(find.text('02:00 - 08:00'), findsOneWidget);

      setState(() {
        start = 10;
        end = 18;
      });
      await tester.pump();

      expect(find.text('10:00 - 18:00'), findsOneWidget);
    });
  });
}
