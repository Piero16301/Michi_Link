import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/l10n/l10n.dart';

class HistoryRecordCard extends StatelessWidget {
  const HistoryRecordCard({
    required this.record,
    this.isSelected = false,
    this.onTap,
    super.key,
  });

  final HistoryRecord record;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context);

    final isGpsFixed = record.status.gpsFix;
    final timeStr = DateFormat('HH:mm:ss').format(record.timestamp);

    final gpsBadgeColor = isGpsFixed ? colorScheme.primary : colorScheme.error;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer.withValues(alpha: 0.25)
                : colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withValues(alpha: 0.35),
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Seq / Time / GPS Fix Status
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedRoute01,
                        color: colorScheme.primary,
                        size: 20,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.historyRecordSeq(record.seq),
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedClock01,
                              size: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeStr,
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: gpsBadgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: gpsBadgeColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedSatellite,
                          size: 13,
                          color: gpsBadgeColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isGpsFixed
                              ? l10n.historyValueSatellites(record.status.sats)
                              : l10n.historyGpsNoFix,
                          style: textTheme.labelSmall?.copyWith(
                            color: gpsBadgeColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Divider(
                height: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.25),
              ),
              const SizedBox(height: 12),

              // Row 2: Coordinates & Altitude
              Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedLocation01,
                    size: 14,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${record.coords.lat.toStringAsFixed(6)}, '
                      '${record.coords.lon.toStringAsFixed(6)}',
                      style: textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.historyValueAltitude(
                      record.coords.altM.toStringAsFixed(1),
                    ),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Row 3: Telemetry chips (Battery, Distance Home, RSSI/SNR)
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _MetricChip(
                    icon: HugeIcons.strokeRoundedBatteryCharging01,
                    text: l10n.historyValueBatteryVoltage(
                      record.status.batteryPct,
                      record.status.batteryV.toStringAsFixed(2),
                    ),
                    colorScheme: colorScheme,
                  ),
                  _MetricChip(
                    icon: HugeIcons.strokeRoundedHome03,
                    text: l10n.historyValueDistance(
                      record.radio.distanceHomeM.toStringAsFixed(1),
                    ),
                    colorScheme: colorScheme,
                  ),
                  _MetricChip(
                    icon: HugeIcons.strokeRoundedSignalLow01,
                    text: l10n.historyValueSignalWithSnr(
                      record.radio.rssi,
                      record.radio.snr.toStringAsFixed(1),
                    ),
                    colorScheme: colorScheme,
                  ),
                  if (record.radio.packetsLostGap > 0)
                    _MetricChip(
                      icon: HugeIcons.strokeRoundedAlertCircle,
                      text: l10n.historyLostPackets(
                        record.radio.packetsLostGap,
                      ),
                      colorScheme: colorScheme,
                      isWarning: true,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.text,
    required this.colorScheme,
    this.isWarning = false,
  });

  final List<List<dynamic>> icon;
  final String text;
  final ColorScheme colorScheme;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fgColor = isWarning
        ? colorScheme.error
        : colorScheme.onSurfaceVariant;
    final bgColor = isWarning
        ? colorScheme.error.withValues(alpha: 0.1)
        : colorScheme.surfaceContainerHigh;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, size: 13, color: fgColor),
          const SizedBox(width: 5),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: fgColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
