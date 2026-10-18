import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/l10n/l10n.dart';

class RouteSummaryFloatingBadge extends StatelessWidget {
  const RouteSummaryFloatingBadge({
    required this.count,
    this.startTime,
    this.endTime,
    this.onTap,
    super.key,
  });

  final int count;
  final DateTime? startTime;
  final DateTime? endTime;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context);

    final timeSpan = startTime != null && endTime != null
        ? '${DateFormat('HH:mm').format(startTime!)} - '
              '${DateFormat('HH:mm').format(endTime!)}'
        : null;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.94),
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
                Text(
                  l10n.historyPointsCount(count),
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (timeSpan != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '•  $timeSpan',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SelectedRecordFloatingCard extends StatelessWidget {
  const SelectedRecordFloatingCard({
    required this.record,
    required this.onClose,
    super.key,
  });

  final HistoryRecord record;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context);

    final isGpsFixed = record.status.gpsFix;
    final gpsBadgeColor = isGpsFixed ? colorScheme.primary : colorScheme.error;
    final timeStr = DateFormat('HH:mm:ss').format(record.timestamp);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Seq, time, GPS status, and Close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedRoute01,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${l10n.historyRecordSeq(record.seq)} • $timeStr',
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: gpsBadgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: gpsBadgeColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      isGpsFixed
                          ? l10n.historyValueSatellites(record.status.sats)
                          : l10n.historyGpsNoFix,
                      style: textTheme.labelSmall?.copyWith(
                        color: gpsBadgeColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onClose,
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedCancel01,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Coords & Altitude
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedLocation01,
                size: 13,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${record.coords.lat.toStringAsFixed(6)}, '
                  '${record.coords.lon.toStringAsFixed(6)}',
                  style: textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: colorScheme.onSurface,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                l10n.historyValueAltitude(
                  record.coords.altM.toStringAsFixed(1),
                ),
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Telemetry row: Battery, Distance, Signal
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _AttributePill(
                icon: HugeIcons.strokeRoundedBatteryCharging01,
                text: l10n.historyValueBatteryVoltage(
                  record.status.batteryPct,
                  record.status.batteryV.toStringAsFixed(2),
                ),
                colorScheme: colorScheme,
              ),
              _AttributePill(
                icon: HugeIcons.strokeRoundedHome03,
                text: l10n.historyValueDistance(
                  record.radio.distanceHomeM.toStringAsFixed(1),
                ),
                colorScheme: colorScheme,
              ),
              _AttributePill(
                icon: HugeIcons.strokeRoundedSignalLow01,
                text: l10n.historyValueSignal(record.radio.rssi),
                colorScheme: colorScheme,
              ),
              if (record.radio.packetsLostGap > 0)
                _AttributePill(
                  icon: HugeIcons.strokeRoundedAlertCircle,
                  text: l10n.historyLostPackets(record.radio.packetsLostGap),
                  colorScheme: colorScheme,
                  isError: true,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttributePill extends StatelessWidget {
  const _AttributePill({
    required this.icon,
    required this.text,
    required this.colorScheme,
    this.isError = false,
  });

  final List<List<dynamic>> icon;
  final String text;
  final ColorScheme colorScheme;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = isError ? colorScheme.error : colorScheme.onSurfaceVariant;
    final bg = isError
        ? colorScheme.error.withValues(alpha: 0.1)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
