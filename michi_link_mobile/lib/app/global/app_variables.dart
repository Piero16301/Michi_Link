import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

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
