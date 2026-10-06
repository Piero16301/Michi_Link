import 'package:country_flags/country_flags.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/l10n/l10n.dart';
import 'package:michi_link_mobile/settings/settings.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final currentColorKey = ColorHelper.getColorName(state.baseColor);
        final currentColorName = _getColorName(currentColorKey, l10n);
        final currentThemeName = _getThemeName(state.theme, l10n);
        final currentLanguageName = _getLanguageName(state.language, l10n);

        return Scaffold(
          appBar: ExpressiveTopAppBar(
            centerTitle: false,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: ExpressiveIconButton.circle(
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowLeft01,
                  strokeWidth: 2,
                ),
                onPressed: () => context.pop(),
              ),
            ),
            title: Text(
              l10n.settingsAppBarTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.only(top: 2, bottom: 24),
            children: [
              // Sección: Aspecto (Tema, Color base y Fuente agrupados)
              ExpressiveCardGroup(
                title: l10n.settingsAppearanceTitle,
                children: [
                  ExpressiveListTile(
                    leading: const ExpressiveBadge(
                      backgroundColor: Color(0xFF6750A4),
                      foregroundColor: Colors.white,
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedMoon02,
                        strokeWidth: 2,
                      ),
                    ),
                    title: Text(l10n.settingsThemeTitle),
                    subtitle: Text(currentThemeName),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(
                          icon: _getThemeIcon(state.theme),
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowRight01,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    onTap: () => _showThemePickerModal(context, state),
                  ),
                  ExpressiveListTile(
                    leading: const ExpressiveBadge(
                      backgroundColor: Color(0xFFE06D53),
                      foregroundColor: Colors.white,
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedPaintBoard,
                        strokeWidth: 2,
                      ),
                    ),
                    title: Text(l10n.settingsBaseColorTitle),
                    subtitle: Text(currentColorName),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: state.baseColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowRight01,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    onTap: () => _showColorPickerModal(context, state),
                  ),
                  ExpressiveListTile(
                    leading: const ExpressiveBadge(
                      backgroundColor: Color(0xFF1E88E5),
                      foregroundColor: Colors.white,
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedTextFont,
                        strokeWidth: 2,
                      ),
                    ),
                    title: Text(l10n.settingsFontTitle),
                    subtitle: Text(
                      state.fontFamily,
                      style: TextStyle(fontFamily: state.fontFamily),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 24,
                          child: Center(
                            child: Text(
                              'Aa',
                              style: TextStyle(
                                fontFamily: state.fontFamily,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowRight01,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    onTap: () => _showFontPickerModal(context, state),
                  ),
                ],
              ),

              // Sección: Idioma
              ExpressiveCardGroup(
                title: l10n.settingsLanguageTitle,
                children: [
                  ExpressiveListTile(
                    leading: const ExpressiveBadge(
                      backgroundColor: Color(0xFF00ACC1),
                      foregroundColor: Colors.white,
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedGlobe02,
                        strokeWidth: 2,
                      ),
                    ),
                    title: Text(l10n.settingsLanguageTitle),
                    subtitle: Text(currentLanguageName),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CountryFlag.fromLanguageCode(
                          state.language.languageCode,
                          theme: const ImageTheme(
                            width: 24,
                            height: 24,
                            shape: RoundedRectangle(6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowRight01,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    onTap: () => _showLanguagePickerModal(context, state),
                  ),
                ],
              ),

              // Sección: Información de la aplicación
              const SettingsAppSpecs(),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showSettingsModal({
    required BuildContext context,
    required String title,
    required List<Widget> Function(BuildContext modalContext) itemsBuilder,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sheetHeight =
        MediaQuery.of(context).size.height *
        AppVariables.modalBottomSheetHeightPct;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (modalContext) {
        return SizedBox(
          height: sheetHeight,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.4,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: itemsBuilder(modalContext),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showThemePickerModal(BuildContext context, AppState state) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final options = [
      (ThemeMode.light, l10n.settingsThemeLight, HugeIcons.strokeRoundedSun03),
      (ThemeMode.dark, l10n.settingsThemeDark, HugeIcons.strokeRoundedMoon02),
      (
        ThemeMode.system,
        l10n.settingsThemeSystem,
        HugeIcons.strokeRoundedComputerPhoneSync,
      ),
    ];

    _showSettingsModal(
      context: context,
      title: l10n.settingsThemeTitle,
      itemsBuilder: (modalContext) => options.map((option) {
        final mode = option.$1;
        final title = option.$2;
        final icon = option.$3;
        final isSelected = state.theme == mode;

        return ListTile(
          leading: HugeIcon(
            icon: icon,
            color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            strokeWidth: 2,
          ),
          title: Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
          trailing: isSelected
              ? HugeIcon(
                  icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                  color: colorScheme.primary,
                  strokeWidth: 2,
                )
              : null,
          onTap: () {
            context.read<AppCubit>().changeTheme(theme: mode);
            Navigator.pop(modalContext);
          },
        );
      }).toList(),
    );
  }

  void _showColorPickerModal(BuildContext context, AppState state) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    _showSettingsModal(
      context: context,
      title: l10n.settingsBaseColorTitle,
      itemsBuilder: (modalContext) => ColorHelper.colorMap.entries.map((entry) {
        final isSelected = entry.value == state.baseColor;
        return ListTile(
          leading: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: entry.value,
              shape: BoxShape.circle,
            ),
          ),
          title: Text(_getColorName(entry.key, l10n)),
          trailing: isSelected
              ? HugeIcon(
                  icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                  color: colorScheme.primary,
                  strokeWidth: 2,
                )
              : null,
          onTap: () {
            context.read<AppCubit>().changeBaseColor(baseColor: entry.value);
            Navigator.pop(modalContext);
          },
        );
      }).toList(),
    );
  }

  void _showFontPickerModal(BuildContext context, AppState state) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    _showSettingsModal(
      context: context,
      title: l10n.settingsFontTitle,
      itemsBuilder: (modalContext) => AppVariables.availableFonts.entries.map((
        entry,
      ) {
        final isSelected = entry.value == state.fontFamily;
        return ListTile(
          leading: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              'Aa',
              style: TextStyle(
                fontFamily: entry.value,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          title: Text(
            entry.key,
            style: TextStyle(
              fontFamily: entry.value,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          trailing: isSelected
              ? HugeIcon(
                  icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                  color: colorScheme.primary,
                  strokeWidth: 2,
                )
              : null,
          onTap: () {
            context.read<AppCubit>().changeFontFamily(fontFamily: entry.value);
            Navigator.pop(modalContext);
          },
        );
      }).toList(),
    );
  }

  void _showLanguagePickerModal(BuildContext context, AppState state) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    _showSettingsModal(
      context: context,
      title: l10n.selectLanguage,
      itemsBuilder: (modalContext) => AppVariables.supportedLocales.map((
        locale,
      ) {
        final isSelected = locale.languageCode == state.language.languageCode;
        return ListTile(
          leading: CountryFlag.fromLanguageCode(
            locale.languageCode,
            theme: const ImageTheme(
              width: 28,
              height: 28,
              shape: RoundedRectangle(6),
            ),
          ),
          title: Text(_getLanguageName(locale, l10n)),
          trailing: isSelected
              ? HugeIcon(
                  icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                  color: colorScheme.primary,
                  strokeWidth: 2,
                )
              : null,
          onTap: () {
            context.read<AppCubit>().changeLanguage(language: locale);
            Navigator.pop(modalContext);
          },
        );
      }).toList(),
    );
  }

  String _getLanguageName(Locale locale, AppLocalizations l10n) {
    if (locale.languageCode ==
        AppVariables.supportedLocales.first.languageCode) {
      return l10n.settingsLanguageEnglish;
    } else if (locale.languageCode ==
        AppVariables.supportedLocales.last.languageCode) {
      return l10n.settingsLanguageSpanish;
    }
    return locale.languageCode;
  }

  String _getThemeName(ThemeMode themeMode, AppLocalizations l10n) {
    switch (themeMode) {
      case ThemeMode.light:
        return l10n.settingsThemeLight;
      case ThemeMode.dark:
        return l10n.settingsThemeDark;
      case ThemeMode.system:
        return l10n.settingsThemeSystem;
    }
  }

  List<List<dynamic>> _getThemeIcon(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return HugeIcons.strokeRoundedSun03;
      case ThemeMode.dark:
        return HugeIcons.strokeRoundedMoon02;
      case ThemeMode.system:
        return HugeIcons.strokeRoundedComputerPhoneSync;
    }
  }

  String _getColorName(String colorKey, AppLocalizations l10n) {
    switch (colorKey) {
      case 'RED':
        return l10n.settingsColorRed;
      case 'PINK':
        return l10n.settingsColorPink;
      case 'PURPLE':
        return l10n.settingsColorPurple;
      case 'DEEP_PURPLE':
        return l10n.settingsColorDeepPurple;
      case 'INDIGO':
        return l10n.settingsColorIndigo;
      case 'BLUE':
        return l10n.settingsColorBlue;
      case 'LIGHT_BLUE':
        return l10n.settingsColorLightBlue;
      case 'CYAN':
        return l10n.settingsColorCyan;
      case 'TEAL':
        return l10n.settingsColorTeal;
      case 'GREEN':
        return l10n.settingsColorGreen;
      case 'LIGHT_GREEN':
        return l10n.settingsColorLightGreen;
      case 'LIME':
        return l10n.settingsColorLime;
      case 'YELLOW':
        return l10n.settingsColorYellow;
      case 'AMBER':
        return l10n.settingsColorAmber;
      case 'ORANGE':
        return l10n.settingsColorOrange;
      case 'DEEP_ORANGE':
        return l10n.settingsColorDeepOrange;
      case 'BROWN':
        return l10n.settingsColorBrown;
      case 'GREY':
        return l10n.settingsColorGrey;
      case 'BLUE_GREY':
        return l10n.settingsColorBlueGrey;
      default:
        return colorKey;
    }
  }
}
