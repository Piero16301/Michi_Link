import 'package:material_ui/material_ui.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer placeholder for a history record card while loading
class LoadingHistoryCard extends StatelessWidget {
  const LoadingHistoryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
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
              _shimmerBox(context, width: 44, height: 44, borderRadius: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _shimmerBox(
                          context,
                          width: 120,
                          height: 16,
                          borderRadius: 6,
                        ),
                        _shimmerBox(
                          context,
                          width: 60,
                          height: 18,
                          borderRadius: 12,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _shimmerBox(context, width: 160, height: 12),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _shimmerBox(context, width: 80, height: 24, borderRadius: 10),
              _shimmerBox(context, width: 90, height: 24, borderRadius: 10),
              _shimmerBox(context, width: 90, height: 24, borderRadius: 10),
            ],
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
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
