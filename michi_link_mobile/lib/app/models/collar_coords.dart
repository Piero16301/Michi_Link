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
    final rawLat = (json['lat'] as num?)?.toDouble() ?? 0.0;
    final rawLon = (json['lon'] as num?)?.toDouble() ?? 0.0;
    final rawAlt = (json['alt_m'] as num?)?.toDouble() ?? 0.0;

    final lat = rawLat.isFinite ? rawLat.clamp(-90.0, 90.0) : 0.0;
    final lon = rawLon.isFinite ? rawLon.clamp(-180.0, 180.0) : 0.0;
    final altM = rawAlt.isFinite ? rawAlt : 0.0;

    return CollarCoords(altM: altM, lat: lat, lon: lon);
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
