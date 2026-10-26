import 'package:expressive_kit/expressive_kit.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:mocktail/mocktail.dart';

class MockDeviceInfoRepositoryInternal extends Mock
    implements DeviceInfoRepository {}

class MockPerformanceService extends Mock implements PerformanceService {}

class MockTrace extends Mock implements Trace {}

void main() {
  group('DeviceInfoService', () {
    late MockDeviceInfoRepositoryInternal repository;
    late MockPerformanceService performance;
    late DeviceInfoService service;

    setUp(() async {
      repository = MockDeviceInfoRepositoryInternal();
      performance = MockPerformanceService();

      if (getIt.isRegistered<PerformanceService>()) {
        await getIt.unregister<PerformanceService>();
      }
      getIt.registerSingleton<PerformanceService>(performance);

      service = DeviceInfoService(deviceInfoRepository: repository);
    });

    tearDown(() async {
      if (getIt.isRegistered<PerformanceService>()) {
        await getIt.unregister<PerformanceService>();
      }
    });

    test(
      'initialize starts trace, delegates to repository, and stops trace',
      () async {
        final trace = MockTrace();
        when(
          () => performance.startTrace('device_info_service_initialization'),
        ).thenReturn(trace);
        when(() => repository.initialize()).thenAnswer((_) async {});
        when(() => performance.stopTrace(trace)).thenReturn(null);

        await service.initialize();

        verify(
          () => performance.startTrace('device_info_service_initialization'),
        ).called(1);
        verify(() => repository.initialize()).called(1);
        verify(() => performance.stopTrace(trace)).called(1);
      },
    );

    test('deviceInfo delegates to repository', () {
      const expectedInfo = AppDeviceInfo(id: 'device-456');
      when(() => repository.deviceInfo).thenReturn(expectedInfo);

      expect(service.deviceInfo, equals(expectedInfo));
      verify(() => repository.deviceInfo).called(1);
    });

    test('packageInfo delegates to repository', () {
      final expectedPkg = AppPackageInfo(
        appName: 'Michi Test',
        version: '1.2.3',
        buildNumber: '99',
        updateTime: DateTime(2026, 10, 26),
      );
      when(() => repository.packageInfo).thenReturn(expectedPkg);

      expect(service.packageInfo, equals(expectedPkg));
      verify(() => repository.packageInfo).called(1);
    });
  });
}
