import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:michi_link_mobile/app/app.dart';

void main() {
  group('AppMapStyles', () {
    test('can be instantiated', () {
      // Intentionally instantiated at runtime to verify coverage.
      // ignore: prefer_const_constructors
      final styles = AppMapStyles();
      expect(styles, isA<AppMapStyles>());
    });

    test('darkM3 is valid JSON', () {
      final parsed = jsonDecode(AppMapStyles.darkM3);
      expect(parsed, isA<List<dynamic>>());
      expect((parsed as List<dynamic>).isNotEmpty, isTrue);
    });

    test('lightM3 is valid JSON', () {
      final parsed = jsonDecode(AppMapStyles.lightM3);
      expect(parsed, isA<List<dynamic>>());
      expect((parsed as List<dynamic>).isNotEmpty, isTrue);
    });
  });
}
