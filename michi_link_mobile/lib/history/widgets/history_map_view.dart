import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:expressive_kit/expressive_kit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/l10n/l10n.dart';

class HistoryMapView extends StatefulWidget {
  const HistoryMapView({
    required this.records,
    this.selectedRecord,
    this.onRecordSelected,
    super.key,
  });

  final List<HistoryRecord> records;
  final HistoryRecord? selectedRecord;
  final ValueChanged<HistoryRecord?>? onRecordSelected;

  @override
  State<HistoryMapView> createState() => _HistoryMapViewState();
}

class _HistoryMapViewState extends State<HistoryMapView> {
  GoogleMapController? _mapController;
  BitmapDescriptor? _catMarkerIcon;
  BitmapDescriptor? _pointMarkerIcon;
  BitmapDescriptor? _selectedPointMarkerIcon;
  Brightness? _lastBrightness;
  double? _lastPixelRatio;

  final ValueNotifier<double> _bearingNotifier = ValueNotifier<double>(0);
  CameraPosition? _currentCameraPosition;
  double _currentZoom = 16;

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

    if (_lastBrightness != brightness || _lastPixelRatio != pixelRatio) {
      _lastBrightness = brightness;
      _lastPixelRatio = pixelRatio;
      unawaited(_loadCustomMarkers());
    }
  }

  @override
  void didUpdateWidget(HistoryMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.records != widget.records) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitRouteBounds();
      });
    }
    if (widget.selectedRecord != null &&
        oldWidget.selectedRecord != widget.selectedRecord) {
      final coords = widget.selectedRecord!.coords;
      if (coords.lat != 0 || coords.lon != 0) {
        unawaited(
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(LatLng(coords.lat, coords.lon)),
          ),
        );
      }
    }
  }

  Future<BitmapDescriptor> _createSvgMarker({
    required BytesLoader loader,
    required Color borderColor,
    required Color bgColor,
    required double markerSize,
    required double contentSize,
    double borderWidth = 2.5,
    double pixelRatio = 1.0,
  }) async {
    final pictureInfo = await vg.loadPicture(loader, null);
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder)..scale(pixelRatio);

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
    final targetSize = (markerSize * pixelRatio).round();
    final img = await picture.toImage(targetSize, targetSize);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      byteData!.buffer.asUint8List(),
      imagePixelRatio: pixelRatio,
    );
  }

  Future<BitmapDescriptor> _createDotMarker({
    required Color fillColor,
    required Color strokeColor,
    required double dotDiameter,
    double canvasSize = 32.0,
    double strokeWidth = 2.0,
    double pixelRatio = 1.0,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder)..scale(pixelRatio);

    final center = Offset(canvasSize / 2, canvasSize / 2);
    final radius = dotDiameter / 2;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    canvas
      ..drawCircle(center.translate(0, 1), radius + strokeWidth, shadowPaint)
      ..drawCircle(center, radius + strokeWidth, strokePaint)
      ..drawCircle(center, radius, fillPaint);

    final picture = recorder.endRecording();
    final targetSize = (canvasSize * pixelRatio).round();
    final img = await picture.toImage(targetSize, targetSize);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      byteData!.buffer.asUint8List(),
      imagePixelRatio: pixelRatio,
    );
  }

  Future<void> _loadCustomMarkers() async {
    try {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      final isDark = theme.brightness == Brightness.dark;
      final pixelRatio =
          MediaQuery.maybeDevicePixelRatioOf(context) ??
          View.of(context).devicePixelRatio;

      final catIcon = await _createSvgMarker(
        loader: SvgAssetLoader(CatBreed.europeanOrangeWhite.assetPath),
        borderColor: colorScheme.primary,
        bgColor: isDark ? colorScheme.surfaceContainerHigh : Colors.white,
        markerSize: 48,
        contentSize: 30,
        borderWidth: 2.2,
        pixelRatio: pixelRatio,
      );

      final dotIcon = await _createDotMarker(
        fillColor: colorScheme.primary,
        strokeColor: isDark ? const Color(0xFF1E2628) : Colors.white,
        dotDiameter: 10,
        pixelRatio: pixelRatio,
      );

      final selectedDotIcon = await _createDotMarker(
        fillColor: Colors.white,
        strokeColor: colorScheme.primary,
        dotDiameter: 14,
        strokeWidth: 3.5,
        canvasSize: 36,
        pixelRatio: pixelRatio,
      );

      if (mounted) {
        setState(() {
          _catMarkerIcon = catIcon;
          _pointMarkerIcon = dotIcon;
          _selectedPointMarkerIcon = selectedDotIcon;
        });
      }
    } on Exception catch (_) {}
  }

  void _zoomIn() {
    unawaited(_mapController?.animateCamera(CameraUpdate.zoomIn()));
  }

  void _zoomOut() {
    unawaited(_mapController?.animateCamera(CameraUpdate.zoomOut()));
  }

  void _resetNorth() {
    final controller = _mapController;
    if (controller == null) return;
    final currentPos = _currentCameraPosition;
    if (currentPos != null) {
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
  }

  void _fitRouteBounds() {
    final controller = _mapController;
    if (controller == null) return;

    final validRecords = widget.records
        .where((r) => r.coords.lat != 0 || r.coords.lon != 0)
        .toList();

    if (validRecords.isEmpty) return;

    if (validRecords.length == 1) {
      final point = validRecords.first.coords;
      unawaited(
        controller.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(point.lat, point.lon),
            AppVariables.mapFocusZoom,
          ),
        ),
      );
      return;
    }

    var minLat = validRecords.first.coords.lat;
    var maxLat = validRecords.first.coords.lat;
    var minLon = validRecords.first.coords.lon;
    var maxLon = validRecords.first.coords.lon;

    for (final r in validRecords) {
      final lat = r.coords.lat;
      final lon = r.coords.lon;
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lon < minLon) minLon = lon;
      if (lon > maxLon) maxLon = lon;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLon),
      northeast: LatLng(maxLat, maxLon),
    );

    unawaited(
      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mapStyle = isDark ? AppMapStyles.darkM3 : AppMapStyles.lightM3;

    final topPadding = MediaQuery.paddingOf(context).top + 84;
    const bottomPadding = 270.0;

    final validRecords = widget.records
        .where((r) => r.coords.lat != 0 || r.coords.lon != 0)
        .toList();

    // Chronological order for polyline (oldest to newest)
    final chronologicalRecords = validRecords.reversed.toList();
    final polylinePoints = chronologicalRecords
        .map((r) => LatLng(r.coords.lat, r.coords.lon))
        .toList();

    final markers = <Marker>{};

    // Point markers for every packet/record in the route
    for (var i = 0; i < chronologicalRecords.length; i++) {
      final record = chronologicalRecords[i];
      final isSelected =
          widget.selectedRecord?.seq == record.seq &&
          widget.selectedRecord?.timestamp == record.timestamp;

      markers.add(
        Marker(
          markerId: MarkerId(
            'history_point_${record.seq}_'
            '${record.timestamp.millisecondsSinceEpoch}',
          ),
          position: LatLng(record.coords.lat, record.coords.lon),
          anchor: const Offset(0.5, 0.5),
          zIndexInt: isSelected ? 20 : 10,
          icon: isSelected
              ? (_selectedPointMarkerIcon ??
                    BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueOrange,
                    ))
              : (_pointMarkerIcon ??
                    BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueCyan,
                    )),
          onTap: () => widget.onRecordSelected?.call(record),
        ),
      );
    }

    // Route End / Latest Cat Position Marker (no white info window)
    if (chronologicalRecords.isNotEmpty) {
      final end = chronologicalRecords.last;
      markers.add(
        Marker(
          markerId: const MarkerId('history_route_end'),
          position: LatLng(end.coords.lat, end.coords.lon),
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 30,
          icon:
              _catMarkerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          onTap: () => widget.onRecordSelected?.call(end),
        ),
      );
    }

    final polylines = <Polyline>{};
    if (polylinePoints.length >= 2) {
      final segmentCount = polylinePoints.length - 1;
      for (var i = 0; i < segmentCount; i++) {
        // Gradient opacity: older segments are more transparent,
        // newest segment has full opacity (alpha: 1.0).
        final progress = segmentCount > 1 ? i / (segmentCount - 1) : 1.0;
        final alpha = (0.20 + (0.80 * progress)).clamp(0.20, 1.0);
        polylines.add(
          Polyline(
            polylineId: PolylineId('history_segment_$i'),
            points: [polylinePoints[i], polylinePoints[i + 1]],
            color: colorScheme.primary.withValues(alpha: alpha),
            width: 4,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            geodesic: true,
            zIndex: i,
          ),
        );
      }
    }

    final initialTarget = validRecords.isNotEmpty
        ? LatLng(validRecords.first.coords.lat, validRecords.first.coords.lon)
        : const LatLng(0, 0);

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialTarget,
            zoom: 16,
          ),
          style: mapStyle,
          padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          polylines: polylines,
          markers: markers,
          onMapCreated: (controller) {
            _mapController = controller;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fitRouteBounds();
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
          },
          onTap: (_) {
            if (widget.selectedRecord != null) {
              widget.onRecordSelected?.call(null);
            }
          },
        ),

        // Floating Map Controls (Top Right), matching home_map_view.dart
        Positioned(
          top: topPadding,
          left: 16,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.92),
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
                    icon: HugeIcons.strokeRoundedZoomIn,
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
                  icon: ValueListenableBuilder<double>(
                    valueListenable: _bearingNotifier,
                    builder: (context, bearing, child) {
                      return Transform.rotate(
                        angle: -bearing * (math.pi / 180),
                        child: child,
                      );
                    },
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowUp04,
                      color: colorScheme.onSurface,
                      strokeWidth: 2,
                    ),
                  ),
                  tooltip: l10n.homeResetNorthTooltip,
                  onPressed: _resetNorth,
                ),
                Divider(
                  height: 6,
                  indent: 6,
                  endIndent: 6,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
                ExpressiveIconButton.circle(
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedZoomOut,
                    color: colorScheme.onSurface,
                    strokeWidth: 2,
                  ),
                  tooltip: l10n.homeZoomOutTooltip,
                  onPressed: _zoomOut,
                ),
              ],
            ),
          ),
        ),

        // If no records in this period, display an informative overlay over
        // the map
        if (validRecords.isEmpty)
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedLocationOffline01,
                        color: colorScheme.primary,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.historyEmptyTitle,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.historyEmptyDescription,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
