import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/home/home.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final darkTheme = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      extendBodyBehindAppBar: true,
      appBar: ExpressiveTopAppBar(
        showBackButton: false,
        backgroundColor: Colors.transparent,
        toolbarHeight: 70,
        titleSpacing: 16,
        centerTitle: false,
        title: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.4),
                  ),
                ),
                padding: const EdgeInsets.all(5),
                child: Image.asset(
                  darkTheme
                      ? AppVariables.logoNoBgDark
                      : AppVariables.logoNoBgLight,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Michin',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'En línea',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '  •  hace 20s',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ExpressiveIconButton.circle(
              variant: ExpressiveIconButtonVariant.tonal,
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedPawPrint,
                color: colorScheme.primary,
                strokeWidth: 2,
              ),
              onPressed: () {
                // Mascotas
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ExpressiveIconButton.circle(
              variant: ExpressiveIconButtonVariant.tonal,
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedSettings02,
                color: colorScheme.onSurfaceVariant,
                strokeWidth: 2,
              ),
              tooltip: 'Ajustes',
              onPressed: () => unawaited(context.push(AppRoute.settings.path)),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Mapa placeholder de fondo con marcadores y controles flotantes
          Positioned.fill(
            child: BlocBuilder<HomeCubit, HomeState>(
              builder: (context, state) {
                return _HomeMapPlaceholder(zoom: state.zoom);
              },
            ),
          ),

          // Panel inferior de telemetría y métricas
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _HomeTelemetryPanel(),
          ),
        ],
      ),
    );
  }
}

/// Placeholder de mapa estilizado que adapta sus colores al tema M3 activo.
class _HomeMapPlaceholder extends StatelessWidget {
  const _HomeMapPlaceholder({required this.zoom});

  final double zoom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        // Posiciones relativas para los marcadores en el mapa
        final basePos = Offset(width * 0.47, height * 0.38);
        final michinPos = Offset(width * 0.76, height * 0.20);
        final geofenceCenter = basePos;
        final geofenceRadius = width * 0.44;

