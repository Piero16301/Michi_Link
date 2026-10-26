import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:michi_link_mobile/app/app.dart';

part 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit({
    required String deviceId,
    DatabaseService? databaseService,
  }) : _databaseService = databaseService ?? getIt<DatabaseService>(),
       super(NotificationsState(deviceId: deviceId)) {
    _alertsSubscription = _databaseService
        .getAlertRecordsStream(deviceId: deviceId)
        .listen(
          _onAlertsChanged,
          onError: (_) =>
              emit(state.copyWith(status: NotificationsStatus.failure)),
        );
  }

  final DatabaseService _databaseService;
  late final StreamSubscription<List<AlertRecord>> _alertsSubscription;

  void _onAlertsChanged(List<AlertRecord> alerts) {
    emit(state.copyWith(alerts: alerts, status: NotificationsStatus.success));
  }

  @override
  Future<void> close() async {
    await _alertsSubscription.cancel();
    return await super.close();
  }
}
