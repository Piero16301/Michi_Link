import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MockDeviceInfoPlugin extends Mock implements DeviceInfoPlugin {}

class MockAndroidDeviceInfo extends Mock implements AndroidDeviceInfo {}

class MockAndroidBuildVersion extends Mock implements AndroidBuildVersion {}

void main() {
  group('DeviceInfoRepository', () {
    test('MockDeviceInfoRepository returns expected values', () async {
      final repo = MockDeviceInfoRepository();
      await expectLater(repo.initialize(), completes);
      expect(repo.deviceInfo.id, 'mock-device-id');
      expect(repo.packageInfo.appName, 'Michi Link');
      expect(repo.packageInfo.version, '1.0.0');
      expect(repo.packageInfo.buildNumber, '1');
      expect(repo.packageInfo.updateTime, DateTime(2026, 10, 25));
    });

    group('PlusDeviceInfoRepository', () {
      late MockDeviceInfoPlugin mockPlugin;
      late PlusDeviceInfoRepository repo;

      setUp(() {
        mockPlugin = MockDeviceInfoPlugin();
        repo = PlusDeviceInfoRepository(deviceInfoPlugin: mockPlugin);
        PackageInfo.setMockInitialValues(
          appName: 'Michi Link Test',
          packageName: 'com.pmorales.michi.link',
          version: '2.0.0',
          buildNumber: '42',
          buildSignature: '',
        );
      });

      test(
        'initializes and maps deviceInfo and packageInfo correctly',
        () async {
          final androidInfo = MockAndroidDeviceInfo();
          final version = MockAndroidBuildVersion();

          when(() => version.release).thenReturn('14');
          when(() => version.sdkInt).thenReturn(34);
          when(() => version.securityPatch).thenReturn('2026-10-01');

          when(() => androidInfo.id).thenReturn('android-device-123');
          when(() => androidInfo.version).thenReturn(version);
          when(() => androidInfo.model).thenReturn('Pixel 9');
          when(() => androidInfo.brand).thenReturn('Google');
          when(() => androidInfo.isLowRamDevice).thenReturn(false);
          when(() => androidInfo.isPhysicalDevice).thenReturn(true);
          when(() => androidInfo.hardware).thenReturn('tensor-g4');
          when(() => androidInfo.physicalRamSize).thenReturn(12000000000);
          when(() => androidInfo.availableRamSize).thenReturn(8000000000);

          when(
            () => mockPlugin.androidInfo,
          ).thenAnswer((_) async => androidInfo);

          await repo.initialize();

          expect(repo.deviceInfo.id, 'android-device-123');
          expect(repo.deviceInfo.versionRelease, '14');
          expect(repo.deviceInfo.sdkInt, 34);
          expect(repo.deviceInfo.securityPatch, '2026-10-01');
          expect(repo.deviceInfo.model, 'Pixel 9');
          expect(repo.deviceInfo.brand, 'Google');
          expect(repo.deviceInfo.isLowRamDevice, isFalse);
          expect(repo.deviceInfo.isPhysicalDevice, isTrue);
          expect(repo.deviceInfo.processor, 'tensor-g4');
          expect(repo.deviceInfo.physicalRamSize, 12000000000);
          expect(repo.deviceInfo.availableRamSize, 8000000000);

          expect(repo.packageInfo.appName, 'Michi Link Test');
          expect(repo.packageInfo.version, '2.0.0');
          expect(repo.packageInfo.buildNumber, '42');
          expect(repo.packageInfo.updateTime, isNotNull);
        },
      );

      test('instantiates with default plugin when omitted', () {
        expect(PlusDeviceInfoRepository.new, returnsNormally);
      });
    });
  });
}
