import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebasePerformance extends Mock implements FirebasePerformance {}

class MockPerformanceTrace extends Mock implements Trace {}

void main() {
  group('PerformanceRepository', () {
    test('MockPerformanceRepository throws UnimplementedError', () {
      final repo = MockPerformanceRepository();
      expect(() => repo.startTrace('trace'), throwsUnimplementedError);
      expect(
        () => repo.stopTrace(MockPerformanceTrace()),
        throwsUnimplementedError,
      );
    });

    test('FirebasePerformanceRepository starts and stops trace', () async {
      final performance = MockFirebasePerformance();
      final trace = MockPerformanceTrace();
      final repo = FirebasePerformanceRepository(performance: performance);

      when(() => performance.newTrace('test_trace')).thenReturn(trace);
      when(trace.start).thenAnswer((_) async {});
      when(trace.stop).thenAnswer((_) async {});

      final createdTrace = repo.startTrace('test_trace');
      expect(createdTrace, equals(trace));
      verify(() => performance.newTrace('test_trace')).called(1);
      verify(trace.start).called(1);

      repo.stopTrace(createdTrace);
      await Future<void>.delayed(Duration.zero);
      verify(trace.stop).called(1);
    });
  });
}
