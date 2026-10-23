import 'dart:math' as math;

import 'package:expressive_kit/expressive_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/l10n/l10n.dart';

class HomeMapControls extends StatelessWidget {
  const HomeMapControls({
    required this.topPadding,
    required this.bearingNotifier,
    required this.onZoomIn,
    required this.onResetNorth,
    required this.onZoomOut,
    required this.onMyLocation,
    required this.onCatLocation,
    required this.onFitRange,
    super.key,
  });

  final double topPadding;
  final ValueListenable<double> bearingNotifier;
  final VoidCallback onZoomIn;
  final VoidCallback onResetNorth;
  final VoidCallback onZoomOut;
  final VoidCallback onMyLocation;
  final VoidCallback onCatLocation;
  final VoidCallback onFitRange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return Positioned(
      left: 16,
      right: 16,
      top: topPadding,
      child: RepaintBoundary(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
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
                    onPressed: onZoomIn,
                  ),
                  Divider(
                    height: 6,
                    indent: 6,
                    endIndent: 6,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                  ExpressiveIconButton.circle(
                    icon: ValueListenableBuilder<double>(
                      valueListenable: bearingNotifier,
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
                    onPressed: onResetNorth,
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
                    onPressed: onZoomOut,
                  ),
                ],
              ),
            ),
            Container(
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
                      icon: HugeIcons.strokeRoundedNavigation03,
                      color: colorScheme.onSurface,
                      strokeWidth: 2,
                    ),
                    tooltip: l10n.homeMyLocationTooltip,
                    onPressed: onMyLocation,
                  ),
                  const SizedBox(height: 2),
                  ExpressiveIconButton.circle(
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedPawPrint,
                      color: colorScheme.primary,
                      strokeWidth: 2,
                    ),
                    tooltip: l10n.homeCatLocationTooltip,
                    onPressed: onCatLocation,
                  ),
                  const SizedBox(height: 2),
                  ExpressiveIconButton.circle(
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedTarget02,
                      color: colorScheme.onSurface,
                      strokeWidth: 2,
                    ),
                    tooltip: l10n.homeFitRangeTooltip,
                    onPressed: onFitRange,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
