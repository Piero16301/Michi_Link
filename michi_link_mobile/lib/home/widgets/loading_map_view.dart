import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/home/home.dart';
import 'package:shimmer/shimmer.dart';

class LoadingMapView extends StatelessWidget {
  const LoadingMapView({this.collarId, super.key});

  final String? collarId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                width: 46,
                height: 46,
                padding: const EdgeInsets.all(2),
                child: Center(
                  child: _shimmerBox(
                    context,
                    width: 40,
                    height: 40,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _shimmerBox(context, width: 84, height: 16),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _shimmerBox(
                        context,
                        width: 7,
                        height: 7,
                        shape: BoxShape.circle,
                      ),
                      const SizedBox(width: 5),
                      _shimmerBox(
                        context,
                        width: 46,
                        height: 10,
                        borderRadius: 3,
                      ),
                      const SizedBox(width: 6),
                      _shimmerBox(
                        context,
                        width: 50,
                        height: 10,
                        borderRadius: 3,
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
            child: _shimmerBox(
              context,
              width: 40,
              height: 40,
              shape: BoxShape.circle,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _shimmerBox(
              context,
              width: 40,
              height: 40,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: colorScheme.surfaceContainerLowest,
              child: Center(
                child: _shimmerBox(
                  context,
                  width: 56,
                  height: 56,
                  borderRadius: 16,
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 28,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: const BorderRadius.all(Radius.circular(32)),
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Fila 1: Batería y Constelación
                  Row(
                    children: [
                      // Cuadro 1: Batería
                      Expanded(
                        child: MetricCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _shimmerBox(
                                        context,
                                        width: 52,
                                        height: 11,
                                        borderRadius: 3,
                                      ),
                                      _shimmerBox(
                                        context,
                                        width: 18,
                                        height: 18,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      _shimmerBox(
                                        context,
                                        width: 44,
                                        height: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      _shimmerBox(
                                        context,
                                        width: 40,
                                        height: 11,
                                        borderRadius: 3,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _shimmerBox(
                                context,
                                width: double.infinity,
                                height: 7,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Cuadro 2: Constelación
                      Expanded(
                        child: MetricCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _shimmerBox(
                                        context,
                                        width: 78,
                                        height: 11,
                                        borderRadius: 3,
                                      ),
                                      _shimmerBox(
                                        context,
                                        width: 18,
                                        height: 18,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  _shimmerBox(context, width: 68, height: 18),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _shimmerBox(
                                    context,
                                    width: 6,
                                    height: 6,
                                    shape: BoxShape.circle,
                                  ),
                                  const SizedBox(width: 5),
                                  _shimmerBox(
                                    context,
                                    width: 55,
                                    height: 10,
                                    borderRadius: 3,
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

                  // Fila 2: Señal y Paquetes
                  Row(
                    children: [
                      // Cuadro 3: Señal LoRa
                      Expanded(
                        child: MetricCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _shimmerBox(
                                        context,
                                        width: 66,
                                        height: 11,
                                        borderRadius: 3,
                                      ),
                                      _shimmerBox(
                                        context,
                                        width: 20,
                                        height: 13,
                                        borderRadius: 2,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      _shimmerBox(
                                        context,
                                        width: 56,
                                        height: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      _shimmerBox(
                                        context,
                                        width: 54,
                                        height: 11,
                                        borderRadius: 3,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _shimmerBox(
                                    context,
                                    width: 16,
                                    height: 16,
                                    borderRadius: 3,
                                  ),
                                  const SizedBox(width: 5),
                                  _shimmerBox(
                                    context,
                                    width: 70,
                                    height: 10,
                                    borderRadius: 3,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Cuadro 4: Paquetes y Pérdida
                      Expanded(
                        child: MetricCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _shimmerBox(
                                        context,
                                        width: 52,
                                        height: 11,
                                        borderRadius: 3,
                                      ),
                                      _shimmerBox(
                                        context,
                                        width: 18,
                                        height: 18,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      _shimmerBox(
                                        context,
                                        width: 44,
                                        height: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      _shimmerBox(
                                        context,
                                        width: 44,
                                        height: 11,
                                        borderRadius: 3,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _shimmerBox(
                                      context,
                                      width: double.infinity,
                                      height: 7,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  _shimmerBox(
                                    context,
                                    width: 40,
                                    height: 10,
                                    borderRadius: 3,
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

                  // Botón Configurar collar
                  _shimmerBox(
                    context,
                    width: double.infinity,
                    height: 48,
                    borderRadius: 24,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _shimmerBox(
    BuildContext context, {
    required double width,
    required double height,
    double borderRadius = 4,
    BoxShape shape = BoxShape.rectangle,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Shimmer.fromColors(
      baseColor: isDark
          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      highlightColor: isDark
          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.9)
          : colorScheme.surfaceContainerLowest,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: shape,
          borderRadius: shape == BoxShape.circle
              ? null
              : BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
