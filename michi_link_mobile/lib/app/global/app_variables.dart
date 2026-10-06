import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/l10n/l10n.dart';

class AppVariables {
  static const String appName = 'Michi Link';

  @visibleForTesting
  static bool useTestFonts = false;

  static const Color defaultBaseColor = Colors.green;
  static const String defaultFontFamily = 'GoogleSansFlex';

  static const logoNoBgDark = 'assets/images/logo-no-bg-dark.png';
  static const logoNoBgLight = 'assets/images/logo-no-bg-light.png';

  static final minDate = DateTime(2020);
  static const tabletMaxWidth = 500.0;
  static const tabletMaxHeight = 400.0;
  static const mobileChartMaxHeight = 340.0;
  static const webChartMaxHeight = 480.0;
  static const paginationSize = 10;
  static const modalBottomSheetHeightPct = 0.6;

  static const animationDuration = Duration(milliseconds: 400);
  static const snackBarDuration = Duration(seconds: 5);

  static final DateFormat formatDate = DateFormat('dd/MM/yyyy');
  static const String nameRegExp =
      r'^(?=.{2,}$)[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ]+(?: [a-zA-ZáéíóúÁÉÍÓÚñÑüÜ]+)*$';

  static Map<String, String> availableFonts = getAvailableFonts();

  static Map<String, String> getAvailableFonts() {
    return {
      'Google Sans Flex': 'GoogleSansFlex',
      'Merriweather': 'Merriweather',
      'Montserrat': 'Montserrat',
      'Nunito': 'Nunito',
      'Open Sans': 'OpenSans',
      'Orbitron': 'Orbitron',
      'Playfair Display': 'PlayfairDisplay',
      'Roboto': 'Roboto',
      'Source Code Pro': 'SourceCodePro',
    };
  }

  static const collarsCollection = 'categories';

  static const List<Locale> supportedLocales = [
    Locale('en', 'US'),
    Locale('es', 'ES'),
  ];
}

enum SnackBarType {
  success,
  error,
  warning,
  info;

  bool get isSuccess => this == SnackBarType.success;
  bool get isError => this == SnackBarType.error;
  bool get isWarning => this == SnackBarType.warning;
  bool get isInfo => this == SnackBarType.info;
}

enum CatBreed {
  defaultBreed,
  europeanOrangeWhite,
  persian,
  siamese,
  maineCoon,
  ragdoll,
  britishShorthair,
  bengal,
  russianBlue,
  sphynx;

  static const CatBreed unspecified = CatBreed.defaultBreed;

  String displayName(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case CatBreed.defaultBreed:
        return l10n.catBreedDefault;
      case CatBreed.europeanOrangeWhite:
        return l10n.catBreedEuropeanOrangeWhite;
      case CatBreed.persian:
        return l10n.catBreedPersian;
      case CatBreed.siamese:
        return l10n.catBreedSiamese;
      case CatBreed.maineCoon:
        return l10n.catBreedMaineCoon;
      case CatBreed.ragdoll:
        return l10n.catBreedRagdoll;
      case CatBreed.britishShorthair:
        return l10n.catBreedBritishShorthair;
      case CatBreed.bengal:
        return l10n.catBreedBengal;
      case CatBreed.russianBlue:
        return l10n.catBreedRussianBlue;
      case CatBreed.sphynx:
        return l10n.catBreedSphynx;
    }
  }

  String get assetPath {
    switch (this) {
      case CatBreed.defaultBreed:
        return 'assets/cats/default_cat.svg';
      case CatBreed.europeanOrangeWhite:
        return 'assets/cats/european_orange_white.svg';
      case CatBreed.persian:
        return 'assets/cats/persian.svg';
      case CatBreed.siamese:
        return 'assets/cats/siamese.svg';
      case CatBreed.maineCoon:
        return 'assets/cats/maine_coon.svg';
      case CatBreed.ragdoll:
        return 'assets/cats/ragdoll.svg';
      case CatBreed.britishShorthair:
        return 'assets/cats/british_shorthair.svg';
      case CatBreed.bengal:
        return 'assets/cats/bengal.svg';
      case CatBreed.russianBlue:
        return 'assets/cats/russian_blue.svg';
      case CatBreed.sphynx:
        return 'assets/cats/sphynx.svg';
    }
  }

  bool get isDefault => this == CatBreed.defaultBreed;
  bool get isEuropeanOrangeWhite => this == CatBreed.europeanOrangeWhite;
  bool get isPersian => this == CatBreed.persian;
  bool get isSiamese => this == CatBreed.siamese;
  bool get isMaineCoon => this == CatBreed.maineCoon;
  bool get isRagdoll => this == CatBreed.ragdoll;
  bool get isBritishShorthair => this == CatBreed.britishShorthair;
  bool get isBengal => this == CatBreed.bengal;
  bool get isRussianBlue => this == CatBreed.russianBlue;
  bool get isSphynx => this == CatBreed.sphynx;

  Widget svgPicture({
    Key? key,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    ColorFilter? colorFilter,
    AlignmentGeometry alignment = Alignment.center,
  }) {
    return SvgPicture.asset(
      assetPath,
      key: key,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      colorFilter: colorFilter,
    );
  }
}