        return Stack(
          children: [
            // Lienzo que dibuja el mapa blueprint adaptado al tema
            Positioned.fill(
              child: CustomPaint(
                painter: _MapBlueprintPainter(
                  colorScheme: colorScheme,
                  basePos: basePos,
                  michinPos: michinPos,
                  geofenceCenter: geofenceCenter,
                  geofenceRadius: geofenceRadius,
                  zoom: zoom,
                ),
              ),
            ),

            // Etiqueta de la geovalla segura
            Positioned(
              left: width * 0.08,
              top: height * 0.28,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.92,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedShield01,
                      size: 15,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'GEOVALLA SEGURA (500M)',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Marcador: Base ESP32 • Casa
            Positioned(
              left: basePos.dx - 60,
              top: basePos.dy - 35,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.tertiary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.tertiary.withValues(alpha: 0.45),
                          blurRadius: 18,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedHome01,
                        color: colorScheme.onTertiary,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.92,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: colorScheme.tertiary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Base ESP32  •  Casa',
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurface,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Marcador: Michin (Mascota)
            Positioned(
              left: michinPos.dx - 55,
              top: michinPos.dy - 55,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Halo temático de pulso
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                      ),
                      // Flecha direccional
                      Positioned(
                        top: -6,
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowUp01,
                          size: 28,
                          color: colorScheme.primary.withValues(alpha: 0.9),
                        ),
                      ),
                      // Avatar squircle de Michin
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: colorScheme.primary,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(7),
                        child: Image.asset(
                          theme.brightness == Brightness.dark
                              ? AppVariables.logoNoBgDark
                              : AppVariables.logoNoBgLight,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.92,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Michin  •  1.4 km/h',
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurface,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Controles de Zoom a la izquierda
            Positioned(
              left: 16,
              top: 140,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh.withValues(
                    alpha: 0.92,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedAdd01,
                        color: colorScheme.onSurface,
                        size: 20,
                      ),
                      onPressed: () {
                        context.read<HomeCubit>().updateZoom(zoom + 1);
                      },
                    ),
                    Container(
                      width: 28,
                      height: 1,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    IconButton(
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedRemove01,
                        color: colorScheme.onSurface,
                        size: 20,
                      ),
                      onPressed: () {
                        context.read<HomeCubit>().updateZoom(
                          math.max(1, zoom - 1),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Botones de acción del mapa flotantes a la derecha
            Positioned(
              right: 16,
              top: 130,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExpressiveIconButton.circle(
                    variant: ExpressiveIconButtonVariant.tonal,
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedTarget02,
                      color: colorScheme.primary,
                      strokeWidth: 2,
                    ),
                    onPressed: () {},
                  ),
                  const SizedBox(height: 12),
                  ExpressiveIconButton.circle(
                    variant: ExpressiveIconButtonVariant.tonal,
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedHome01,
                      color: colorScheme.tertiary,
                      strokeWidth: 2,
                    ),
                    onPressed: () {},
                  ),
                  const SizedBox(height: 12),
                  ExpressiveIconButton.circle(
                    variant: ExpressiveIconButtonVariant.tonal,
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedChart01,
                      color: colorScheme.onSurfaceVariant,
                      strokeWidth: 2,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Painter para simular un mapa blueprint con carreteras, geovalla y
/// trayectoria que utiliza la paleta de colores del [ColorScheme] activo.
class _MapBlueprintPainter extends CustomPainter {
  const _MapBlueprintPainter({
    required this.colorScheme,
    required this.basePos,
    required this.michinPos,
    required this.geofenceCenter,
    required this.geofenceRadius,
    required this.zoom,
  });

  final ColorScheme colorScheme;
  final Offset basePos;
  final Offset michinPos;
  final Offset geofenceCenter;
  final double geofenceRadius;
  final double zoom;

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = colorScheme.surfaceContainerLowest;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Bloques urbanos adaptados a surfaceContainerLow
    final blockPaint = Paint()
      ..color = colorScheme.surfaceContainerLow
      ..style = PaintingStyle.fill;

    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * 0.06, size.height * 0.16, 90, 80),
          const Radius.circular(16),
        ),
        blockPaint,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * 0.08, size.height * 0.36, 110, 60),
          const Radius.circular(16),
        ),
        blockPaint,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * 0.38, size.height * 0.12, 100, 110),
          const Radius.circular(16),
        ),
        blockPaint,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * 0.65, size.height * 0.24, 120, 80),
          const Radius.circular(16),
        ),
        blockPaint,
      );

    // Calles estilizadas con surfaceContainerHigh
    final streetPaint = Paint()
      ..color = colorScheme.surfaceContainerHigh
      ..style = PaintingStyle.stroke
      ..strokeWidth = 32
      ..strokeCap = StrokeCap.round;

    final roadPath1 = Path()
      ..moveTo(-20, size.height * 0.32)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.34,
        size.width * 0.5,
        size.height * 0.28,
        size.width + 20,
        size.height * 0.32,
      );
    canvas.drawPath(roadPath1, streetPaint);

    final roadPath2 = Path()
      ..moveTo(size.width * 0.28, -20)
      ..lineTo(size.width * 0.28, size.height * 0.6);
    canvas.drawPath(roadPath2, streetPaint);

    final roadPath3 = Path()
      ..moveTo(size.width * 0.58, -20)
      ..cubicTo(
        size.width * 0.58,
        size.height * 0.25,
        size.width * 0.52,
        size.height * 0.4,
        size.width * 0.50,
        size.height * 0.65,
      );
    canvas.drawPath(roadPath3, streetPaint);

    // Circunferencia de Geovalla (línea discontinua con color primario)
    final geofencePaint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    _drawDashedCircle(
      canvas,
      geofenceCenter,
      geofenceRadius,
      geofencePaint,
      dashLength: 8,
      gapLength: 7,
    );

    // Trayectoria punteada desde Base hacia Michin con color primario
    final trajectoryPaint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final path = Path()
      ..moveTo(basePos.dx, basePos.dy)
      ..cubicTo(
        basePos.dx - 20,
        basePos.dy - 60,
        michinPos.dx - 60,
        michinPos.dy + 80,
        michinPos.dx,
        michinPos.dy,
      );

    _drawDashedPath(canvas, path, trajectoryPaint, gapLength: 8);

    // Puntos intermedios en la trayectoria
    final dotPaint = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.fill;

    canvas
      ..drawCircle(Offset(basePos.dx - 12, basePos.dy - 40), 3.5, dotPaint)
      ..drawCircle(Offset(basePos.dx + 16, basePos.dy - 85), 3.5, dotPaint)
      ..drawCircle(Offset(michinPos.dx - 45, michinPos.dy + 48), 3.5, dotPaint);
  }

  void _drawDashedCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint, {
    double dashLength = 6,
    double gapLength = 6,
  }) {
    final circumference = 2 * math.pi * radius;
    final dashCount = (circumference / (dashLength + gapLength)).floor();
    final adjustedGap = (circumference - (dashCount * dashLength)) / dashCount;
    final sweepAngle = dashLength / radius;
    final gapAngle = adjustedGap / radius;

    var currentAngle = 0.0;
    for (var i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle,
        sweepAngle,
        false,
        paint,
      );
      currentAngle += sweepAngle + gapAngle;
    }
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint, {
    double dashLength = 6,
    double gapLength = 6,
  }) {
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final length = math.min(dashLength, metric.length - distance);
        final extractPath = metric.extractPath(distance, distance + length);
        canvas.drawPath(extractPath, paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MapBlueprintPainter oldDelegate) {
    return oldDelegate.zoom != zoom ||
        oldDelegate.basePos != basePos ||
        oldDelegate.michinPos != michinPos ||
        oldDelegate.colorScheme != colorScheme;
  }
}

