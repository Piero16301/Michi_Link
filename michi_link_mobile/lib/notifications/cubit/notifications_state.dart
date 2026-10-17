part of 'notifications_cubit.dart';

class NotificationsState extends Equatable {
  const NotificationsState({this.collarId = '', this.alerts = const []});

  final String collarId;
  final List<AlertRecord> alerts;

  NotificationsState copyWith({String? collarId, List<AlertRecord>? alerts}) {
    return NotificationsState(
      collarId: collarId ?? this.collarId,
      alerts: alerts ?? this.alerts,
    );
  }

  @override
  List<Object?> get props => [collarId, alerts];
}
