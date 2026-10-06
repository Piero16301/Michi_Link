import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/l10n/l10n.dart';

class SuccessCollarCard extends StatelessWidget {
  const SuccessCollarCard({
    required this.collar,
    required this.onEdit,
    super.key,
  });

  final CollarModel collar;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context);

    final shortId = _getShortId(collar.deviceId);
    final isOnline = collar.isOnline;
    final statusColor = isOnline ? colorScheme.primary : colorScheme.error;
    final lossPct = collar.packetLossPct;

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
                      child: collar.breed.svgPicture(width: 70, height: 70),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: statusColor,
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
                    Text(
                      collar.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOnline
                                ? l10n.collarsStatusActiveRealtime
                                : l10n.collarsStatusDisconnected,
                            style: textTheme.labelSmall?.copyWith(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
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
                  ExpressiveIconButton.circle(
                    size: ExpressiveIconButtonSize.small,
                    variant: ExpressiveIconButtonVariant.tonal,
                    tooltip: l10n.collarsEditTooltip,
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedEdit02,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onPressed: onEdit,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ExpressiveIconButton.circle(
                        size: ExpressiveIconButtonSize.small,
                        variant: ExpressiveIconButtonVariant.tonal,
                        tooltip: l10n.collarsNotificationsTooltip,
                        showBadgeDot: collar.hasActiveAlert,
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedNotification01,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 6),
                      ExpressiveIconButton.circle(
                        size: ExpressiveIconButtonSize.small,
                        variant: ExpressiveIconButtonVariant.tonal,
                        tooltip: l10n.collarsLocationHistoryTooltip,
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedRoute01,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {},
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
                                Text(
                                  l10n.collarsBatteryLabel,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                HugeIcon(
                                  icon:
                                      HugeIcons.strokeRoundedBatteryCharging01,
                                  color: colorScheme.primary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '${collar.status.batteryPct}%',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.collarsBatteryVoltage(
                                    collar.status.batteryV,
                                  ),
                                  style: textTheme.bodySmall?.copyWith(
                                    fontSize: 10,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (collar.status.batteryPct / 100).clamp(
                              0.0,
                              1.0,
                            ),
                            minHeight: 7,
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation(
                              collar.status.batteryPct > 20
                                  ? colorScheme.primary
                                  : colorScheme.error,
                            ),
                          ),
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
                                Text(
                                  l10n.collarsConstellationLabel,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                HugeIcon(
                                  icon: HugeIcons.strokeRoundedSatellite01,
                                  color: colorScheme.primary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.collarsSatellitesCount(collar.status.sats),
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: collar.status.gpsFix
                                    ? colorScheme.primary
                                    : colorScheme.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                collar.status.gpsFix
                                    ? l10n.collarsGpsFix
                                    : l10n.collarsNoGpsFix,
                                style: textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
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
                                Text(
                                  l10n.collarsSignalLabel,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                _signalBars(context, collar.radio.rssi),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '${collar.radio.rssi} dBm',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.collarsSignalSnr(collar.radio.snr),
                                  style: textTheme.bodySmall?.copyWith(
                                    fontSize: 10,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedHome03,
                              size: 16,
                              color: colorScheme.primary,
                              strokeWidth: 2,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                l10n.collarsDistanceHome(
                                  collar.radio.distanceHomeM,
                                ),
                                style: textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
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
                                Text(
                                  l10n.collarsPacketsLabel,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                HugeIcon(
                                  icon: HugeIcons.strokeRoundedPackage,
                                  color: colorScheme.primary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  l10n.collarsPacketsReceivedCount(
                                    collar.packetsReceived,
                                  ),
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.collarsPacketsLostCount(
                                    collar.packetsLost,
                                  ),
                                  style: textTheme.bodySmall?.copyWith(
                                    fontSize: 10,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (1.0 - (lossPct / 100)).clamp(
                                    0.0,
                                    1.0,
                                  ),
                                  minHeight: 7,
                                  backgroundColor: colorScheme.error.withValues(
                                    alpha: 0.25,
                                  ),
                                  valueColor: AlwaysStoppedAnimation(
                                    lossPct <= 5
                                        ? colorScheme.primary
                                        : (lossPct <= 15
                                              ? colorScheme.tertiary
                                              : colorScheme.error),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.collarsLossRate(collar.packetLossPct),
                              style: textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: lossPct <= 5
                                    ? colorScheme.onSurfaceVariant
                                    : colorScheme.error,
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
          ),
        ],
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

  static Widget _signalBars(BuildContext context, int rssi) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeBars = rssi >= -75
        ? 4
        : (rssi >= -95 ? 3 : (rssi >= -110 ? 2 : (rssi >= -125 ? 1 : 0)));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _bar(4, activeBars >= 1, colorScheme),
        const SizedBox(width: 2),
        _bar(7, activeBars >= 2, colorScheme),
        const SizedBox(width: 2),
        _bar(10, activeBars >= 3, colorScheme),
        const SizedBox(width: 2),
        _bar(13, activeBars >= 4, colorScheme),
      ],
    );
  }

  static Widget _bar(double height, bool active, ColorScheme colorScheme) {
    return Container(
      width: 3.5,
      height: height,
      decoration: BoxDecoration(
        color: active
            ? colorScheme.primary
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }
}
