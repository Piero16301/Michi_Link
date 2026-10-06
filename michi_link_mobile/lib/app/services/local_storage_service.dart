import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';

class LocalStorageService {
  LocalStorageService({required this._localStorageRepository});

  final LocalStorageRepository _localStorageRepository;

  Future<void> initialize() async {
    await _localStorageRepository.initialize();
  }

  void saveLanguage({required Locale language}) {
    _localStorageRepository.saveLanguage(language: language);
  }

  Locale? getLanguage() {
    return _localStorageRepository.getLanguage();
  }

  void saveTheme({required ThemeMode theme}) {
    _localStorageRepository.saveTheme(theme: theme);
  }

  ThemeMode? getTheme() {
    return _localStorageRepository.getTheme();
  }

  void saveBaseColor({required Color baseColor}) {
    _localStorageRepository.saveBaseColor(baseColor: baseColor);
  }

  Color? getBaseColor() {
    return _localStorageRepository.getBaseColor();
  }

  void saveFontFamily({required String fontFamily}) {
    _localStorageRepository.saveFontFamily(fontFamily: fontFamily);
  }

  String? getFontFamily() {
    return _localStorageRepository.getFontFamily();
  }

  void saveCollars({required List<String> collars}) {
    _localStorageRepository.saveCollars(collars: collars);
  }

  List<String> getCollars() {
    return _localStorageRepository.getCollars();
  }

  Stream<List<String>> getCollarsStream() {
    return _localStorageRepository.getCollarsStream();
  }

  void saveSelectedCollarId({String? collarId}) {
    _localStorageRepository.saveSelectedCollarId(collarId: collarId);
  }

  String? getSelectedCollarId() {
    return _localStorageRepository.getSelectedCollarId();
  }

  Stream<String?> getSelectedCollarIdStream() {
    return _localStorageRepository.getSelectedCollarIdStream();
  }
}
