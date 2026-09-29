import 'package:equatable/equatable.dart';

/// {@template collar_config}
/// A class that represents configuration parameters for a collar
/// {@endtemplate}
class CollarConfig extends Equatable {
  /// {@macro collar_config}
  const CollarConfig({
    required this.maxDistanceM,
    required this.minBatteryPct,
    required this.requireGpsFix,
  });

  /// Creates an instance of [CollarConfig] from a [Map]
  factory CollarConfig.fromJson(Map<String, dynamic> json) {
    return CollarConfig(
      maxDistanceM: (json['max_distance_m'] as num?)?.toInt() ?? 0,
      minBatteryPct: (json['min_battery_pct'] as num?)?.toInt() ?? 0,
      requireGpsFix: json['require_gps_fix'] as bool? ?? false,
    );
  }

  /// Creates a [Map] from an instance of [CollarConfig]
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'max_distance_m': maxDistanceM,
      'min_battery_pct': minBatteryPct,
      'require_gps_fix': requireGpsFix,
    };
  }

  /// Maximum allowed distance in meters before triggering an alert
  final int maxDistanceM;

  /// Minimum battery percentage threshold before warning
  final int minBatteryPct;

  /// Whether a valid GPS fix is required
  final bool requireGpsFix;

  @override
  List<Object?> get props => [maxDistanceM, minBatteryPct, requireGpsFix];
}
