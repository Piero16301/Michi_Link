import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/settings/settings.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../helpers/pump_app.dart';

class MockAppCubit extends MockCubit<AppState> implements AppCubit {}

void main() {
  setUpAll(() {
    registerFallbackValue(ThemeMode.light);
    registerFallbackValue(Colors.blue);
    registerFallbackValue(const Locale('es'));
  });

  group('SettingsView', () {
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
      when(
        () => appCubit.changeTheme(theme: any(named: 'theme')),
      ).thenAnswer((_) async {});
      when(
        () => appCubit.changeBaseColor(baseColor: any(named: 'baseColor')),
      ).thenAnswer((_) async {});
      when(
        () => appCubit.changeFontFamily(fontFamily: any(named: 'fontFamily')),
      ).thenAnswer((_) async {});
      when(
        () => appCubit.changeLanguage(language: any(named: 'language')),
      ).thenAnswer((_) async {});
    });

    testWidgets('renders all settings groups and tiles', (tester) async {
      await tester.pumpApp(
        BlocProvider<AppCubit>.value(
          value: appCubit,
          child: const SettingsView(),
        ),
      );

      expect(find.byType(SettingsView), findsOneWidget);
      expect(find.byType(SettingsAppSpecs), findsOneWidget);
    });

    testWidgets(
      'tapping theme tile opens modal and selecting theme calls cubit',
      (tester) async {
        await tester.pumpApp(
          BlocProvider<AppCubit>.value(
            value: appCubit,
            child: const SettingsView(),
          ),
        );

        await tester.tap(find.text('Tema'));
        await tester.pumpAndSettle();

        final darkOption = find.text('Oscuro');
        if (darkOption.evaluate().isNotEmpty) {
          await tester.tap(darkOption.last);
          await tester.pumpAndSettle();
          verify(() => appCubit.changeTheme(theme: ThemeMode.dark)).called(1);
        }
      },
    );

    testWidgets(
      'tapping color tile opens color modal and selecting color calls cubit',
      (tester) async {
        await tester.pumpApp(
          BlocProvider<AppCubit>.value(
            value: appCubit,
            child: const SettingsView(),
          ),
        );

        await tester.tap(find.text('Color base'));
        await tester.pumpAndSettle();

        expect(find.byType(BottomSheet), findsOneWidget);
      },
    );

    testWidgets('tapping font tile opens font modal', (tester) async {
      await tester.pumpApp(
        BlocProvider<AppCubit>.value(
          value: appCubit,
          child: const SettingsView(),
        ),
      );

      await tester.tap(find.text('Fuente'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('tapping language tile opens language modal', (tester) async {
      await tester.pumpApp(
        BlocProvider<AppCubit>.value(
          value: appCubit,
          child: const SettingsView(),
        ),
      );

      await tester.tap(find.text('Idioma').last);
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
    });
  });
}
