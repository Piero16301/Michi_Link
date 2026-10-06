import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/home/home.dart';
import 'package:michi_link_mobile/l10n/l10n.dart';

class HomeTelemetryPanel extends StatelessWidget {
  const HomeTelemetryPanel({required this.collar, super.key});

  final CollarModel collar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context);

    final lossPct = collar.packetLossPct;

    return Container(
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
                                icon: HugeIcons.strokeRoundedBatteryCharging01,
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
                          backgroundColor: colorScheme.surfaceContainerHighest,
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

              // Cuadro 2: Constelación (Satélites y GPS Fix)
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
          const SizedBox(height: 12),

          Row(
            children: [
              // Cuadro 3: Señal LoRa / Distancia
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
                                value: (1.0 - (lossPct / 100)).clamp(0.0, 1.0),
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
          const SizedBox(height: 12),
          ExpressiveButton.filled(
            onPressed: () => _showConfigCollarModal(context, collar),
            label: l10n.homeConfigCollar,
            size: ExpressiveButtonSize.large,
            isExpanded: true,
            trailingIcon: const HugeIcon(
              icon: HugeIcons.strokeRoundedSettings02,
            ),
          ),
        ],
      ),
    );
  }

  static void _showConfigCollarModal(BuildContext context, CollarModel collar) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxHeight =
        MediaQuery.of(context).size.height *
        AppVariables.modalBottomSheetMaxHeightPct;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (modalContext) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: CollarConfigBottomSheet(parentContext: context, collar: collar),
      ),
    );
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
