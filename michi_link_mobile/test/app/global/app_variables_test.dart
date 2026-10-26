import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';

import '../../helpers/helpers.dart';

void main() {
  group('AppVariables', () {
    test('constants have expected values', () {
      expect(AppVariables.appName, 'Michi Link');
      expect(AppVariables.logoNoBgDark, contains('logo-no-bg-dark.png'));
      expect(AppVariables.logoNoBgLight, contains('logo-no-bg-light.png'));
      expect(AppVariables.minDate, DateTime(2020));
      expect(AppVariables.tabletMaxWidth, 500.0);
      expect(AppVariables.tabletMaxHeight, 400.0);
      expect(AppVariables.mobileChartMaxHeight, 340.0);
      expect(AppVariables.webChartMaxHeight, 480.0);
      expect(AppVariables.paginationSize, 10);
      expect(AppVariables.modalBottomSheetMaxHeightPct, 0.72);
      expect(AppVariables.modalBottomSheetKeyboardMaxHeightPct, 0.85);
      expect(AppVariables.mapFocusZoom, 19.0);
      expect(AppVariables.snackBarDuration, const Duration(seconds: 5));
      expect(AppVariables.animationDuration, const Duration(milliseconds: 400));
      expect(
        AppVariables.formatDate.format(DateTime(2026, 1, 15)),
        '15/01/2026',
      );
    });
  });

  group('SnackBarType', () {
    test('getters return correct boolean flags', () {
      expect(SnackBarType.success.isSuccess, isTrue);
      expect(SnackBarType.success.isError, isFalse);
      expect(SnackBarType.success.isWarning, isFalse);
      expect(SnackBarType.success.isInfo, isFalse);

      expect(SnackBarType.error.isError, isTrue);
      expect(SnackBarType.error.isSuccess, isFalse);

      expect(SnackBarType.warning.isWarning, isTrue);
      expect(SnackBarType.warning.isSuccess, isFalse);

      expect(SnackBarType.info.isInfo, isTrue);
      expect(SnackBarType.info.isSuccess, isFalse);
    });
  });

  group('CatBreed', () {
    test('unspecified is defaultBreed', () {
      expect(CatBreed.unspecified, CatBreed.defaultBreed);
    });

    test('getters return correct boolean flags', () {
      expect(CatBreed.defaultBreed.isDefault, isTrue);
      expect(CatBreed.europeanOrangeWhite.isEuropeanOrangeWhite, isTrue);
      expect(CatBreed.persian.isPersian, isTrue);
      expect(CatBreed.siamese.isSiamese, isTrue);
      expect(CatBreed.maineCoon.isMaineCoon, isTrue);
      expect(CatBreed.ragdoll.isRagdoll, isTrue);
      expect(CatBreed.britishShorthair.isBritishShorthair, isTrue);
      expect(CatBreed.bengal.isBengal, isTrue);
      expect(CatBreed.russianBlue.isRussianBlue, isTrue);
      expect(CatBreed.sphynx.isSphynx, isTrue);
    });

    test('assetPath returns non-empty path for each breed', () {
      for (final breed in CatBreed.values) {
        expect(breed.assetPath, startsWith('assets/cats/'));
        expect(breed.assetPath, endsWith('.svg'));
      }
    });

    testWidgets('displayName returns translated string for each breed', (
      tester,
    ) async {
      await tester.pumpApp(
        Builder(
          builder: (context) {
            for (final breed in CatBreed.values) {
              final name = breed.displayName(context);
              expect(name, isNotEmpty);
            }
            return const SizedBox();
          },
        ),
      );
    });

    testWidgets('svgPicture renders widget', (tester) async {
      await tester.pumpApp(
        CatBreed.defaultBreed.svgPicture(width: 50, height: 50),
      );
      expect(
        find.byType(CatBreed.defaultBreed.svgPicture().runtimeType),
        findsOneWidget,
      );
    });
  });
}
