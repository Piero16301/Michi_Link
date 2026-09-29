import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:michi_link_mobile/app/app.dart';

/// {@template alert_record}
/// A class that represents an alert log entry
/// {@endtemplate}
class AlertRecord extends Equatable {
  /// {@macro alert_record}
  const AlertRecord({
    required this.id,
    required this.severity,
    required this.type,
    required this.value,
    required this.expireAt,
    required this.timestamp,
  });

  /// Creates an instance of [AlertRecord] from a [Map]
  factory AlertRecord.fromJson(Map<String, dynamic> json, {String? id}) {
    return AlertRecord(
      id: id ?? '',
      severity: AlertSeverity.fromString(json['severity'] as String?),
      type: AlertType.fromString(json['type'] as String?),
      value: (json['value'] as num?) ?? 0,
      expireAt: (json['expire_at'] as Timestamp? ?? Timestamp.now())
          .toDate()
          .toLocal(),
      timestamp: (json['timestamp'] as Timestamp? ?? Timestamp.now())
          .toDate()
          .toLocal(),
    );
  }

  /// Creates a [Map] from an instance of [AlertRecord]
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'severity': severity.value,
      'type': type.value,
      'value': value,
      'expire_at': expireAt.toUtc(),
      'timestamp': timestamp.toUtc(),
    };
  }

  /// Unique identifier of the alert document
  final String id;

  /// Expiration date for automatic TTL cleanup
  final DateTime expireAt;

  /// Alert severity level (e.g. INFO, WARNING, CRITICAL)
  final AlertSeverity severity;

  /// Timestamp when the alert was triggered
  final DateTime timestamp;

  /// Alert event type (e.g. BATTERY_NORMAL, SIGNAL_NORMAL)
  final AlertType type;

  /// Value associated with the alert condition
  final num value;

  @override
  List<Object?> get props => [id, expireAt, severity, timestamp, type, value];
}
