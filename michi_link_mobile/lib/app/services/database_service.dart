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
}
