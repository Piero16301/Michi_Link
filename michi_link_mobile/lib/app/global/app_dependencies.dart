import 'package:get_it/get_it.dart';
import 'package:michi_link_mobile/app/app.dart';

final GetIt getIt = GetIt.instance;

void setupServiceLocator(Environment env) {
  getIt
    // 1. Infraestructura y Telemetría (Base de todo)
    ..registerLazySingleton<CrashService>(
      () =>
          CrashService(crashRepository: ServiceFactory.getCrashRepository(env)),
    )
    ..registerLazySingleton<PerformanceService>(
      () => PerformanceService(
        performanceRepository: ServiceFactory.getPerformanceRepository(env),
      ),
    )
    ..registerLazySingleton<AnalyticsService>(
      () => AnalyticsService(
        analyticsRepository: ServiceFactory.getAnalyticsRepository(env),
      ),
    )
    // 2. Configuración y Almacenamiento Local
    ..registerLazySingleton<LocalStorageService>(
      () => LocalStorageService(
        localStorageRepository: ServiceFactory.getLocalStorageRepository(env),
      ),
    )
    // 3. Servicios de Datos / Externos
    ..registerLazySingleton<DatabaseService>(
      () => DatabaseService(
        databaseRepository: ServiceFactory.getDatabaseRepository(env),
      ),
    )
    ..registerLazySingleton<DeviceInfoService>(
      () => DeviceInfoService(
        deviceInfoRepository: ServiceFactory.getDeviceInfoRepository(env),
      ),
    )
    ..registerLazySingleton<NotificationService>(
      () => NotificationService(
        notificationRepository: ServiceFactory.getNotificationRepository(env),
        databaseService: getIt<DatabaseService>(),
        deviceInfoService: getIt<DeviceInfoService>(),
        localStorageService: getIt<LocalStorageService>(),
        performanceService: getIt<PerformanceService>(),
        crashService: getIt<CrashService>(),
        analyticsService: getIt<AnalyticsService>(),
      ),
    );
}

enum Environment { mock, prod }

class ServiceFactory {
  static CrashRepository getCrashRepository(Environment env) {
    switch (env) {
      case Environment.mock:
        return MockCrashRepository();
      case Environment.prod:
        return CrashlyticsCrashRepository();
    }
  }

  static PerformanceRepository getPerformanceRepository(Environment env) {
    switch (env) {
      case Environment.mock:
        return MockPerformanceRepository();
      case Environment.prod:
        return FirebasePerformanceRepository();
    }
  }

  static AnalyticsRepository getAnalyticsRepository(Environment env) {
    switch (env) {
      case Environment.mock:
        return MockAnalyticsRepository();
      case Environment.prod:
        return FirebaseAnalyticsRepository();
    }
  }

  static LocalStorageRepository getLocalStorageRepository(Environment env) {
    switch (env) {
      case Environment.mock:
        return MockLocalStorageRepository();
      case Environment.prod:
        return HiveLocalStorageRepository();
    }
  }

  static DatabaseRepository getDatabaseRepository(Environment env) {
    switch (env) {
      case Environment.mock:
        return MockDatabaseRepository();
      case Environment.prod:
        return FirestoreDatabaseRepository();
    }
  }

  static DeviceInfoRepository getDeviceInfoRepository(Environment env) {
    switch (env) {
      case Environment.mock:
        return MockDeviceInfoRepository();
      case Environment.prod:
        return PlusDeviceInfoRepository();
    }
  }

  static NotificationRepository getNotificationRepository(Environment env) {
    switch (env) {
      case Environment.mock:
        return MockNotificationRepository();
      case Environment.prod:
        return FirebaseNotificationRepository();
    }
  }
}
