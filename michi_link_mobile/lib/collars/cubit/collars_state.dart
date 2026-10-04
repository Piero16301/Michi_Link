part of 'collars_cubit.dart';

class CollarsState extends Equatable {
  const CollarsState({required this.collars});

  factory CollarsState.initial() {
    final now = DateTime.now();
    return CollarsState(
      collars: [
        CollarModel(
          deviceId: 'COLLAR_9E284A1F8C592E5A',
          name: 'Michin',
          isOnline: true,
          hasActiveAlert: false,
          packetLossPct: '0.0%',
          packetsLost: 2,
          packetsReceived: 340,
          config: const CollarConfig(
            maxDistanceM: 500,
            minBatteryPct: 20,
            requireGpsFix: true,
          ),
          coords: const CollarCoords(
            lat: -8.0666408,
            lon: -79.0628176,
            altM: 35,
          ),
          baseCoords: const CollarCoords(
            lat: -8.066663,
            lon: -79.062807,
            altM: 35,
          ),
          radio: const CollarRadio(
            distanceHomeM: 2.7,
            packetsLostGap: 0,
            rssi: -94,
            snr: 9.5,
            seq: 412,
          ),
          status: const CollarStatus(
            batteryPct: 85,
            batteryV: 3.95,
            gpsFix: true,
            sats: 15,
          ),
          lastSeen: now.subtract(const Duration(seconds: 20)),
          breed: CatBreed.europeanOrangeWhite,
        ),
        CollarModel(
          deviceId: 'COLLAR_5A7C9E23B81F4D02',
          name: 'Kira',
          isOnline: false,
          hasActiveAlert: false,
          packetLossPct: '1.2%',
          packetsLost: 8,
          packetsReceived: 215,
          config: const CollarConfig(
            maxDistanceM: 500,
            minBatteryPct: 20,
            requireGpsFix: true,
          ),
          coords: const CollarCoords(
            lat: -8.0667000,
            lon: -79.0629000,
            altM: 35,
          ),
          baseCoords: const CollarCoords(
            lat: -8.066663,
            lon: -79.062807,
            altM: 35,
          ),
          radio: const CollarRadio(
            distanceHomeM: 14.2,
            packetsLostGap: 0,
            rssi: -72,
            snr: 12,
            seq: 180,
          ),
          status: const CollarStatus(
            batteryPct: 92,
            batteryV: 4.12,
            gpsFix: true,
            sats: 11,
          ),
          lastSeen: now.subtract(const Duration(minutes: 2)),
          breed: CatBreed.persian,
        ),
      ],
    );
  }

  final List<CollarModel> collars;

  CollarsState copyWith({List<CollarModel>? collars}) {
    return CollarsState(collars: collars ?? this.collars);
  }

  @override
  List<Object?> get props => [collars];
}