/// Panel inferior estilizado con métricas de telemetría y botón de acción
/// principal, integrado completamente al [ColorScheme] activo.
class _HomeTelemetryPanel extends StatelessWidget {
  const _HomeTelemetryPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final darkTheme = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: darkTheme ? 0.4 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cuadrícula 2x2 de métricas con tamaño uniforme
            Row(
              children: [
                // Tarjeta 1: Distancia
                Expanded(
                  child: _MetricCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'DISTANCIA',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'ZONA SEGURA',
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '124',
                              style: textTheme.headlineMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'm de casa',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Tarjeta 2: Batería collar
                Expanded(
                  child: _MetricCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'BATERÍA COLLAR',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedBatteryCharging01,
                              color: colorScheme.primary,
                              size: 17,
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '85%',
                                  style: textTheme.headlineMedium?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '3.95 V',
                                  style: textTheme.titleSmall?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                height: 5,
                                color: colorScheme.surfaceContainerHighest,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor: 0.85,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                // Tarjeta 3: Posicionamiento
                Expanded(
                  child: _MetricCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'POSICIONAMIENTO',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedSatellite01,
                              color: colorScheme.secondary,
                              size: 16,
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: colorScheme.secondary.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                              child: Text(
                                '3D Fix',
                                style: textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '15 Satélites activos',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Tarjeta 4: Enlace LoRa
                Expanded(
                  child: _MetricCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'ENLACE LORA',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                Text(
                                  '915M',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.7),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            // Indicador de barras de señal
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _signalBar(context, 6, active: true),
                                const SizedBox(width: 2.5),
                                _signalBar(context, 9, active: true),
                                const SizedBox(width: 2.5),
                                _signalBar(context, 13, active: true),
                                const SizedBox(width: 2.5),
                                _signalBar(context, 17, active: false),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '-92',
                                  style: textTheme.headlineMedium?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'dBm',
                                  style: textTheme.titleSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'SNR: +8.5 dB (Óptimo)',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Botón de acción principal M3 Expressive
            ExpressiveButton.filled(
              onPressed: () {
                // Telemetría detallada
              },
              label: 'Ver telemetría detallada y umbrales',
              size: ExpressiveButtonSize.large,
              isExpanded: true,
              trailingIcon: const HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight02,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _signalBar(
    BuildContext context,
    double height, {
    required bool active,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 3.5,
      height: height,
      decoration: BoxDecoration(
        color: active
            ? colorScheme.primary
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Tarjeta contenedora para cada métrica con estilo M3 Expressive
class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: child,
    );
  }
}
