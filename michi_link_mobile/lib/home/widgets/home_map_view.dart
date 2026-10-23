import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/home/widgets/home_map_controls.dart';
import 'package:michi_link_mobile/home/widgets/home_marker_builder.dart';
import 'package:michi_link_mobile/home/widgets/home_marker_callout.dart';
import 'package:michi_link_mobile/l10n/l10n.dart';

enum _SelectedMarkerType { none, cat, base }

class HomeMapView extends StatefulWidget {
  const HomeMapView({required this.collar, this.onHistoryPressed, super.key});

  final CollarModel collar;
  final VoidCallback? onHistoryPressed;

  @override
  State<HomeMapView> createState() => _HomeMapViewState();
}

class _HomeMapViewState extends State<HomeMapView> {
  GoogleMapController? _mapController;
  CameraPosition? _currentCameraPosition;
  final ValueNotifier<double> _bearingNotifier = ValueNotifier<double>(0);
  double _currentZoom = 17;
  bool _hasLocationPermission = false;
  Position? _userPosition;
  double? _distanceToCatM;

  BitmapDescriptor? _catMarkerIcon;
  BitmapDescriptor? _baseMarkerIcon;
  Brightness? _lastBrightness;
  CatBreed? _lastBreed;
  double? _lastPixelRatio;

