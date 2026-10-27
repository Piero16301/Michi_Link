import 'dart:async';
import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expressive_kit/expressive_kit.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';

part 'app_state.dart';

class AppCubit extends Cubit<AppState> {
  AppCubit({LocalStorageService? localStorage})
    : _localStorage = localStorage ?? getIt<LocalStorageService>(),
      super(const AppState()) {
    _selectedCollarSubscription = _localStorage
        .getSelectedCollarIdStream()
        .listen(_onSelectedCollarChanged);
  }

  final LocalStorageService _localStorage;
  late final StreamSubscription<String?> _selectedCollarSubscription;

  void _onSelectedCollarChanged(String? deviceId) {
    emit(state.copyWith(selectedCollarId: deviceId));
  }

  void initialLoad() {
    // Setting the language to the device language if it's not set
    var language = _localStorage.getLanguage();
    if (language == null) {
      final deviceLocale = PlatformDispatcher.instance.locale.languageCode;
      language = ExpressiveLanguages.fromLanguageCode(deviceLocale);
      _localStorage.saveLanguage(language: language);
    }

    // Setting the theme to the device theme if it's not set
    var theme = _localStorage.getTheme();
    if (theme == null) {
      theme = ExpressiveTheme.defaultTheme;
      _localStorage.saveTheme(theme: theme);
    }

    // Setting the base color to default if it's not set
    var baseColor = _localStorage.getBaseColor();
    if (baseColor == null) {
      baseColor = ExpressiveColors.defaultColor;
      _localStorage.saveBaseColor(baseColor: baseColor);
    }

    // Setting the font family to default if it's not set
    var fontFamily = _localStorage.getFontFamily();
    final isFontSupported =
        fontFamily != null &&
        ExpressiveFonts.availableFonts.containsValue(fontFamily);

    if (!isFontSupported) {
      fontFamily = ExpressiveFonts.defaultFont;
      _localStorage.saveFontFamily(fontFamily: fontFamily);
    }

    emit(
      state.copyWith(
        language: language,
        theme: theme,
        baseColor: baseColor,
        fontFamily: fontFamily,
        selectedCollarId: _localStorage.getSelectedCollarId(),
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
        'color': ExpressiveColors.palette.containsValue(baseColor)
            ? ExpressiveColors.toKey(baseColor)
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

  void changeSelectedCollarId({String? deviceId}) {
    _localStorage.saveSelectedCollarId(deviceId: deviceId);
  }

  @override
  Future<void> close() async {
    await _selectedCollarSubscription.cancel();
    return await super.close();
  }
}
