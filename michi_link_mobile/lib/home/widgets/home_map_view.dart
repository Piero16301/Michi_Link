import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';

class HomeMapView extends StatelessWidget {
  const HomeMapView({required this.collar, super.key});

  final CollarModel collar;

  @override
  Widget build(BuildContext context) {
    final baseCoords = collar.baseCoords;

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(baseCoords.lat, baseCoords.lon),
        zoom: 17,
      ),
    );
  }
}
