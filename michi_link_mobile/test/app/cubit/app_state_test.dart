import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';

void main() {
  group('AppState', () {
    test('supports value equality', () {
      expect(const AppState(), equals(const AppState()));
    });

    test('copyWith updates specified fields', () {
      const state = AppState();
      final updated = state.copyWith(
        language: const Locale('fr'),
        theme: ThemeMode.dark,
        baseColor: Colors.red,
        fontFamily: 'Inter',
        selectedCollarId: 'collar_1',
      );

      expect(updated.language, const Locale('fr'));
      expect(updated.theme, ThemeMode.dark);
      expect(updated.baseColor, Colors.red);
      expect(updated.fontFamily, 'Inter');
      expect(updated.selectedCollarId, 'collar_1');
    });

    test('copyWith allows setting selectedCollarId to null', () {
      const state = AppState(selectedCollarId: 'collar_1');
      final updated = state.copyWith(selectedCollarId: null);
      expect(updated.selectedCollarId, isNull);
    });

    test('copyWith preserves values when nothing passed', () {
      const state = AppState(selectedCollarId: 'collar_1');
      final updated = state.copyWith();
      expect(updated, equals(state));
    });
  });
}
