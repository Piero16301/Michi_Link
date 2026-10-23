import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/settings/settings.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../helpers/pump_app.dart';

class MockAppCubit extends MockCubit<AppState> implements AppCubit {}

void main() {
  group('SettingsPage', () {
    late MockAppCubit appCubit;

    setUp(() {
      PackageInfo.setMockInitialValues(
        appName: 'MichiLink',
        packageName: 'com.michilink.app',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
      );

      appCubit = MockAppCubit();
      when(() => appCubit.state).thenReturn(const AppState());
      when(
        () => appCubit.stream,
      ).thenAnswer((_) => Stream.value(const AppState()));
    });

    testWidgets('renders SettingsView', (tester) async {
      await tester.pumpApp(
        BlocProvider<AppCubit>.value(
          value: appCubit,
          child: const SettingsPage(),
        ),
      );

      expect(find.byType(SettingsView), findsOneWidget);
    });
  });
}
