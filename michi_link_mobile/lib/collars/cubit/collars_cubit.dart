import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:michi_link_mobile/app/global/app_variables.dart';
import 'package:michi_link_mobile/app/models/collar_config.dart';
import 'package:michi_link_mobile/app/models/collar_coords.dart';
import 'package:michi_link_mobile/app/models/collar_model.dart';
import 'package:michi_link_mobile/app/models/collar_radio.dart';
import 'package:michi_link_mobile/app/models/collar_status.dart';

part 'collars_state.dart';

class CollarsCubit extends Cubit<CollarsState> {
  CollarsCubit() : super(CollarsState.initial());

  void addCollar({
    required String name,
    required String deviceId,
    required CatBreed breed,
  }) {
    final newCollar = CollarModel(
      deviceId: deviceId,
      name: name,
      isOnline: true,
      hasActiveAlert: false,
      packetLossPct: '0.0%',
      packetsLost: 0,
      packetsReceived: 1,
      config: const CollarConfig(
        maxDistanceM: 500,
        minBatteryPct: 20,
        requireGpsFix: true,
      ),
      coords: const CollarCoords(lat: -8.066663, lon: -79.062807, altM: 35),
      baseCoords: const CollarCoords(lat: -8.066663, lon: -79.062807, altM: 35),
      radio: const CollarRadio(
        distanceHomeM: 0,
        packetsLostGap: 0,
        rssi: -80,
        snr: 10,
        seq: 1,
      ),
      status: const CollarStatus(
        batteryPct: 100,
        batteryV: 4.20,
        gpsFix: true,
        sats: 12,
      ),
      lastSeen: DateTime.now(),
      breed: breed,
    );

    emit(state.copyWith(collars: [...state.collars, newCollar]));
  }

  void updateCollar({
    required String deviceId,
    required String name,
    int? minBatteryPct,
    CatBreed? breed,
  }) {
    final updatedList = state.collars.map((collar) {
      if (collar.deviceId == deviceId) {
        return collar.copyWith(
          name: name,
          breed: breed ?? collar.breed,
          config: minBatteryPct != null
              ? CollarConfig(
                  maxDistanceM: collar.config.maxDistanceM,
                  minBatteryPct: minBatteryPct,
                  requireGpsFix: collar.config.requireGpsFix,
                )
              : collar.config,
        );
      }
      return collar;
    }).toList();

    emit(state.copyWith(collars: updatedList));
  }

  void removeCollar(String deviceId) {
    final updatedList = state.collars
        .where((c) => c.deviceId != deviceId)
        .toList();
    emit(state.copyWith(collars: updatedList));
  }
}