  _SelectedMarkerType _selectedMarker = _SelectedMarkerType.none;
  double _infoWindowX = 0;
  double _infoWindowY = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_checkInitialLocation());
  }

  @override
  void dispose() {
    _bearingNotifier.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final brightness = Theme.of(context).brightness;
    final pixelRatio =
        MediaQuery.maybeDevicePixelRatioOf(context) ??
        View.of(context).devicePixelRatio;
    // Carga los marcadores personalizados si cambia el brillo, la raza o
    // la resolución
    if (_lastBrightness != brightness ||
        _lastBreed != widget.collar.breed ||
        _lastPixelRatio != pixelRatio) {
      _lastBrightness = brightness;
      _lastBreed = widget.collar.breed;
      _lastPixelRatio = pixelRatio;
      unawaited(_loadCustomMarkers());
    }
  }

  @override
  void didUpdateWidget(HomeMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.collar.breed != widget.collar.breed) {
      _lastBreed = widget.collar.breed;
      unawaited(_loadCustomMarkers());
    }
    if (oldWidget.collar.coords.lat != widget.collar.coords.lat ||
        oldWidget.collar.coords.lon != widget.collar.coords.lon) {
      if (_userPosition != null) {
        _updateUserPosition(_userPosition!);
      }
      if (_selectedMarker == _SelectedMarkerType.cat) {
        unawaited(_updateInfoWindowPosition());
      }
    }
  }

  Future<void> _loadCustomMarkers() async {
    try {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      final isDark = theme.brightness == Brightness.dark;
      final pixelRatio =
          MediaQuery.maybeDevicePixelRatioOf(context) ??
          View.of(context).devicePixelRatio;

      final catIcon = await HomeMarkerBuilder.createSvgMarker(
        loader: SvgAssetLoader(widget.collar.breed.assetPath),
        borderColor: colorScheme.primary,
        bgColor: isDark ? colorScheme.surfaceContainerHigh : Colors.white,
        markerSize: 48,
        contentSize: 30,
        borderWidth: 2.2,
        pixelRatio: pixelRatio,
      );

      final baseSvg = HomeMarkerBuilder.buildHugeIconSvg(
        HugeIcons.strokeRoundedRadioTower,
        colorScheme.primary,
      );
      final baseIcon = await HomeMarkerBuilder.createSvgMarker(
        loader: SvgStringLoader(baseSvg),
        borderColor: colorScheme.secondary,
        bgColor: isDark ? colorScheme.surfaceContainerHigh : Colors.white,
        markerSize: 62,
        contentSize: 38,
        borderWidth: 2.8,
        pixelRatio: pixelRatio,
      );

      if (mounted) {
        setState(() {
          _catMarkerIcon = catIcon;
          _baseMarkerIcon = baseIcon;
        });
      }
    } on Exception catch (_) {}
  }

  Future<void> _updateInfoWindowPosition() async {
    if (_mapController == null || _selectedMarker == _SelectedMarkerType.none) {
      return;
    }
    final target = _selectedMarker == _SelectedMarkerType.cat
        ? LatLng(widget.collar.coords.lat, widget.collar.coords.lon)
        : LatLng(widget.collar.baseCoords.lat, widget.collar.baseCoords.lon);

    try {
      final screenCoord = await _mapController!.getScreenCoordinate(target);
      if (!mounted) return;
      final dpr = defaultTargetPlatform == TargetPlatform.android
          ? MediaQuery.devicePixelRatioOf(context)
          : 1.0;
      setState(() {
        _infoWindowX = screenCoord.x / dpr;
        _infoWindowY = screenCoord.y / dpr;
      });
    } on Exception catch (_) {}
  }

  Future<void> _selectMarker(_SelectedMarkerType type) async {
    if (_selectedMarker == type) {
      setState(() {
        _selectedMarker = _SelectedMarkerType.none;
      });
      return;
    }
    final target = type == _SelectedMarkerType.cat
        ? LatLng(widget.collar.coords.lat, widget.collar.coords.lon)
        : LatLng(widget.collar.baseCoords.lat, widget.collar.baseCoords.lon);

    if (_mapController != null) {
      try {
        final screenCoord = await _mapController!.getScreenCoordinate(target);
        if (!mounted) return;
        final dpr = defaultTargetPlatform == TargetPlatform.android
            ? MediaQuery.devicePixelRatioOf(context)
            : 1.0;
        setState(() {
          _infoWindowX = screenCoord.x / dpr;
          _infoWindowY = screenCoord.y / dpr;
          _selectedMarker = type;
        });
      } on Exception catch (_) {
        if (mounted) {
          setState(() {
            _selectedMarker = type;
          });
        }
      }
    } else {
      setState(() {
        _selectedMarker = type;
      });
    }
  }

  Future<void> _checkInitialLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled && mounted) {
          setState(() {
            _hasLocationPermission = true;
          });
          final position =
              await Geolocator.getLastKnownPosition() ??
              await Geolocator.getCurrentPosition(
                locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.medium,
                ),
              );
          if (mounted) {
            _updateUserPosition(position);
          }
        }
      }
    } on Exception catch (_) {}
  }

  void _updateUserPosition(Position position) {
    final catCoords = widget.collar.coords;
    double? dist;
    if (catCoords.lat != 0 || catCoords.lon != 0) {
      dist = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        catCoords.lat,
        catCoords.lon,
      );
    }
    setState(() {
      _userPosition = position;
      _distanceToCatM = dist;
    });
  }

  int _formatDistance(double meters) => meters.round();

  void _animateToBaseCoords() {
    final baseCoords = widget.collar.baseCoords;
    unawaited(
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(baseCoords.lat, baseCoords.lon),
          AppVariables.mapFocusZoom,
        ),
      ),
    );
  }

  void _zoomIn() {
    unawaited(_mapController?.animateCamera(CameraUpdate.zoomIn()));
  }

  void _resetNorth() {
    final controller = _mapController;
    if (controller == null) return;
    final currentPos =
        _currentCameraPosition ??
        CameraPosition(
          target: LatLng(
            widget.collar.baseCoords.lat,
            widget.collar.baseCoords.lon,
          ),
          zoom: _currentZoom,
        );
    unawaited(
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: currentPos.target,
            zoom: currentPos.zoom,
            tilt: currentPos.tilt,
          ),
        ),
      ),
    );
  }

  void _zoomOut() {
    unawaited(_mapController?.animateCamera(CameraUpdate.zoomOut()));
  }

  Future<void> _goToMyLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).homeLocationServiceDisabled,
          ),
          action: SnackBarAction(
            label: AppLocalizations.of(context).homeSettingsAction,
            onPressed: () => unawaited(Geolocator.openLocationSettings()),
          ),
        ),
      );
      _animateToBaseCoords();
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).homeOpenSettingsPrompt),
          action: SnackBarAction(
            label: AppLocalizations.of(context).homeSettingsAction,
            onPressed: () => unawaited(Geolocator.openAppSettings()),
          ),
        ),
      );
      _animateToBaseCoords();
      return;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _hasLocationPermission = false;
            _userPosition = null;
            _distanceToCatM = null;
          });
          if (permission == LocationPermission.deniedForever) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context).homeOpenSettingsPrompt,
                ),
                action: SnackBarAction(
                  label: AppLocalizations.of(context).homeSettingsAction,
                  onPressed: () => unawaited(Geolocator.openAppSettings()),
                ),
              ),
            );
          }
        }
        _animateToBaseCoords();
        return;
      }
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      if (mounted && !_hasLocationPermission) {
        setState(() {
          _hasLocationPermission = true;
        });
      }

      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        if (!mounted) return;
        _updateUserPosition(position);
        unawaited(
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(position.latitude, position.longitude),
              AppVariables.mapFocusZoom,
            ),
          ),
        );
      } on Exception catch (_) {
        _animateToBaseCoords();
      }
    }
  }

  void _goToCatLocation() {
    final catCoords = widget.collar.coords;
    unawaited(
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(catCoords.lat, catCoords.lon),
          AppVariables.mapFocusZoom,
        ),
      ),
    );
    if (_hasLocationPermission) {
      unawaited(_refreshUserDistanceSilently());
    }
  }

  Future<void> _refreshUserDistanceSilently() async {
    try {
      final position =
          await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
            ),
          );
      if (mounted) {
        _updateUserPosition(position);
      }
    } on Exception catch (_) {}
  }

  double _calculateZoomForRadius(double radiusM, double lat) {
    final cosLat = math.cos(lat * math.pi / 180.0).abs();
    final safeCos = cosLat > 0.0001 ? cosLat : 1.0;
    final zoom =
        math.log((156543.0 * safeCos * 320.0) / (2.0 * radiusM)) / math.ln2;
    return zoom.clamp(3.0, 20.0);
  }

  void _fitMaxDistanceRange({bool animate = true}) {
    final baseCoords = widget.collar.baseCoords;
    final radiusM = widget.collar.config.maxDistanceM <= 0
        ? 100.0
        : widget.collar.config.maxDistanceM.toDouble();

    final latDelta = radiusM / 111320.0;
    final cosLat = math.cos(baseCoords.lat * math.pi / 180.0).abs();
    final lonDelta = radiusM / (111320.0 * (cosLat > 0.0001 ? cosLat : 1.0));

    final bounds = LatLngBounds(
      southwest: LatLng(baseCoords.lat - latDelta, baseCoords.lon - lonDelta),
      northeast: LatLng(baseCoords.lat + latDelta, baseCoords.lon + lonDelta),
    );

    final update = CameraUpdate.newLatLngBounds(bounds, 32);
    unawaited(
      animate
          ? _mapController?.animateCamera(update)
          : _mapController?.moveCamera(update),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    final baseCoords = widget.collar.baseCoords;
    final catCoords = widget.collar.coords;
    final isDark = theme.brightness == Brightness.dark;
    final mapStyle = isDark ? AppMapStyles.darkM3 : AppMapStyles.lightM3;

    final topPadding = MediaQuery.paddingOf(context).top + 84;
    const bottomPadding = 340.0;

    final radiusM = widget.collar.config.maxDistanceM <= 0
        ? 100.0
        : widget.collar.config.maxDistanceM.toDouble();
    final initialZoom = _calculateZoomForRadius(radiusM, baseCoords.lat);

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(baseCoords.lat, baseCoords.lon),
            zoom: initialZoom,
          ),
          style: mapStyle,
          padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
          myLocationEnabled: _hasLocationPermission,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          onTap: (_) {
            if (_selectedMarker != _SelectedMarkerType.none) {
              setState(() {
                _selectedMarker = _SelectedMarkerType.none;
              });
            }
          },
          circles: {
            if (widget.collar.config.maxDistanceM > 0)
              Circle(
                circleId: const CircleId('geofence_circle'),
                center: LatLng(baseCoords.lat, baseCoords.lon),
                radius: widget.collar.config.maxDistanceM.toDouble(),
                strokeWidth: 2,
                strokeColor: colorScheme.primary.withValues(alpha: 0.65),
                fillColor: colorScheme.primary.withValues(alpha: 0.12),
              ),
          },
          markers: {
            Marker(
              markerId: const MarkerId('base_station'),
              position: LatLng(baseCoords.lat, baseCoords.lon),
              anchor: const Offset(0.5, 0.5),
              zIndexInt: 1,
              icon:
                  _baseMarkerIcon ??
                  BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueCyan,
                  ),
              onTap: () => unawaited(_selectMarker(_SelectedMarkerType.base)),
            ),
            if (catCoords.lat != 0 || catCoords.lon != 0)
              Marker(
                markerId: const MarkerId('cat_location'),
                position: LatLng(catCoords.lat, catCoords.lon),
                anchor: const Offset(0.5, 0.5),
                zIndexInt: 2,
                icon:
                    _catMarkerIcon ??
                    BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure,
                    ),
                onTap: () => unawaited(_selectMarker(_SelectedMarkerType.cat)),
              ),
          },
          onMapCreated: (controller) {
            _mapController = controller;
            _currentCameraPosition = CameraPosition(
              target: LatLng(baseCoords.lat, baseCoords.lon),
              zoom: initialZoom,
            );
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fitMaxDistanceRange(animate: false);
            });
          },
          onCameraMove: (position) {
            _currentCameraPosition = position;
            if (_bearingNotifier.value != position.bearing) {
              _bearingNotifier.value = position.bearing;
            }
            if (position.zoom != _currentZoom) {
              _currentZoom = position.zoom;
            }
            if (_selectedMarker != _SelectedMarkerType.none) {
              unawaited(_updateInfoWindowPosition());
            }
          },
        ),

        if (_distanceToCatM != null)
          Positioned(
            bottom: bottomPadding + 10,
            left: 16,
            right: 16,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _goToCatLocation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh.withValues(
                        alpha: 0.94,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedRoute01,
                          color: colorScheme.primary,
                          size: 16,
                          strokeWidth: 2,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            l10n.homeDistanceToPet(
                              _formatDistance(_distanceToCatM!),
                            ),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

        if (_selectedMarker != _SelectedMarkerType.none)
          Positioned(
            left: _infoWindowX,
            top:
                _infoWindowY -
                (_selectedMarker == _SelectedMarkerType.cat ? 28.0 : 35.0),
            child: FractionalTranslation(
              translation: const Offset(-0.5, -1),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedMarker = _SelectedMarkerType.none;
                  });
                },
                child: CalloutBubble(
                  title: _selectedMarker == _SelectedMarkerType.cat
                      ? widget.collar.name
                      : l10n.homeMyLocationTooltip,
                  subtitle: _selectedMarker == _SelectedMarkerType.cat
                      ? (_distanceToCatM != null
                            ? l10n.homeDistanceToPet(
                                _formatDistance(_distanceToCatM!),
                              )
                            : null)
                      : (widget.collar.config.maxDistanceM > 0
                            ? l10n.homeSafeZoneRadius(
                                widget.collar.config.maxDistanceM,
                              )
                            : null),
                  colorScheme: colorScheme,
                  theme: theme,
                  leading: _selectedMarker == _SelectedMarkerType.cat
                      ? Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedPawPrint,
                              color: colorScheme.primary,
                              size: 14,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: colorScheme.secondary.withValues(
                              alpha: 0.15,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedRadioTower,
                              color: colorScheme.secondary,
                              size: 14,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),

        HomeMapControls(
          topPadding: topPadding,
          bearingNotifier: _bearingNotifier,
          onZoomIn: _zoomIn,
          onResetNorth: _resetNorth,
          onZoomOut: _zoomOut,
          onMyLocation: _goToMyLocation,
          onCatLocation: _goToCatLocation,
          onFitRange: _fitMaxDistanceRange,
        ),
      ],
    );
  }
}
