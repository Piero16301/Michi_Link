import 'package:equatable/equatable.dart';

/// {@template collar_coords}
/// A class that represents coordinates for a collar
/// {@endtemplate}
class CollarCoords extends Equatable {
  /// {@macro collar_coords}
  const CollarCoords({
    required this.altM,
    required this.lat,
    required this.lon,
  });

  /// Creates an instance of [CollarCoords] from a [Map]
  factory CollarCoords.fromJson(Map<String, dynamic> json) {
    return CollarCoords(
      altM: (json['alt_m'] as num?)?.toDouble() ?? 0.0,
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (json['lon'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Creates a [Map] from an instance of [CollarCoords]
  Map<String, dynamic> toJson() {
    return <String, dynamic>{'alt_m': altM, 'lat': lat, 'lon': lon};
  }

  /// Altitude in meters
  final double altM;

  /// Latitude coordinate
  final double lat;

  /// Longitude coordinate
  final double lon;

  @override
  List<Object?> get props => [altM, lat, lon];
}
