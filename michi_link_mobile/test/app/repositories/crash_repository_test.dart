import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseCrashlytics extends Mock implements FirebaseCrashlytics {}

void main() {
  group('CrashRepository', () {
    test('MockCrashRepository methods execute without error', () {
      final repo = MockCrashRepository();
      expect(() => repo.log('msg'), returnsNormally);
      expect(() => repo.setCustomKey('key', 'val'), returnsNormally);
      expect(
        () => repo.recordError(Exception(), null, reason: 'r', fatal: false),
        returnsNormally,
      );
    });

    test('CrashlyticsCrashRepository delegates methods', () {
      final crashlytics = MockFirebaseCrashlytics();
      final repo = CrashlyticsCrashRepository(crashlytics: crashlytics);

      when(() => crashlytics.log(any())).thenAnswer((_) async {});
      when(
        () => crashlytics.setCustomKey(any(), any()),
      ).thenAnswer((_) async {});
      when(
        () => crashlytics.recordError(
          any<dynamic>(),
          any<StackTrace?>(),
          reason: any<dynamic>(named: 'reason'),
          information: any<Iterable<Object>>(named: 'information'),
          fatal: any<bool>(named: 'fatal'),
        ),
      ).thenAnswer((_) async {});

      repo.log('hello');
      verify(() => crashlytics.log('hello')).called(1);

      repo.setCustomKey('tier', 'free');
      verify(() => crashlytics.setCustomKey('tier', 'free')).called(1);

      final exp = Exception('oops');
      repo.recordError(exp, null, reason: 'failed', fatal: true);
      verify(
        () => crashlytics.recordError(exp, null, reason: 'failed', fatal: true),
      ).called(1);
    });
  });
}
