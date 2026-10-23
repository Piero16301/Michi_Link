import 'package:expressive_kit/expressive_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/history/widgets/history_date_selector.dart';

import '../../helpers/helpers.dart';

void main() {
  group('HistoryDateSelector', () {
    testWidgets('renders today label and handles next/previous clicks', (
      tester,
    ) async {
      var prevCalled = false;
      var nextCalled = false;

      final now = DateTime.now();

      await tester.pumpApp(
        HistoryDateSelector(
          selectedDate: now,
          isNextEnabled: true,
          onPrevious: () => prevCalled = true,
          onNext: () => nextCalled = true,
          onDateSelected: (_) {},
        ),
      );

      expect(find.byType(HistoryDateSelector), findsOneWidget);

      final iconButtons = find.byType(ExpressiveIconButton);
      expect(iconButtons, findsNWidgets(2));

      await tester.tap(iconButtons.first);
      expect(prevCalled, isTrue);

      await tester.tap(iconButtons.last);
      expect(nextCalled, isTrue);
    });

    testWidgets('renders yesterday label', (tester) async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      await tester.pumpApp(
        HistoryDateSelector(
          selectedDate: yesterday,
          onPrevious: () {},
          onNext: () {},
          onDateSelected: (_) {},
        ),
      );

      expect(find.byType(HistoryDateSelector), findsOneWidget);
    });

    testWidgets('renders other date label and opens date picker on tap', (
      tester,
    ) async {
      final customDate = DateTime(2025, 5, 12);
      DateTime? selectedDate;

      await tester.pumpApp(
        Scaffold(
          body: HistoryDateSelector(
            selectedDate: customDate,
            onPrevious: () {},
            onNext: () {},
            onDateSelected: (date) => selectedDate = date,
          ),
        ),
      );

      expect(find.byType(HistoryDateSelector), findsOneWidget);

      await tester.tap(find.byType(InkWell).at(1));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);

      await tester.tap(find.byType(TextButton).last);
      await tester.pumpAndSettle();

      expect(selectedDate, isNotNull);
    });
  });
}
