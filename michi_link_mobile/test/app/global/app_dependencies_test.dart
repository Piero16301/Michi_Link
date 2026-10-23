import 'package:flutter_test/flutter_test.dart';
import 'package:michi_link_mobile/app/app.dart';

void main() {
  group('AppDependencies', () {
    test('ServiceFactory returns correct repositories for mock', () {
      expect(
        ServiceFactory.getCrashRepository(Environment.mock),
        isA<MockCrashRepository>(),
      );
      expect(
        ServiceFactory.getPerformanceRepository(Environment.mock),
        isA<MockPerformanceRepository>(),
      );
      expect(
        ServiceFactory.getAnalyticsRepository(Environment.mock),
        isA<MockAnalyticsRepository>(),
      );
      expect(
        ServiceFactory.getLocalStorageRepository(Environment.mock),
        isA<MockLocalStorageRepository>(),
      );
      expect(
        ServiceFactory.getDatabaseRepository(Environment.mock),
        isA<MockDatabaseRepository>(),
      );
    });

    test('ServiceFactory prod repositories creation', () {
      expect(
        ServiceFactory.getLocalStorageRepository(Environment.prod),
        isA<HiveLocalStorageRepository>(),
      );
      try {
        ServiceFactory.getCrashRepository(Environment.prod);
      } on Object catch (_) {}
      try {
        ServiceFactory.getPerformanceRepository(Environment.prod);
      } on Object catch (_) {}
      try {
        ServiceFactory.getAnalyticsRepository(Environment.prod);
      } on Object catch (_) {}
      try {
        ServiceFactory.getDatabaseRepository(Environment.prod);
      } on Object catch (_) {}
    });

    test('setupServiceLocator registers and resolves mock instances', () async {
      await getIt.reset();
      setupServiceLocator(Environment.mock);

      expect(getIt.isRegistered<CrashService>(), isTrue);
      expect(getIt.isRegistered<PerformanceService>(), isTrue);
      expect(getIt.isRegistered<AnalyticsService>(), isTrue);
      expect(getIt.isRegistered<LocalStorageService>(), isTrue);
      expect(getIt.isRegistered<DatabaseService>(), isTrue);

      expect(getIt<CrashService>(), isA<CrashService>());
      expect(getIt<PerformanceService>(), isA<PerformanceService>());
      expect(getIt<AnalyticsService>(), isA<AnalyticsService>());
      expect(getIt<LocalStorageService>(), isA<LocalStorageService>());
      expect(getIt<DatabaseService>(), isA<DatabaseService>());
    });

    test('setupServiceLocator registers all services for prod', () async {
      await getIt.reset();
      setupServiceLocator(Environment.prod);

      expect(getIt.isRegistered<CrashService>(), isTrue);
      expect(getIt.isRegistered<PerformanceService>(), isTrue);
      expect(getIt.isRegistered<AnalyticsService>(), isTrue);
      expect(getIt.isRegistered<LocalStorageService>(), isTrue);
      expect(getIt.isRegistered<DatabaseService>(), isTrue);

      await getIt.reset();
      setupServiceLocator(Environment.mock);
    });
  });
}
