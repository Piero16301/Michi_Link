import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:michi_link_mobile/app/models/collar_config.dart';
import 'package:michi_link_mobile/app/models/collar_coords.dart';
import 'package:michi_link_mobile/app/models/collar_last_alert.dart';
import 'package:michi_link_mobile/app/models/collar_radio.dart';
import 'package:michi_link_mobile/app/models/collar_status.dart';

/// {@template collar_model}
/// A class that represents a collar device and its complete state
/// {@endtemplate}
class CollarModel extends Equatable {
  /// {@macro collar_model}
  const CollarModel({
    required this.deviceId,
    required this.name,
    required this.isOnline,
    required this.hasActiveAlert,
    required this.packetLossPct,
    required this.packetsLost,
    required this.packetsReceived,
    required this.config,
    required this.coords,
    required this.baseCoords,
    required this.radio,
    required this.status,
    required this.lastSeen,
    this.lastAlert,
  });

  /// Creates an instance of [CollarModel] from a [Map]
  factory CollarModel.fromJson(Map<String, dynamic> json) {
    return CollarModel(
      deviceId: json['device_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      isOnline: json['is_online'] as bool? ?? false,
      hasActiveAlert: json['has_active_alert'] as bool? ?? false,
      lastSeen: (json['last_seen'] as Timestamp? ?? Timestamp.now())
          .toDate()
          .toLocal(),
      packetLossPct: json['packet_loss_pct'] as String? ?? '0%',
      packetsLost: (json['packets_lost'] as num?)?.toInt() ?? 0,
      packetsReceived: (json['packets_received'] as num?)?.toInt() ?? 0,
      config: json['config'] != null
          ? CollarConfig.fromJson(json['config'] as Map<String, dynamic>)
          : const CollarConfig(
              maxDistanceM: 0,
              minBatteryPct: 0,
              requireGpsFix: false,
            ),
      coords: json['coords'] != null
          ? CollarCoords.fromJson(json['coords'] as Map<String, dynamic>)
          : const CollarCoords(altM: 0, lat: 0, lon: 0),
      baseCoords: json['base_coords'] != null
          ? CollarCoords.fromJson(json['base_coords'] as Map<String, dynamic>)
          : const CollarCoords(altM: 0, lat: 0, lon: 0),
      lastAlert: json['last_alert'] != null
          ? CollarLastAlert.fromJson(json['last_alert'] as Map<String, dynamic>)
          : null,
      radio: json['radio'] != null
          ? CollarRadio.fromJson(json['radio'] as Map<String, dynamic>)
          : const CollarRadio(
              distanceHomeM: 0,
              packetsLostGap: 0,
              rssi: 0,
              snr: 0,
              seq: 0,
            ),
      status: json['status'] != null
          ? CollarStatus.fromJson(json['status'] as Map<String, dynamic>)
          : const CollarStatus(
              batteryPct: 0,
              batteryV: 0,
              gpsFix: false,
              sats: 0,
            ),
    );
  }

  /// Creates a [Map] from an instance of [CollarModel]
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'device_id': deviceId,
      'name': name,
      'is_online': isOnline,
      'has_active_alert': hasActiveAlert,
      'last_seen': lastSeen.toUtc(),
      'packet_loss_pct': packetLossPct,
      'packets_lost': packetsLost,
      'packets_received': packetsReceived,
      'config': config.toJson(),
      'coords': coords.toJson(),
      'base_coords': baseCoords.toJson(),
      'last_alert': lastAlert?.toJson(),
      'radio': radio.toJson(),
      'status': status.toJson(),
    };
  }

  /// Unique identifier of the collar device
  final String deviceId;

  /// Pet or collar display name
  final String name;

  /// Whether the device is currently online
  final bool isOnline;

  /// Whether there is currently an active alert
  final bool hasActiveAlert;

  /// Timestamp of the last received signal
  final DateTime lastSeen;

  /// Packet loss percentage formatted string
  final String packetLossPct;

  /// Count of lost packets
  final int packetsLost;

  /// Count of received packets
  final int packetsReceived;

  /// Collar configuration parameters
  final CollarConfig config;

  /// Current GPS coordinates
  final CollarCoords coords;

  /// Base GPS coordinates (home)
  final CollarCoords baseCoords;

  /// Most recent alert details, if any
  final CollarLastAlert? lastAlert;

  /// LoRa radio metrics
  final CollarRadio radio;

  /// Device hardware status
  final CollarStatus status;

  @override
  List<Object?> get props => [
    deviceId,
    name,
    isOnline,
    hasActiveAlert,
    lastSeen,
    packetLossPct,
    packetsLost,
    packetsReceived,
    config,
    coords,
    baseCoords,
    lastAlert,
    radio,
    status,
  ];
}
