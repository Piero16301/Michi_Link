import 'package:flutter_test/flutter_test.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:mocktail/mocktail.dart';

class MockCrashRepositoryInternal extends Mock implements CrashRepository {}

void main() {
  group('CrashService', () {
    late MockCrashRepositoryInternal repository;
    late CrashService service;

    setUp(() {
      repository = MockCrashRepositoryInternal();
      service = CrashService(crashRepository: repository);
    });

    test('recordError delegates to repository', () {
      final exception = Exception('Test');
      final stackTrace = StackTrace.current;

      when(
        () => repository.recordError(
          any<dynamic>(),
          any<StackTrace?>(),
          reason: any<dynamic>(named: 'reason'),
          information: any<Iterable<Object>>(named: 'information'),
          fatal: any<bool?>(named: 'fatal'),
        ),
      ).thenReturn(null);

      service.recordError(
        exception,
        stackTrace,
        reason: 'Testing',
        information: ['info'],
        fatal: true,
      );

      verify(
        () => repository.recordError(
          exception,
          stackTrace,
          reason: 'Testing',
          information: ['info'],
          fatal: true,
        ),
      ).called(1);
    });

    test('log delegates to repository', () {
      when(() => repository.log(any())).thenReturn(null);

      service.log('A log message');

      verify(() => repository.log('A log message')).called(1);
    });

    test('setCustomKey delegates to repository', () {
      when(() => repository.setCustomKey(any(), any())).thenReturn(null);

      service.setCustomKey('user_type', 'tester');

      verify(() => repository.setCustomKey('user_type', 'tester')).called(1);
    });
  });
}
