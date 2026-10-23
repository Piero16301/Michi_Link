import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/settings/settings.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('SettingsCardBlock', () {
    testWidgets('renders title, selected value and handles onChanged', (
      tester,
    ) async {
      String? selectedValue = 'A';

      await tester.pumpApp(
        Scaffold(
          body: SettingsCardBlock<String>(
            title: 'Block Title',
            value: selectedValue,
            items: const [
              DropdownMenuItem(value: 'A', child: Text('Option A')),
              DropdownMenuItem(value: 'B', child: Text('Option B')),
            ],
            onChanged: (val) => selectedValue = val,
          ),
        ),
      );

      expect(find.text('Block Title'), findsOneWidget);
      expect(find.text('Option A'), findsOneWidget);

      await tester.tap(find.text('Option A'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Option B').last);
      await tester.pumpAndSettle();

      expect(selectedValue, 'B');
    });

    testWidgets('renders inside Expanded when isExpanded is true', (
      tester,
    ) async {
      await tester.pumpApp(
        const Scaffold(
          body: Row(
            children: [
              SettingsCardBlock<String>(
                title: 'Expanded Block',
                value: 'A',
                isExpanded: true,
                items: [DropdownMenuItem(value: 'A', child: Text('Option A'))],
              ),
            ],
          ),
        ),
      );

      expect(find.text('Expanded Block'), findsOneWidget);
      final block = tester.widget<SettingsCardBlock<String>>(
        find.byType(SettingsCardBlock<String>),
      );
      expect(block.isExpanded, isTrue);
    });
  });
}
