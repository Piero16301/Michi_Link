import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/l10n/l10n.dart';

import '../helpers/pump_app.dart';

void main() {
  group('AppLocalizationsX', () {
    testWidgets('provides l10n getter on BuildContext', (tester) async {
      late AppLocalizations localizations;

      await tester.pumpApp(
        Builder(
          builder: (context) {
            localizations = context.l10n;
            return const SizedBox();
          },
        ),
      );

      expect(localizations, isNotNull);
      expect(localizations, isA<AppLocalizations>());
    });
  });
}
