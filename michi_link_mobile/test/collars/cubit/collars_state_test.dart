import 'package:flutter_test/flutter_test.dart';
import 'package:michi_link_mobile/collars/collars.dart';

void main() {
  group('CollarsState', () {
    test('supports value comparisons', () {
      expect(const CollarsState(), equals(const CollarsState()));
    });

    test('copyWith updates collars list', () {
      const state = CollarsState();
      final updated = state.copyWith(collars: ['COLLAR_1', 'COLLAR_2']);

      expect(updated.collars, ['COLLAR_1', 'COLLAR_2']);
      expect(updated.props, [
        ['COLLAR_1', 'COLLAR_2'],
      ]);
    });

    test('copyWith preserves current collars when null passed', () {
      const state = CollarsState(collars: ['COLLAR_1']);
      final updated = state.copyWith();
      expect(updated.collars, ['COLLAR_1']);
    });
  });
}
