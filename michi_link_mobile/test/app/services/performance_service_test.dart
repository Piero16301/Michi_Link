import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:mocktail/mocktail.dart';

class MockPerformanceRepositoryInternal extends Mock
    implements PerformanceRepository {}

class MockTrace extends Mock implements Trace {}

void main() {
  group('PerformanceService', () {
    late MockPerformanceRepositoryInternal repository;
    late PerformanceService service;

    setUp(() {
      repository = MockPerformanceRepositoryInternal();
      service = PerformanceService(performanceRepository: repository);
    });

    test('startTrace and stopTrace delegate to repository', () {
      final trace = MockTrace();
      when(() => repository.startTrace('my_trace')).thenReturn(trace);
      when(() => repository.stopTrace(trace)).thenReturn(null);

      final returnedTrace = service.startTrace('my_trace');
      expect(returnedTrace, equals(trace));
      verify(() => repository.startTrace('my_trace')).called(1);

      service.stopTrace(trace);
      verify(() => repository.stopTrace(trace)).called(1);
    });
  });
}
