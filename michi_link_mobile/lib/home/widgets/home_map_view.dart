import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
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
  double _currentZoom = 17;
  bool _hasLocationPermission = false;
  Position? _userPosition;
  double? _distanceToCatM;

  BitmapDescriptor? _catMarkerIcon;
  BitmapDescriptor? _baseMarkerIcon;
  Brightness? _lastBrightness;
  CatBreed? _lastBreed;

  _SelectedMarkerType _selectedMarker = _SelectedMarkerType.none;
  double _infoWindowX = 0;
  double _infoWindowY = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_checkInitialLocation());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final brightness = Theme.of(context).brightness;
    // Carga los marcadores personalizados si cambia el brillo o la raza
    if (_lastBrightness != brightness || _lastBreed != widget.collar.breed) {
      _lastBrightness = brightness;
      _lastBreed = widget.collar.breed;
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

  String _buildHugeIconSvg(
    List<List<dynamic>> iconData,
    Color color, {
    double strokeWidth = 2.0,
  }) {
    final hexColor =
        '#${(color.toARGB32() & 0x00FFFFFF).toRadixString(16).padLeft(6, '0')}';
    final buffer = StringBuffer()
      ..write(
        '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">',
      );
    for (final element in iconData) {
      final tagName = element[0] as String;
      final attributes = element[1] as Map<String, dynamic>;
      buffer.write('<$tagName');
      for (final entry in attributes.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key == 'key' || key == 'opacity') continue;
        var finalValue = value.toString();
        if (key == 'stroke' || key == 'fill') {
          finalValue = hexColor;
        } else if (key == 'strokeWidth') {
          finalValue = strokeWidth.toString();
        }
        final svgKey = key.replaceAllMapped(
          RegExp('[A-Z]'),
          (m) => '-${m[0]!.toLowerCase()}',
        );
        buffer.write(' $svgKey="$finalValue"');
      }
      buffer.write('/>');
    }
    buffer.write('</svg>');
    return buffer.toString();
  }

  // Construye un marcador SVG personalizado
  Future<BitmapDescriptor> _createSvgMarker({
    required BytesLoader loader,
    required Color borderColor,
    required Color bgColor,
    required double markerSize,
    required double contentSize,
    double borderWidth = 2.5,
  }) async {
    final pictureInfo = await vg.loadPicture(loader, null);
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    final center = Offset(markerSize / 2, markerSize / 2);
    final radius = (markerSize / 2) - 4;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill;

    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill;

    final clipPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius - borderWidth));

    final srcWidth = pictureInfo.size.width;
    final srcHeight = pictureInfo.size.height;
    final scale = contentSize / math.max(srcWidth, srcHeight);
    final dx = center.dx - (srcWidth * scale) / 2;
    final dy = center.dy - (srcHeight * scale) / 2;

    canvas
      ..drawCircle(center.translate(0, 2), radius, shadowPaint)
      ..drawCircle(center, radius, borderPaint)
      ..drawCircle(center, radius - borderWidth, bgPaint)
      ..save()
      ..clipPath(clipPath)
      ..translate(dx, dy)
      ..scale(scale, scale)
      ..drawPicture(pictureInfo.picture)
      ..restore();

    final picture = recorder.endRecording();
    final img = await picture.toImage(markerSize.toInt(), markerSize.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  Future<void> _loadCustomMarkers() async {
    try {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      final isDark = theme.brightness == Brightness.dark;

      final catIcon = await _createSvgMarker(
        loader: SvgAssetLoader(widget.collar.breed.assetPath),
        borderColor: colorScheme.primary,
        bgColor: isDark ? colorScheme.surfaceContainerHigh : Colors.white,
        markerSize: 48,
        contentSize: 30,
        borderWidth: 2.2,
      );

      final baseSvg = _buildHugeIconSvg(
        HugeIcons.strokeRoundedRadioTower,
        colorScheme.primary,
      );
      final baseIcon = await _createSvgMarker(
        loader: SvgStringLoader(baseSvg),
        borderColor: colorScheme.secondary,
        bgColor: isDark ? colorScheme.surfaceContainerHigh : Colors.white,
        markerSize: 62,
        contentSize: 38,
        borderWidth: 2.8,
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
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fitMaxDistanceRange(animate: false);
            });
          },
          onCameraMove: (position) {
            if (position.zoom != _currentZoom) {
              _currentZoom = position.zoom;
              debugPrint('Zoom: $_currentZoom');
            }
            if (_selectedMarker != _SelectedMarkerType.none) {
              unawaited(_updateInfoWindowPosition());
            }
          },
        ),

        if (_distanceToCatM != null)
          Positioned(
            top: topPadding + 4,
            left: 72,
            right: 72,
            child: Center(
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
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
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
                child: _CalloutBubble(
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

        Positioned(
          left: 16,
          right: 16,
          top: topPadding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh.withValues(
                    alpha: 0.92,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExpressiveIconButton.circle(
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedAdd01,
                        color: colorScheme.onSurface,
                        strokeWidth: 2,
                      ),
                      tooltip: l10n.homeZoomInTooltip,
                      onPressed: _zoomIn,
                    ),
                    Divider(
                      height: 6,
                      indent: 6,
                      endIndent: 6,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                    ExpressiveIconButton.circle(
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedMinusSign,
                        color: colorScheme.onSurface,
                        strokeWidth: 2,
                      ),
                      tooltip: l10n.homeZoomOutTooltip,
                      onPressed: _zoomOut,
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh.withValues(
                    alpha: 0.92,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExpressiveIconButton.circle(
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedNavigation03,
                        color: colorScheme.onSurface,
                        strokeWidth: 2,
                      ),
                      tooltip: l10n.homeMyLocationTooltip,
                      onPressed: _goToMyLocation,
                    ),
                    const SizedBox(height: 2),
                    ExpressiveIconButton.circle(
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedPawPrint,
                        color: colorScheme.primary,
                        strokeWidth: 2,
                      ),
                      tooltip: l10n.homeCatLocationTooltip,
                      onPressed: _goToCatLocation,
                    ),
                    const SizedBox(height: 2),
                    ExpressiveIconButton.circle(
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedTarget02,
                        color: colorScheme.onSurface,
                        strokeWidth: 2,
                      ),
                      tooltip: l10n.homeFitRangeTooltip,
                      onPressed: _fitMaxDistanceRange,
                    ),
                    const SizedBox(height: 2),
                    ExpressiveIconButton.circle(
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedClock01,
                        color: colorScheme.onSurfaceVariant,
                        strokeWidth: 2,
                      ),
                      tooltip: l10n.homeLocationHistoryTooltip,
                      onPressed: widget.onHistoryPressed ?? () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CalloutBubble extends StatelessWidget {
  const _CalloutBubble({
    required this.title,
    required this.colorScheme,
    required this.theme,
    this.subtitle,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.65),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 8)],
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        CustomPaint(
          size: const Size(12, 6),
          painter: _TriangleArrowPainter(
            color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.96),
            borderColor: colorScheme.outlineVariant.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }
}

class _TriangleArrowPainter extends CustomPainter {
  const _TriangleArrowPainter({required this.color, required this.borderColor});

  final Color color;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    final fillPaint = Paint()..color = color;
    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas
      ..drawPath(path, fillPaint)
      ..drawLine(Offset.zero, Offset(size.width / 2, size.height), borderPaint)
      ..drawLine(
        Offset(size.width / 2, size.height),
        Offset(size.width, 0),
        borderPaint,
      );
  }

  @override
  bool shouldRepaint(_TriangleArrowPainter oldDelegate) =>
      color != oldDelegate.color || borderColor != oldDelegate.borderColor;
}
