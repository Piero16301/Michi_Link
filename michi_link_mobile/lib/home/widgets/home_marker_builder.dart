import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:material_ui/material_ui.dart';

class HomeMarkerBuilder {
  static String buildHugeIconSvg(
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

  static Future<BitmapDescriptor> createSvgMarker({
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
}
