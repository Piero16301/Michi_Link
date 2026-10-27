import 'package:device_info_plus/device_info_plus.dart';
import 'package:expressive_kit/expressive_kit.dart';
import 'package:package_info_plus/package_info_plus.dart';

abstract class DeviceInfoRepository {
  Future<void> initialize();

  AppDeviceInfo get deviceInfo;

  AppPackageInfo get packageInfo;
}

class MockDeviceInfoRepository implements DeviceInfoRepository {
  @override
  Future<void> initialize() async {}

  @override
  AppDeviceInfo get deviceInfo => const AppDeviceInfo(id: 'mock-device-id');

  @override
  AppPackageInfo get packageInfo => AppPackageInfo(
    appName: 'Michi Link',
    version: '1.0.0',
    buildNumber: '1',
    updateTime: DateTime(2026, 10, 25),
  );
}

class PlusDeviceInfoRepository implements DeviceInfoRepository {
  PlusDeviceInfoRepository({DeviceInfoPlugin? deviceInfoPlugin})
    : _deviceInfoPlugin = deviceInfoPlugin ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _deviceInfoPlugin;
  late AndroidDeviceInfo _androidInfo;
  late PackageInfo _packageInfo;

  @override
  Future<void> initialize() async {
    final (androidInfo, packageInfo) = await (
      _deviceInfoPlugin.androidInfo,
      PackageInfo.fromPlatform(),
    ).wait;
    _androidInfo = androidInfo;
    _packageInfo = packageInfo;
  }

  @override
  AppDeviceInfo get deviceInfo {
    return AppDeviceInfo(
      id: _androidInfo.id,
      versionRelease: _androidInfo.version.release,
      sdkInt: _androidInfo.version.sdkInt,
      securityPatch: _androidInfo.version.securityPatch,
      model: _androidInfo.model,
      brand: _androidInfo.brand,
      isLowRamDevice: _androidInfo.isLowRamDevice,
      isPhysicalDevice: _androidInfo.isPhysicalDevice,
      processor: _androidInfo.hardware,
      physicalRamSize: _androidInfo.physicalRamSize,
      availableRamSize: _androidInfo.availableRamSize,
    );
  }

  @override
  AppPackageInfo get packageInfo {
    return AppPackageInfo(
      appName: _packageInfo.appName,
      version: _packageInfo.version,
      buildNumber: _packageInfo.buildNumber,
      updateTime: _packageInfo.updateTime ?? DateTime.now(),
    );
  }
}
