import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:michi_link_mobile/app/models/collar_coords.dart';
import 'package:michi_link_mobile/app/models/collar_radio.dart';
import 'package:michi_link_mobile/app/models/collar_status.dart';

/// {@template history_record}
/// A class that represents a historical telemetry record for a collar
/// {@endtemplate}
class HistoryRecord extends Equatable {
  /// {@macro history_record}
  const HistoryRecord({
    required this.id,
    required this.coords,
    required this.radio,
    required this.seq,
    required this.status,
    required this.expireAt,
    required this.timestamp,
  });

  /// Creates an instance of [HistoryRecord] from a [Map]
  factory HistoryRecord.fromJson(Map<String, dynamic> json, {String? id}) {
    return HistoryRecord(
      id: id ?? '',
      coords: json['coords'] != null
          ? CollarCoords.fromJson(json['coords'] as Map<String, dynamic>)
          : const CollarCoords(altM: 0, lat: 0, lon: 0),
      expireAt: (json['expire_at'] as Timestamp? ?? Timestamp.now())
          .toDate()
          .toLocal(),
      radio: json['radio'] != null
          ? CollarRadio.fromJson(json['radio'] as Map<String, dynamic>)
          : const CollarRadio(
              distanceHomeM: 0,
              packetsLostGap: 0,
              rssi: 0,
              snr: 0,
            ),
      seq: (json['seq'] as num?)?.toInt() ?? 0,
      status: json['status'] != null
          ? CollarStatus.fromJson(json['status'] as Map<String, dynamic>)
          : const CollarStatus(
              batteryPct: 0,
              batteryV: 0,
              gpsFix: false,
              sats: 0,
            ),
      timestamp: (json['timestamp'] as Timestamp? ?? Timestamp.now())
          .toDate()
          .toLocal(),
    );
  }

  /// Creates a [Map] from an instance of [HistoryRecord]
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'coords': coords.toJson(),
      'radio': radio.toJson(),
      'seq': seq,
      'status': status.toJson(),
      'expire_at': expireAt.toUtc(),
      'timestamp': timestamp.toUtc(),
    };
  }

  /// Unique identifier of the history record document
  final String id;

  /// GPS coordinates at the time of recording
  final CollarCoords coords;

  /// Expiration date for automatic TTL cleanup
  final DateTime expireAt;

  /// LoRa radio metrics at the time of recording
  final CollarRadio radio;

  /// Telemetry packet sequence number
  final int seq;

  /// Hardware status at the time of recording
  final CollarStatus status;

  /// Timestamp when the record was captured
  final DateTime timestamp;

  @override
  List<Object?> get props => [
    id,
    coords,
    expireAt,
    radio,
    seq,
    status,
    timestamp,
  ];
}
