import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:michi_link_mobile/app/global/app_variables.dart';
import 'package:michi_link_mobile/app/models/collar_config.dart';
import 'package:michi_link_mobile/app/models/collar_coords.dart';
import 'package:michi_link_mobile/app/models/collar_last_alert.dart';
import 'package:michi_link_mobile/app/models/collar_radio.dart';
import 'package:michi_link_mobile/app/models/collar_status.dart';

/// {@template collar_model}
/// A class that represents a collar device with telemetry and status
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
    required this.seq,
    required this.status,
    required this.lastSeen,
    this.lastAlert,
    this.breed = CatBreed.defaultBreed,
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
      packetLossPct: (json['packet_loss_pct'] as num?)?.toDouble() ?? 0,
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
      breed: json['breed'] != null
          ? CatBreed.values.firstWhere(
              (b) => b.name == json['breed'],
              orElse: () => CatBreed.defaultBreed,
            )
          : CatBreed.defaultBreed,
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
      'seq': seq,
      'status': status.toJson(),
      'breed': breed.name,
    };
  }

  /// Unique identifier of the collar device
  final String deviceId;

  /// Name of the collar or pet
  final String name;

  /// Whether the collar is currently connected and transmitting
  final bool isOnline;

  /// Whether the collar currently has an active alert
  final bool hasActiveAlert;

  /// Timestamp when the collar was last seen
  final DateTime lastSeen;

  /// Percentage of lost packets
  final double packetLossPct;

  /// Total number of packets lost
  final int packetsLost;

  /// Total number of packets successfully received
  final int packetsReceived;

  /// Configuration thresholds and settings for the collar
  final CollarConfig config;

  /// Current GPS coordinates of the collar
  final CollarCoords coords;

  /// GPS coordinates of the base station
  final CollarCoords baseCoords;

  /// Most recent alert triggered by the collar, if any
  final CollarLastAlert? lastAlert;

  /// LoRa radio transmission and reception metrics
  final CollarRadio radio;

  /// Telemetry packet sequence number
  final int seq;

  /// Hardware status of the collar (battery, GPS fix, satellites)
  final CollarStatus status;

  /// Cat breed assigned to this collar
  final CatBreed breed;

  /// Creates a copy of [CollarModel] with the given fields replaced
  CollarModel copyWith({
    String? deviceId,
    String? name,
    bool? isOnline,
    bool? hasActiveAlert,
    DateTime? lastSeen,
    double? packetLossPct,
    int? packetsLost,
    int? packetsReceived,
    CollarConfig? config,
    CollarCoords? coords,
    CollarCoords? baseCoords,
    CollarLastAlert? lastAlert,
    CollarRadio? radio,
    int? seq,
    CollarStatus? status,
    CatBreed? breed,
  }) {
    return CollarModel(
      deviceId: deviceId ?? this.deviceId,
      name: name ?? this.name,
      isOnline: isOnline ?? this.isOnline,
      hasActiveAlert: hasActiveAlert ?? this.hasActiveAlert,
      lastSeen: lastSeen ?? this.lastSeen,
      packetLossPct: packetLossPct ?? this.packetLossPct,
      packetsLost: packetsLost ?? this.packetsLost,
      packetsReceived: packetsReceived ?? this.packetsReceived,
      config: config ?? this.config,
      coords: coords ?? this.coords,
      baseCoords: baseCoords ?? this.baseCoords,
      lastAlert: lastAlert ?? this.lastAlert,
      radio: radio ?? this.radio,
      seq: seq ?? this.seq,
      status: status ?? this.status,
      breed: breed ?? this.breed,
    );
  }

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
    seq,
    status,
    breed,
  ];
}
