import 'package:equatable/equatable.dart';

/// {@template collar_status}
/// A class that represents the hardware status of a collar
/// {@endtemplate}
class CollarStatus extends Equatable {
  /// {@macro collar_status}
  const CollarStatus({
    required this.batteryPct,
    required this.batteryV,
    required this.gpsFix,
    required this.sats,
  });

  /// Creates an instance of [CollarStatus] from a [Map]
  factory CollarStatus.fromJson(Map<String, dynamic> json) {
    return CollarStatus(
      batteryPct: (json['battery_pct'] as num?)?.toInt() ?? 0,
      batteryV: (json['battery_v'] as num?)?.toDouble() ?? 0.0,
      gpsFix: json['gps_fix'] as bool? ?? false,
      sats: (json['sats'] as num?)?.toInt() ?? 0,
    );
  }

  /// Creates a [Map] from an instance of [CollarStatus]
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'battery_pct': batteryPct,
      'battery_v': batteryV,
      'gps_fix': gpsFix,
      'sats': sats,
    };
  }

  /// Battery percentage (0-100)
  final int batteryPct;

  /// Battery voltage in volts
  final double batteryV;

  /// Whether GPS has a satellite fix
  final bool gpsFix;

  /// Number of tracked GPS satellites
  final int sats;

  @override
  List<Object?> get props => [batteryPct, batteryV, gpsFix, sats];
}
