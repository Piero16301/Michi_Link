import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';

/// Indicador de carga de Material 3 Expressive con animación de morphing
/// y física de escala elástica entre formas redondeadas.
class ExpressiveLoadingIndicator extends StatefulWidget {
  const ExpressiveLoadingIndicator({
    this.size = 48,
    this.color,
    this.secondaryColor,
    super.key,
  });

  final double size;
  final Color? color;
  final Color? secondaryColor;

  @override
  State<ExpressiveLoadingIndicator> createState() =>
      _ExpressiveLoadingIndicatorState();
}

class _ExpressiveLoadingIndicatorState extends State<ExpressiveLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primary = widget.color ?? colorScheme.primary;
    final secondary = widget.secondaryColor ?? colorScheme.tertiary;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          final angle = t * 2 * math.pi;

          return Transform.rotate(
            angle: angle,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (index) {
                final offset = index * 0.25;
                final wave = math.sin((t * 2 * math.pi) + offset);
                final scale = 0.6 + (0.4 * wave.abs());
                final itemColor = Color.lerp(
                  primary,
                  secondary,
                  (wave + 1) / 2,
                )!;

                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: widget.size * 0.22,
                    height: widget.size * 0.22,
                    decoration: BoxDecoration(
                      color: itemColor,
                      borderRadius: BorderRadius.circular(widget.size * 0.11),
                    ),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }
}

/// Barra de progreso lineal de Material 3 Expressive con extremos redondeados
/// y animación elástica continua.
class ExpressiveLinearProgressIndicator extends StatelessWidget {
  const ExpressiveLinearProgressIndicator({
    this.value,
    this.height = 8,
    this.color,
    this.backgroundColor,
    this.borderRadius,
    super.key,
  });

  final double? value;
  final double height;
  final Color? color;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = color ?? colorScheme.primary;
    final trackColor = backgroundColor ?? colorScheme.surfaceContainerHighest;
    final radius = borderRadius ?? BorderRadius.circular(height / 2);

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: height,
        child: value != null
            ? LinearProgressIndicator(
                value: value,
                color: activeColor,
                backgroundColor: trackColor,
              )
            : LinearProgressIndicator(
                color: activeColor,
                backgroundColor: trackColor,
              ),
      ),
    );
  }
}

/// Indicador de progreso circular de Material 3 Expressive con remates
/// redondeados.
class ExpressiveCircularProgressIndicator extends StatelessWidget {
  const ExpressiveCircularProgressIndicator({
    this.value,
    this.size = 36,
    this.strokeWidth = 4,
    this.color,
    this.backgroundColor,
    super.key,
  });

  final double? value;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = color ?? colorScheme.primary;
    final trackColor = backgroundColor ?? colorScheme.surfaceContainerHighest;

    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        value: value,
        strokeWidth: strokeWidth,
        strokeCap: StrokeCap.round,
        color: activeColor,
        backgroundColor: trackColor,
      ),
    );
  }
}
