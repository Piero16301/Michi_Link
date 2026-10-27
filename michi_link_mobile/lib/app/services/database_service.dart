import 'dart:async';

import 'package:expressive_kit/expressive_kit.dart';
import 'package:michi_link_mobile/app/app.dart';

class DatabaseService {
  DatabaseService({required this._databaseRepository});

  final DatabaseRepository _databaseRepository;

  Stream<CollarModel> getCollarStream({required String deviceId}) {
    return _databaseRepository.getCollarStream(deviceId: deviceId);
  }

  void updateCollar({
    required String deviceId,
    required String name,
    required CatBreed breed,
  }) {
    _databaseRepository.updateCollar(
      deviceId: deviceId,
      name: name,
      breed: breed,
    );
  }

  void updateCollarConfig({
    required String deviceId,
    required CollarConfig config,
  }) {
    _databaseRepository.updateCollarConfig(deviceId: deviceId, config: config);
  }

  Stream<List<AlertRecord>> getAlertRecordsStream({required String deviceId}) {
    return _databaseRepository.getAlertRecordsStream(deviceId: deviceId);
  }

  Stream<List<HistoryRecord>> getHistoryRecordsStream({
    required String deviceId,
    required DateTime start,
    required DateTime end,
  }) {
    return _databaseRepository.getHistoryRecordsStream(
      deviceId: deviceId,
      start: start,
      end: end,
    );
  }

  void updateDeviceSettings({
    required String token,
    AppDeviceInfo? deviceInfo,
    String? collarToModify,
    List<String>? enabledCollars,
  }) {
    _databaseRepository.updateDeviceSettings(
      token: token,
      deviceInfo: deviceInfo,
      collarToModify: collarToModify,
      enabledCollars: enabledCollars,
    );
  }
}
