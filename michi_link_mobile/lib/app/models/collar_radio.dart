import 'package:equatable/equatable.dart';

/// {@template collar_radio}
/// A class that represents the radio metrics of a collar
/// {@endtemplate}
class CollarRadio extends Equatable {
  /// {@macro collar_radio}
  const CollarRadio({
    required this.distanceHomeM,
    required this.packetsLostGap,
    required this.rssi,
    required this.snr,
    required this.seq,
  });

  /// Creates an instance of [CollarRadio] from a [Map]
  factory CollarRadio.fromJson(Map<String, dynamic> json) {
    return CollarRadio(
      distanceHomeM: (json['distance_home_m'] as num?)?.toDouble() ?? 0.0,
      packetsLostGap: (json['packets_lost_gap'] as num?)?.toInt() ?? 0,
      rssi: (json['rssi'] as num?)?.toInt() ?? 0,
      snr: (json['snr'] as num?)?.toDouble() ?? 0.0,
      seq: (json['seq'] as num?)?.toInt() ?? 0,
    );
  }

  /// Creates a [Map] from an instance of [CollarRadio]
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'distance_home_m': distanceHomeM,
      'packets_lost_gap': packetsLostGap,
      'rssi': rssi,
      'snr': snr,
      'seq': seq,
    };
  }

  /// Distance to home base in meters
  final double distanceHomeM;

  /// Gap of packets lost
  final int packetsLostGap;

  /// Received Signal Strength Indication in dBm
  final int rssi;

  /// Signal-to-Noise Ratio in dB
  final double snr;

  /// Sequence number of the transmission packet
  final int seq;

  @override
  List<Object?> get props => [distanceHomeM, packetsLostGap, rssi, snr, seq];
}
