import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:mocktail/mocktail.dart';

class MockLocalStorageServiceInternal extends Mock
    implements LocalStorageService {}

class MockAnalyticsServiceInternal extends Mock implements AnalyticsService {}

void main() {
  setUpAll(() {
    registerFallbackValue(const Locale('en'));
    registerFallbackValue(ThemeMode.light);
    registerFallbackValue(Colors.blue);
  });

  group('AppCubit', () {
    late MockLocalStorageServiceInternal localStorage;
    late MockAnalyticsServiceInternal analyticsService;
    late StreamController<String?> selectedCollarController;

    setUp(() async {
      localStorage = MockLocalStorageServiceInternal();
      analyticsService = MockAnalyticsServiceInternal();
      selectedCollarController = StreamController<String?>.broadcast();

      when(
        () => localStorage.getSelectedCollarIdStream(),
      ).thenAnswer((_) => selectedCollarController.stream);

      if (getIt.isRegistered<AnalyticsService>()) {
        await getIt.unregister<AnalyticsService>();
      }
      getIt.registerSingleton<AnalyticsService>(analyticsService);
      when(
        () => analyticsService.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenReturn(null);
    });

    tearDown(() async {
      await selectedCollarController.close();
      if (getIt.isRegistered<AnalyticsService>()) {
        getIt.unregister<AnalyticsService>();
      }
    });

    test('initial state has default AppState', () {
      final cubit = AppCubit(localStorage: localStorage);
      expect(cubit.state, equals(const AppState()));
      unawaited(cubit.close());
    });

    test('updates state when selected collar stream emits', () async {
      final cubit = AppCubit(localStorage: localStorage);
      selectedCollarController.add('COLLAR_ABC');
      await pumpEventQueue();

      expect(cubit.state.selectedCollarId, 'COLLAR_ABC');
      unawaited(cubit.close());
    });

    test('initialLoad sets defaults when local storage has null values', () {
      when(() => localStorage.getLanguage()).thenReturn(null);
      when(
        () => localStorage.saveLanguage(language: any(named: 'language')),
      ).thenReturn(null);
      when(() => localStorage.getTheme()).thenReturn(null);
      when(
        () => localStorage.saveTheme(theme: any(named: 'theme')),
      ).thenReturn(null);
      when(() => localStorage.getBaseColor()).thenReturn(null);
      when(
        () => localStorage.saveBaseColor(baseColor: any(named: 'baseColor')),
      ).thenReturn(null);
      when(() => localStorage.getFontFamily()).thenReturn(null);
      when(
        () => localStorage.saveFontFamily(fontFamily: any(named: 'fontFamily')),
      ).thenReturn(null);
      when(
        () => localStorage.getSelectedCollarId(),
      ).thenReturn('COLLAR_DEFAULT');

      final cubit = AppCubit(localStorage: localStorage)..initialLoad();

      verify(
        () => localStorage.saveLanguage(language: any(named: 'language')),
      ).called(1);
      verify(
        () => localStorage.saveTheme(theme: any(named: 'theme')),
      ).called(1);
      verify(
        () => localStorage.saveBaseColor(baseColor: any(named: 'baseColor')),
      ).called(1);
      verify(
        () => localStorage.saveFontFamily(fontFamily: any(named: 'fontFamily')),
      ).called(1);
      unawaited(cubit.close());
    });

    blocTest<AppCubit, AppState>(
      'changeLanguage saves language, logs analytics and emits state',
      build: () {
        when(
          () => localStorage.saveLanguage(language: any(named: 'language')),
        ).thenReturn(null);
        return AppCubit(localStorage: localStorage);
      },
      act: (cubit) => cubit.changeLanguage(language: const Locale('fr')),
      expect: () => [
        isA<AppState>().having(
          (s) => s.language,
          'language',
          const Locale('fr'),
        ),
      ],
      verify: (_) {
        verify(
          () => localStorage.saveLanguage(language: const Locale('fr')),
        ).called(1);
        verify(
          () => analyticsService.logEvent(
            name: 'change_language',
            parameters: {'language': 'fr'},
          ),
        ).called(1);
      },
    );

    blocTest<AppCubit, AppState>(
      'changeTheme saves theme, logs analytics and emits state',
      build: () {
        when(
          () => localStorage.saveTheme(theme: any(named: 'theme')),
        ).thenReturn(null);
        return AppCubit(localStorage: localStorage);
      },
      act: (cubit) => cubit.changeTheme(theme: ThemeMode.dark),
      expect: () => [
        isA<AppState>().having((s) => s.theme, 'theme', ThemeMode.dark),
      ],
      verify: (_) {
        verify(() => localStorage.saveTheme(theme: ThemeMode.dark)).called(1);
        verify(
          () => analyticsService.logEvent(
            name: 'change_theme',
            parameters: {'theme': 'DARK'},
          ),
        ).called(1);
      },
    );

    blocTest<AppCubit, AppState>(
      'changeBaseColor saves base color, logs analytics and emits state',
      build: () {
        when(
          () => localStorage.saveBaseColor(baseColor: any(named: 'baseColor')),
        ).thenReturn(null);
        return AppCubit(localStorage: localStorage);
      },
      act: (cubit) => cubit.changeBaseColor(baseColor: Colors.teal),
      expect: () => [
        isA<AppState>().having((s) => s.baseColor, 'baseColor', Colors.teal),
      ],
      verify: (_) {
        verify(
          () => localStorage.saveBaseColor(baseColor: Colors.teal),
        ).called(1);
        verify(
          () => analyticsService.logEvent(
            name: 'change_base_color',
            parameters: any(named: 'parameters'),
          ),
        ).called(1);
      },
    );

    blocTest<AppCubit, AppState>(
      'changeFontFamily saves font family, logs analytics and emits state',
      build: () {
        when(
          () =>
              localStorage.saveFontFamily(fontFamily: any(named: 'fontFamily')),
        ).thenReturn(null);
        return AppCubit(localStorage: localStorage);
      },
      act: (cubit) => cubit.changeFontFamily(fontFamily: 'Inter'),
      expect: () => [
        isA<AppState>().having((s) => s.fontFamily, 'fontFamily', 'Inter'),
      ],
      verify: (_) {
        verify(
          () => localStorage.saveFontFamily(fontFamily: 'Inter'),
        ).called(1);
        verify(
          () => analyticsService.logEvent(
            name: 'change_font_family',
            parameters: {'font': 'Inter'},
          ),
        ).called(1);
      },
    );

    test('changeSelectedCollarId delegates to localStorage', () {
      when(
        () =>
            localStorage.saveSelectedCollarId(collarId: any(named: 'collarId')),
      ).thenReturn(null);
      final cubit = AppCubit(localStorage: localStorage)
        ..changeSelectedCollarId(collarId: 'COLLAR_999');

      verify(
        () => localStorage.saveSelectedCollarId(collarId: 'COLLAR_999'),
      ).called(1);
      unawaited(cubit.close());
    });
  });
}
