import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/settings/settings.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('SettingsAppSpecs', () {
    setUp(() {
      PackageInfo.setMockInitialValues(
        appName: 'MichiLink',
        packageName: 'com.michilink.app',
        version: '1.2.3',
        buildNumber: '45',
        buildSignature: '',
      );
    });

    testWidgets('renders version and build number', (tester) async {
      await tester.pumpApp(const Scaffold(body: SettingsAppSpecs()));

      await tester.pumpAndSettle();

      expect(find.byType(SettingsAppSpecs), findsOneWidget);
      expect(find.text('1.2.3 (45)'), findsOneWidget);
    });
  });
}
