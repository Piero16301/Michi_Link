import 'dart:async';

import 'package:michi_link_mobile/app/app.dart';

class DatabaseService {
  DatabaseService({required this._databaseRepository});

  final DatabaseRepository _databaseRepository;

  Stream<CollarModel> getCollarStream({required String collarId}) {
    return _databaseRepository.getCollarStream(collarId: collarId);
  }

  void updateCollar({
    required String collarId,
    required String name,
    required CatBreed breed,
  }) {
    return _databaseRepository.updateCollar(
      collarId: collarId,
      name: name,
      breed: breed,
    );
  }

  void updateCollarConfig({
    required String collarId,
    required CollarConfig config,
  }) {
    _databaseRepository.updateCollarConfig(collarId: collarId, config: config);
  }

  Stream<List<AlertRecord>> getAlertRecordsStream({required String collarId}) {
    return _databaseRepository.getAlertRecordsStream(collarId: collarId);
  }

  Stream<List<HistoryRecord>> getHistoryRecordsStream({
    required String collarId,
    required DateTime start,
    required DateTime end,
  }) {
    return _databaseRepository.getHistoryRecordsStream(
      collarId: collarId,
      start: start,
      end: end,
    );
  }
}
