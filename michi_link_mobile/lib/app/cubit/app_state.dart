part of 'app_cubit.dart';

class AppState extends Equatable {
  const AppState({
    this.language = const Locale('en', 'US'),
    this.theme = ThemeMode.system,
    this.baseColor = Colors.green,
    this.fontFamily = 'GoogleSansFlex',
    this.selectedCollarId,
  });

  final Locale language;
  final ThemeMode theme;
  final Color baseColor;
  final String fontFamily;
  final String? selectedCollarId;

  static const Object _sentinel = Object();

  AppState copyWith({
    Locale? language,
    ThemeMode? theme,
    Color? baseColor,
    String? fontFamily,
    Object? selectedCollarId = _sentinel,
  }) {
    return AppState(
      language: language ?? this.language,
      theme: theme ?? this.theme,
      baseColor: baseColor ?? this.baseColor,
      fontFamily: fontFamily ?? this.fontFamily,
      selectedCollarId: identical(selectedCollarId, _sentinel)
          ? this.selectedCollarId
          : selectedCollarId as String?,
    );
  }

  @override
  List<Object?> get props => [
    language,
    theme,
    baseColor,
    fontFamily,
    selectedCollarId,
  ];
}
