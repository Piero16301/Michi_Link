import 'dart:async';

import 'package:michi_link_mobile/app/app.dart';

class DatabaseService {
  DatabaseService({required this._databaseRepository});

  final DatabaseRepository _databaseRepository;

  Stream<CollarModel> getCollarStream({required String deviceId}) {
    return _databaseRepository.getCollarStream(deviceId);
  }
}
