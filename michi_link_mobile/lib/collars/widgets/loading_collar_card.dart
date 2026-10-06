import 'package:material_ui/material_ui.dart';
import 'package:shimmer/shimmer.dart';

class LoadingCollarCard extends StatelessWidget {
  const LoadingCollarCard({required this.collarId, super.key});

  final String collarId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final shortId = _getShortId(collarId);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: _shimmerBox(
                        context,
                        width: 50,
                        height: 50,
                        borderRadius: 14,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.surfaceContainer,
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(
                      context,
                      width: 110,
                      height: 20,
                      borderRadius: 6,
                    ),
                    const SizedBox(height: 5),
                    _shimmerBox(
                      context,
                      width: 74,
                      height: 18,
                      borderRadius: 8,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ID: ...$shortId',
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _shimmerBox(
                    context,
                    width: 32,
                    height: 32,
                    shape: BoxShape.circle,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _shimmerBox(
                        context,
                        width: 32,
                        height: 32,
                        shape: BoxShape.circle,
                      ),
                      const SizedBox(width: 6),
                      _shimmerBox(
                        context,
                        width: 32,
                        height: 32,
                        shape: BoxShape.circle,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _shimmerBox(
                                  context,
                                  width: 52,
                                  height: 11,
                                  borderRadius: 3,
                                ),
                                _shimmerBox(context, width: 18, height: 18),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _shimmerBox(context, width: 44, height: 18),
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
                        _shimmerBox(context, width: double.infinity, height: 7),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _shimmerBox(
                                  context,
                                  width: 78,
                                  height: 11,
                                  borderRadius: 3,
                                ),
                                _shimmerBox(context, width: 18, height: 18),
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
          ),
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _shimmerBox(context, width: 56, height: 18),
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
                            _shimmerBox(context, width: 16, height: 16),
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
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _shimmerBox(
                                  context,
                                  width: 52,
                                  height: 11,
                                  borderRadius: 3,
                                ),
                                _shimmerBox(context, width: 18, height: 18),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _shimmerBox(context, width: 44, height: 18),
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
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox(
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

  String _getShortId(String deviceId) {
    if (deviceId.contains('_')) {
      final parts = deviceId.split('_');
      final raw = parts.last;
      return raw.length >= 4
          ? raw.substring(raw.length - 4).toUpperCase()
          : raw;
    }
    return deviceId.length >= 4
        ? deviceId.substring(deviceId.length - 4).toUpperCase()
        : deviceId;
  }
}
