import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:michi_link_mobile/app/app.dart';

part 'collars_state.dart';

class CollarsCubit extends Cubit<CollarsState> {
  CollarsCubit({
    LocalStorageService? localStorage,
    DatabaseService? databaseService,
  })  : _localStorage = localStorage ?? getIt<LocalStorageService>(),
        _databaseService = databaseService ?? getIt<DatabaseService>(),
        super(
          CollarsState(
            collars:
                (localStorage ?? getIt<LocalStorageService>()).getCollars(),
          ),
        ) {
    _collarsSubscription = _localStorage.getCollarsStream().listen(
      _onCollarsChanged,
    );
  }

  final LocalStorageService _localStorage;
  final DatabaseService _databaseService;
  late final StreamSubscription<List<String>> _collarsSubscription;

  void _onCollarsChanged(List<String> collars) {
    emit(state.copyWith(collars: collars));
  }

  void addCollar({required String deviceId, String? name, CatBreed? breed}) {
    if (state.collars.contains(deviceId)) return;

    _localStorage.saveCollars(collars: [...state.collars, deviceId]);
  }

  void updateCollar({
    required String collarId,
    required String name,
    required CatBreed breed,
  }) {
    _databaseService.updateCollar(
      collarId: collarId,
      name: name,
      breed: breed,
    );
  }

  void removeCollar(String deviceId) {
    if (!state.collars.contains(deviceId)) return;

    final updatedList = state.collars.where((id) => id != deviceId).toList();
    _localStorage.saveCollars(collars: updatedList);

    final selectedCollarId = _localStorage.getSelectedCollarId();
    if (selectedCollarId == deviceId) {
      final nextSelectedCollarId = updatedList.isNotEmpty
          ? updatedList.first
          : null;
      _localStorage.saveSelectedCollarId(collarId: nextSelectedCollarId);
    }
  }

  @override
  Future<void> close() async {
    await _collarsSubscription.cancel();
    return await super.close();
  }
}
