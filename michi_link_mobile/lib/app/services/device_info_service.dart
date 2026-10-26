import 'dart:async';

import 'package:expressive_kit/expressive_kit.dart';
import 'package:michi_link_mobile/app/app.dart';

class DeviceInfoService {
  DeviceInfoService({required this._deviceInfoRepository});

  final DeviceInfoRepository _deviceInfoRepository;

  Future<void> initialize() async {
    final performance = getIt<PerformanceService>();
    final trace = performance.startTrace('device_info_service_initialization');
    await _deviceInfoRepository.initialize();
    performance.stopTrace(trace);
  }

  AppDeviceInfo get deviceInfo => _deviceInfoRepository.deviceInfo;

  AppPackageInfo get packageInfo => _deviceInfoRepository.packageInfo;
}
