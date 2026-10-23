part of 'notifications_cubit.dart';

enum NotificationsStatus { initial, loading, success, failure }

class NotificationsState extends Equatable {
  const NotificationsState({
    this.collarId = '',
    this.alerts = const [],
    this.status = NotificationsStatus.loading,
  });

  final String collarId;
  final List<AlertRecord> alerts;
  final NotificationsStatus status;

  NotificationsState copyWith({
    String? collarId,
    List<AlertRecord>? alerts,
    NotificationsStatus? status,
  }) {
    return NotificationsState(
      collarId: collarId ?? this.collarId,
      alerts: alerts ?? this.alerts,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [collarId, alerts, status];
}
