import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/l10n/l10n.dart';

/// Card widget to display an [AlertRecord] notification item
class NotificationCard extends StatelessWidget {
  const NotificationCard({
    required this.alert,
    this.showFullDate = false,
    super.key,
  });

  final AlertRecord alert;
  final bool showFullDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context);

    final isRecovery = alert.type.isRecovery;
    final statusColor = _getStatusColor(colorScheme);
    final typeIcon = _getTypeIcon(alert.type);
    final valueIcon = _getValueIcon(alert.type);
    final title = _getTitle(l10n, alert.type);
    final description = _getDescription(l10n, alert.type);
    final formattedValue = _formatValue(l10n, alert.type, alert.value);
    final severityLabel = isRecovery
        ? l10n.alertSeverityNormal
        : _getSeverityLabel(l10n, alert.severity);
    final dateStr = showFullDate
        ? DateFormat('dd/MM/yyyy • HH:mm').format(alert.timestamp)
        : DateFormat('HH:mm').format(alert.timestamp);

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
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.25),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: typeIcon,
                    color: statusColor,
                    size: 22,
                    strokeWidth: 2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            severityLabel,
                            style: textTheme.labelSmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HugeIcon(
                      icon: valueIcon,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formattedValue,
                      style: textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedClock01,
                    size: 13,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateStr,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.8,
                      ),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ColorScheme colorScheme) {
    if (alert.type.isRecovery) {
      return colorScheme.primary;
    }
    return switch (alert.severity) {
      AlertSeverity.critical => colorScheme.error,
      AlertSeverity.warning => Colors.amber.shade700,
      AlertSeverity.info => colorScheme.tertiary,
      AlertSeverity.unknown => colorScheme.onSurfaceVariant,
    };
  }

  static List<List<dynamic>> _getTypeIcon(AlertType type) {
    return switch (type) {
      AlertType.geofenceBreach => HugeIcons.strokeRoundedRoute01,
      AlertType.geofenceRestored => HugeIcons.strokeRoundedHome03,
      AlertType.lowBattery ||
      AlertType.batteryCritical => HugeIcons.strokeRoundedBatteryLow,
      AlertType.batteryNormal => HugeIcons.strokeRoundedBatteryCharging01,
      AlertType.noGpsFix ||
      AlertType.gpsFixRestored => HugeIcons.strokeRoundedSatellite,
      AlertType.weakSignal => HugeIcons.strokeRoundedSignalLow01,
      AlertType.signalNormal => HugeIcons.strokeRoundedWifi01,
      AlertType.unknown => HugeIcons.strokeRoundedAlertCircle,
    };
  }

  static List<List<dynamic>> _getValueIcon(AlertType type) {
    return switch (type) {
      AlertType.geofenceBreach ||
      AlertType.geofenceRestored => HugeIcons.strokeRoundedRoute01,
      AlertType.lowBattery ||
      AlertType.batteryCritical ||
      AlertType.batteryNormal => HugeIcons.strokeRoundedBatteryCharging01,
      AlertType.noGpsFix ||
      AlertType.gpsFixRestored => HugeIcons.strokeRoundedSatellite,
      AlertType.weakSignal ||
      AlertType.signalNormal => HugeIcons.strokeRoundedSignalLow01,
      AlertType.unknown => HugeIcons.strokeRoundedInformationCircle,
    };
  }

  static String _getTitle(AppLocalizations l10n, AlertType type) {
    return switch (type) {
      AlertType.geofenceBreach => l10n.alertGeofenceBreachTitle,
      AlertType.geofenceRestored => l10n.alertGeofenceRestoredTitle,
      AlertType.lowBattery => l10n.alertLowBatteryTitle,
      AlertType.batteryCritical => l10n.alertBatteryCriticalTitle,
      AlertType.batteryNormal => l10n.alertBatteryNormalTitle,
      AlertType.noGpsFix => l10n.alertNoGpsFixTitle,
      AlertType.gpsFixRestored => l10n.alertGpsFixRestoredTitle,
      AlertType.weakSignal => l10n.alertWeakSignalTitle,
      AlertType.signalNormal => l10n.alertSignalNormalTitle,
      AlertType.unknown => l10n.alertUnknownTitle,
    };
  }

  static String _getDescription(AppLocalizations l10n, AlertType type) {
    return switch (type) {
      AlertType.geofenceBreach => l10n.alertGeofenceBreachDesc,
      AlertType.geofenceRestored => l10n.alertGeofenceRestoredDesc,
      AlertType.lowBattery => l10n.alertLowBatteryDesc,
      AlertType.batteryCritical => l10n.alertBatteryCriticalDesc,
      AlertType.batteryNormal => l10n.alertBatteryNormalDesc,
      AlertType.noGpsFix => l10n.alertNoGpsFixDesc,
      AlertType.gpsFixRestored => l10n.alertGpsFixRestoredDesc,
      AlertType.weakSignal => l10n.alertWeakSignalDesc,
      AlertType.signalNormal => l10n.alertSignalNormalDesc,
      AlertType.unknown => l10n.alertUnknownDesc,
    };
  }

  static String _getSeverityLabel(
    AppLocalizations l10n,
    AlertSeverity severity,
  ) {
    return switch (severity) {
      AlertSeverity.critical => l10n.alertSeverityCritical,
      AlertSeverity.warning => l10n.alertSeverityWarning,
      AlertSeverity.info => l10n.alertSeverityInfo,
      AlertSeverity.unknown => l10n.alertSeverityUnknown,
    };
  }

  static String _formatValue(AppLocalizations l10n, AlertType type, num value) {
    return switch (type) {
      AlertType.geofenceBreach || AlertType.geofenceRestored =>
        l10n.alertValueDistance(_formatDistance(value)),
      AlertType.lowBattery ||
      AlertType.batteryCritical ||
      AlertType.batteryNormal => l10n.alertValueBattery(value.toInt()),
      AlertType.weakSignal ||
      AlertType.signalNormal => l10n.alertValueSignal(value.toInt()),
      AlertType.noGpsFix ||
      AlertType.gpsFixRestored => l10n.alertValueSatellites(value.toInt()),
      AlertType.unknown => '$value',
    };
  }

  static String _formatDistance(num value) {
    final isWhole = value is int || value == value.roundToDouble();
    return value.toStringAsFixed(isWhole ? 0 : 1);
  }
}
