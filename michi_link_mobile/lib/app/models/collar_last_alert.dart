import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:michi_link_mobile/app/app.dart';

/// {@template collar_last_alert}
/// A class that represents the most recent alert for a collar
/// {@endtemplate}
class CollarLastAlert extends Equatable {
  /// {@macro collar_last_alert}
  const CollarLastAlert({
    required this.severity,
    required this.type,
    required this.timestamp,
    required this.value,
  });

  /// Creates an instance of [CollarLastAlert] from a [Map]
  factory CollarLastAlert.fromJson(Map<String, dynamic> json) {
    return CollarLastAlert(
      severity: AlertSeverity.fromString(json['severity'] as String?),
      type: AlertType.fromString(json['type'] as String?),
      timestamp: (json['timestamp'] as Timestamp? ?? Timestamp.now())
          .toDate()
          .toLocal(),
      value: (json['value'] as num?) ?? 0,
    );
  }

  /// Creates a [Map] from an instance of [CollarLastAlert]
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'severity': severity.value,
      'type': type.value,
      'timestamp': timestamp.toUtc(),
      'value': value,
    };
  }

  /// Alert severity level (e.g. INFO, WARNING, CRITICAL)
  final AlertSeverity severity;

  /// Type of alert (e.g. SIGNAL_NORMAL, BATTERY_NORMAL)
  final AlertType type;

  /// Timestamp when the alert occurred
  final DateTime timestamp;

  /// Value associated with the alert
  final num value;

  @override
  List<Object?> get props => [severity, type, timestamp, value];
}
