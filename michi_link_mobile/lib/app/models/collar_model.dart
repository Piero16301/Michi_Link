import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:michi_link_mobile/app/global/app_variables.dart';
import 'package:michi_link_mobile/app/models/collar_config.dart';
import 'package:michi_link_mobile/app/models/collar_coords.dart';
import 'package:michi_link_mobile/app/models/collar_last_alert.dart';
import 'package:michi_link_mobile/app/models/collar_radio.dart';
import 'package:michi_link_mobile/app/models/collar_status.dart';

class CollarModel extends Equatable {
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
    this.breed = CatBreed.defaultBreed,
  });

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
      breed: json['breed'] != null
          ? CatBreed.values.firstWhere(
              (b) => b.name == json['breed'],
              orElse: () => CatBreed.defaultBreed,
            )
          : CatBreed.defaultBreed,
    );
  }

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
      'breed': breed.name,
    };
  }

  final String deviceId;
  final String name;
  final bool isOnline;
  final bool hasActiveAlert;
  final DateTime lastSeen;
  final String packetLossPct;
  final int packetsLost;
  final int packetsReceived;
  final CollarConfig config;
  final CollarCoords coords;
  final CollarCoords baseCoords;
  final CollarLastAlert? lastAlert;
  final CollarRadio radio;
  final CollarStatus status;
  final CatBreed breed;

  CollarModel copyWith({
    String? deviceId,
    String? name,
    bool? isOnline,
    bool? hasActiveAlert,
    DateTime? lastSeen,
    String? packetLossPct,
    int? packetsLost,
    int? packetsReceived,
    CollarConfig? config,
    CollarCoords? coords,
    CollarCoords? baseCoords,
    CollarLastAlert? lastAlert,
    CollarRadio? radio,
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
    status,
    breed,
  ];
}
