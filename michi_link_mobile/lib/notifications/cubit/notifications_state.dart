part of 'notifications_cubit.dart';

enum NotificationsStatus { initial, loading, success, failure }

class NotificationsState extends Equatable {
  const NotificationsState({
    this.deviceId = '',
    this.alerts = const [],
    this.status = NotificationsStatus.loading,
  });

  final String deviceId;
  final List<AlertRecord> alerts;
  final NotificationsStatus status;

  NotificationsState copyWith({
    String? deviceId,
    List<AlertRecord>? alerts,
    NotificationsStatus? status,
  }) {
    return NotificationsState(
      deviceId: deviceId ?? this.deviceId,
      alerts: alerts ?? this.alerts,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [deviceId, alerts, status];
}
