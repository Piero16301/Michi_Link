import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:michi_link_mobile/app/app.dart';

part 'collars_state.dart';

class CollarsCubit extends Cubit<CollarsState> {
  CollarsCubit({
    LocalStorageService? localStorage,
    DatabaseService? databaseService,
    NotificationService? notificationService,
  }) : _localStorage = localStorage ?? getIt<LocalStorageService>(),
       _databaseService = databaseService ?? getIt<DatabaseService>(),
       _notificationService =
           notificationService ??
           (getIt.isRegistered<NotificationService>()
               ? getIt<NotificationService>()
               : null),
       super(
         CollarsState(
           collars: (localStorage ?? getIt<LocalStorageService>()).getCollars(),
         ),
       ) {
    _collarsSubscription = _localStorage.getCollarsStream().listen(
      _onCollarsChanged,
    );
  }

  final LocalStorageService _localStorage;
  final DatabaseService _databaseService;
  final NotificationService? _notificationService;
  late final StreamSubscription<List<String>> _collarsSubscription;

  void _onCollarsChanged(List<String> collars) {
    emit(state.copyWith(collars: collars));
  }

  void addCollar({required String deviceId}) {
    if (state.collars.contains(deviceId)) return;

    final isFirstCollar = state.collars.isEmpty;
    final currentCollars = state.collars;
    _localStorage.saveCollars(collars: [...currentCollars, deviceId]);

    if (isFirstCollar) {
      _localStorage.saveSelectedCollarId(deviceId: deviceId);
    }

    unawaited(
      _notificationService?.toggleCollarTopic(
        deviceId: deviceId,
        enabled: true,
      ),
    );

    final token = _notificationService?.token;
    if (token != null && token.isNotEmpty) {
      _databaseService.updateDeviceSettings(
        token: token,
        collarToModify: deviceId,
        enabledCollars: currentCollars,
      );
    }
  }

  void updateCollar({
    required String deviceId,
    required String name,
    required CatBreed breed,
  }) {
    _databaseService.updateCollar(deviceId: deviceId, name: name, breed: breed);
  }

  void removeCollar(String deviceId) {
    if (!state.collars.contains(deviceId)) return;

    final currentCollars = state.collars;
    final updatedList = currentCollars.where((id) => id != deviceId).toList();
    _localStorage.saveCollars(collars: updatedList);

    final selectedCollarId = _localStorage.getSelectedCollarId();
    if (selectedCollarId == deviceId) {
      final nextSelectedCollarId = updatedList.isNotEmpty
          ? updatedList.first
          : null;
      _localStorage.saveSelectedCollarId(deviceId: nextSelectedCollarId);
    }

    unawaited(
      _notificationService?.toggleCollarTopic(
        deviceId: deviceId,
        enabled: false,
      ),
    );

    final token = _notificationService?.token;
    if (token != null && token.isNotEmpty) {
      _databaseService.updateDeviceSettings(
        token: token,
        collarToModify: deviceId,
        enabledCollars: currentCollars,
      );
    }
  }

  @override
  Future<void> close() async {
    await _collarsSubscription.cancel();
    return await super.close();
  }
}
