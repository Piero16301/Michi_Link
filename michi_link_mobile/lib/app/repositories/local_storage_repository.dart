import 'package:expressive_kit/expressive_kit.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';

abstract class LocalStorageRepository {
  static const kUserLanguage = '__user_language__';
  static const kUserTheme = '__user_theme__';
  static const kUserBaseColor = '__user_base_color__';
  static const kUserFontFamily = '__user_font_family__';

  static const kCollars = '__collars__';
  static const kSelectedDeviceId = '__selected_device_id__';

  Future<void> initialize();
  void saveLanguage({required Locale language});
  Locale? getLanguage();
  void saveTheme({required ThemeMode theme});
  ThemeMode? getTheme();
  void saveBaseColor({required Color baseColor});
  Color? getBaseColor();
  void saveFontFamily({required String fontFamily});
  String? getFontFamily();
  void saveCollars({required List<String> collars});
  List<String> getCollars();
  Stream<List<String>> getCollarsStream();
  void saveSelectedCollarId({String? deviceId});
  String? getSelectedCollarId();
  Stream<String?> getSelectedCollarIdStream();
}

class MockLocalStorageRepository implements LocalStorageRepository {
  @override
  Future<void> initialize() async {}

  @override
  void saveLanguage({required Locale language}) {}

  @override
  Locale? getLanguage() {
    return const Locale('en', 'US');
  }

  @override
  void saveTheme({required ThemeMode theme}) {}

  @override
  ThemeMode? getTheme() {
    return ThemeMode.light;
  }

  @override
  void saveBaseColor({required Color baseColor}) {}

  @override
  Color? getBaseColor() {
    return Colors.blue;
  }

  @override
  void saveFontFamily({required String fontFamily}) {}

  @override
  String? getFontFamily() {
    return 'default';
  }

  @override
  void saveCollars({required List<String> collars}) {}

  @override
  List<String> getCollars() {
    return [];
  }

  @override
  Stream<List<String>> getCollarsStream() {
    return const Stream.empty();
  }

  @override
  void saveSelectedCollarId({String? deviceId}) {}

  @override
  String? getSelectedCollarId() {
    return null;
  }

  @override
  Stream<String?> getSelectedCollarIdStream() {
    return const Stream.empty();
  }
}

class HiveLocalStorageRepository implements LocalStorageRepository {
  HiveLocalStorageRepository();

  static const kSettingsBoxName = '__settings__';
  static const kCollarsBoxName = '__collars__';
  static const kPropertiesBoxName = '__properties__';

  late final Box<String> _settingsBox;
  late final Box<String> _collarsBox;
  late final Box<String> _propertiesBox;

  @override
  Future<void> initialize() async {
    final performance = getIt<PerformanceService>();
    final trace = performance.startTrace('hive_initialization');

    try {
      // Initialize Hive
      await Hive.initFlutter();

      if (!Hive.isBoxOpen(kSettingsBoxName)) {
        await Hive.openBox<String>(kSettingsBoxName);
      }
      _settingsBox = Hive.box(kSettingsBoxName);

      if (!Hive.isBoxOpen(kCollarsBoxName)) {
        await Hive.openBox<String>(kCollarsBoxName);
      }
      _collarsBox = Hive.box<String>(kCollarsBoxName);

      if (!Hive.isBoxOpen(kPropertiesBoxName)) {
        await Hive.openBox<String>(kPropertiesBoxName);
      }
      _propertiesBox = Hive.box<String>(kPropertiesBoxName);
    } finally {
      performance.stopTrace(trace);
    }
  }

  @override
  void saveLanguage({required Locale language}) {
    final country = language.countryCode;
    final languageString = country != null && country.isNotEmpty
        ? '${language.languageCode}_$country'
        : language.languageCode;
    _settingsBox
        .put(LocalStorageRepository.kUserLanguage, languageString)
        .ignore();
  }

  @override
  Locale? getLanguage() {
    final languageString = _settingsBox.get(
      LocalStorageRepository.kUserLanguage,
    );
    if (languageString == null || languageString.isEmpty) {
      return null;
    }
    final languageParts = languageString.split('_');
    if (languageParts.length > 1 &&
        languageParts[1].isNotEmpty &&
        languageParts[1] != 'null') {
      return Locale(languageParts.first, languageParts[1]);
    }
    return Locale(languageParts.first);
  }

  @override
  void saveTheme({required ThemeMode theme}) {
    _settingsBox
        .put(LocalStorageRepository.kUserTheme, ExpressiveTheme.toKey(theme))
        .ignore();
  }

  @override
  ThemeMode? getTheme() {
    final themeString = _settingsBox.get(LocalStorageRepository.kUserTheme);
    if (themeString == null) {
      return null;
    }
    return ExpressiveTheme.fromKey(themeString);
  }

  @override
  void saveBaseColor({required Color baseColor}) {
    _settingsBox
        .put(
          LocalStorageRepository.kUserBaseColor,
          ExpressiveColors.toKey(baseColor),
        )
        .ignore();
  }

  @override
  Color? getBaseColor() {
    final baseColorString = _settingsBox.get(
      LocalStorageRepository.kUserBaseColor,
    );
    if (baseColorString == null) {
      return null;
    }
    return ExpressiveColors.fromKey(baseColorString);
  }

  @override
  void saveFontFamily({required String fontFamily}) {
    _settingsBox
        .put(LocalStorageRepository.kUserFontFamily, fontFamily)
        .ignore();
  }

  @override
  String? getFontFamily() {
    return _settingsBox.get(LocalStorageRepository.kUserFontFamily);
  }

  @override
  void saveCollars({required List<String> collars}) {
    _collarsBox.clear().then((_) async {
      if (collars.isNotEmpty) {
        await _collarsBox.addAll(collars);
      }
    }).ignore();
  }

  @override
  List<String> getCollars() {
    return _collarsBox.values.toList();
  }

  @override
  Stream<List<String>> getCollarsStream() async* {
    yield getCollars();
    yield* _collarsBox.watch().map((_) => getCollars());
  }

  @override
  void saveSelectedCollarId({String? deviceId}) {
    if (deviceId == null) {
      _propertiesBox.delete(LocalStorageRepository.kSelectedDeviceId).ignore();
    } else {
      _propertiesBox
          .put(LocalStorageRepository.kSelectedDeviceId, deviceId)
          .ignore();
    }
  }

  @override
  String? getSelectedCollarId() {
    return _propertiesBox.get(LocalStorageRepository.kSelectedDeviceId);
  }

  @override
  Stream<String?> getSelectedCollarIdStream() async* {
    yield getSelectedCollarId();
    yield* _propertiesBox
        .watch(key: LocalStorageRepository.kSelectedDeviceId)
        .map((_) => getSelectedCollarId());
  }
}
