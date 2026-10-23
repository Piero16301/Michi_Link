# ADR-003: Google Maps Integration, LoRa Telemetry, and Geofencing

## Status
Accepted

## Date
2026-10-23

## Context
The core capability of Michi Link is tracking pets equipped with a long-range LoRa radio transmitter and GPS collar.
Requirements for mapping and location visualization include:
- Real-time display of the pet's position alongside the home base station coordinates.
- Visual representation of the safety perimeter (geofence circle) and its active status (normal vs. breached).
- Custom map styling (light and dark mode) adhering to the app's color scheme.
- Dynamic custom map markers with cat breed SVG avatars (`CatBreed`) and floating telemetry callouts (battery, distance to home, GPS satellites, RSSI, SNR).
- Breadcrumb route playback via polylines.

## Decision
1. **Google Maps Flutter (`google_maps_flutter`)**:
   - Mature official SDK with hardware-accelerated rendering on Android and iOS.
   - Native support for `Circle` (geofence perimeter) and `Polyline` (historical path tracing).
2. **Dynamic Marker Generation (`home_marker_builder.dart`)**:
   - In-memory canvas and bitmap descriptor rendering to paint pins featuring custom SVG cat breed avatars.
3. **Custom Map Themes (`app_map_styles.dart`)**:
   - Dedicated JSON styling for light and dark themes synchronized with application theme changes.
4. **LoRa Radio Link Metrics**:
   - Real-time UI exposure of RSSI (Received Signal Strength Indicator), SNR (Signal-to-Noise Ratio), and packet loss percentage to let pet owners gauge signal coverage in challenging environments.

## Alternatives Considered

### Flutter Map (OpenStreetMap / Leaflet)
- **Pros**: Free, no Google Maps API keys required, widget-based layer composition.
- **Cons**: Requires hosting or paying for 3rd-party tile servers with rate limits; lower frame rate compared to native vector tiles on low-end devices.
- **Rejected**: Google Maps provides superior vector smoothness, rotation performance, and gesture stability.

### Mapbox Maps SDK
- **Pros**: Exceptional visual customization and high-performance vector rendering.
- **Cons**: Complex integration footprint, monthly active user pricing tier, and larger binary size.
- **Rejected**: Google Maps covers all project requirements predictably and reliably.

## Consequences
- **Positive**:
  - Smooth 60/120 FPS map interactions and camera animations.
  - Immediate visual feedback on the map when distances exceed the configured `maxDistanceM` threshold.
- **Negative / Trade-offs**:
  - Requires valid Google Maps API Keys configured in `AndroidManifest.xml` and `AppDelegate.swift`.
  - Custom bitmap marker generation involves asynchronous rasterization of SVG assets.
