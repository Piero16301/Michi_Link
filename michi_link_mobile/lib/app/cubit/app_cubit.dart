import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';

part 'app_state.dart';

class AppCubit extends Cubit<AppState> {
  AppCubit({LocalStorageService? localStorage})
    : _localStorage = localStorage ?? getIt<LocalStorageService>(),
      super(const AppState());

  final LocalStorageService _localStorage;

  void initialLoad() {
    // Setting the language to the device language if it's not set
    final language = _localStorage.getLanguage();
    if (language == null) {
      final deviceLocale = Platform.localeName.split('_').first;
      final deviceLanguage = AppVariables.supportedLocales.firstWhere(
        (locale) => locale.languageCode == deviceLocale,
        orElse: () => AppVariables.supportedLocales.first,
      );
      _localStorage.saveLanguage(language: deviceLanguage);
    }

    // Setting the theme to the device theme if it's not set
    final theme = _localStorage.getTheme();
    if (theme == null) {
      _localStorage.saveTheme(theme: ThemeMode.system);
    }

    // Setting the base color to GREEN if it's not set
    final baseColor = _localStorage.getBaseColor();
    if (baseColor == null) {
      _localStorage.saveBaseColor(baseColor: AppVariables.defaultBaseColor);
    }

    // Setting the font family to Popping if it's not set
    var fontFamily = _localStorage.getFontFamily();
    final isFontSupported =
        fontFamily != null &&
        AppVariables.availableFonts.containsValue(fontFamily);

    if (!isFontSupported) {
      final defaultFont =
          AppVariables.availableFonts[AppVariables.defaultFontFamily] ??
          AppVariables.defaultFontFamily;
      _localStorage.saveFontFamily(fontFamily: defaultFont);
      fontFamily = defaultFont;
    }

    emit(
      state.copyWith(
        language: _localStorage.getLanguage(),
        theme: _localStorage.getTheme(),
        baseColor: _localStorage.getBaseColor(),
        fontFamily: _localStorage.getFontFamily(),
      ),
    );
  }

  void changeLanguage({required Locale language}) {
    _localStorage.saveLanguage(language: language);
    getIt<AnalyticsService>().logEvent(
      name: 'change_language',
      parameters: {'language': language.languageCode},
    );
    emit(state.copyWith(language: language));
  }

  void changeTheme({required ThemeMode theme}) {
    _localStorage.saveTheme(theme: theme);
    getIt<AnalyticsService>().logEvent(
      name: 'change_theme',
      parameters: {'theme': theme.name.toUpperCase()},
    );
    emit(state.copyWith(theme: theme));
  }

  void changeBaseColor({required Color baseColor}) {
    _localStorage.saveBaseColor(baseColor: baseColor);
    getIt<AnalyticsService>().logEvent(
      name: 'change_base_color',
      parameters: {
        'color': ColorHelper.colorMap.containsValue(baseColor)
            ? ColorHelper.getColorName(baseColor)
            : baseColor.toARGB32().toRadixString(16),
      },
    );
    emit(state.copyWith(baseColor: baseColor));
  }

  void changeFontFamily({required String fontFamily}) {
    _localStorage.saveFontFamily(fontFamily: fontFamily);
    getIt<AnalyticsService>().logEvent(
      name: 'change_font_family',
      parameters: {'font': fontFamily},
    );
    emit(state.copyWith(fontFamily: fontFamily));
  }
}
