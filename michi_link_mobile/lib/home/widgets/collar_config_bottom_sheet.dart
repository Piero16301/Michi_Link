import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/l10n/l10n.dart';

class CollarConfigBottomSheet extends StatefulWidget {
  const CollarConfigBottomSheet({
    required this.parentContext,
    required this.collar,
    super.key,
  });

  final BuildContext parentContext;
  final CollarModel collar;

  @override
  State<CollarConfigBottomSheet> createState() =>
      _CollarConfigBottomSheetState();
}

class _CollarConfigBottomSheetState extends State<CollarConfigBottomSheet> {
  late double _maxDistance;
  late double _minBatteryPct;
  late bool _requireGpsFix;

  @override
  void initState() {
    super.initState();
    final initialDistance = widget.collar.config.maxDistanceM <= 0
        ? 100.0
        : widget.collar.config.maxDistanceM.toDouble();
    _maxDistance = initialDistance.clamp(50.0, 600.0);

    final initialBattery = widget.collar.config.minBatteryPct <= 0
        ? 20.0
        : widget.collar.config.minBatteryPct.toDouble();
    _minBatteryPct = initialBattery.clamp(5.0, 30.0);

    _requireGpsFix = widget.collar.config.requireGpsFix;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabecera con raza, nombre y estado
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withValues(
                                alpha: 0.4,
                              ),
                            ),
                          ),
                          child: Center(
                            child: widget.collar.breed.svgPicture(
                              width: 30,
                              height: 30,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.collarConfigTitle(widget.collar.name),
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                l10n.collarConfigSubtitle,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: widget.collar.isOnline
                                ? colorScheme.primary.withValues(alpha: 0.15)
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            widget.collar.isOnline
                                ? l10n.collarsStatusLinked
                                : l10n.collarsStatusDisconnected,
                            style: textTheme.labelSmall?.copyWith(
                              color: widget.collar.isOnline
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Parámetro 1: Distancia máxima (Slider 50..600)
                    Row(
                      children: [
                        Text(
                          l10n.collarConfigMaxDistanceLabel,
                          style: textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_maxDistance.round()} m',
                          style: textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.35,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedRoute01,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.collarConfigMaxDistanceSubtitle,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ExpressiveSlider(
                            value: _maxDistance,
                            min: 50,
                            max: 600,
                            divisions: 11,
                            onChanged: (val) {
                              setState(() {
                                _maxDistance = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Parámetro 2: Min Battery Pct (Slider 5..30 de 5 en 5)
                    Row(
                      children: [
                        Text(
                          l10n.collarConfigMinBatteryLabel,
                          style: textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_minBatteryPct.round()}%',
                          style: textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.35,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedBatteryLow,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.collarConfigMinBatterySubtitle,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ExpressiveSlider(
                            value: _minBatteryPct,
                            min: 5,
                            max: 30,
                            divisions: 5,
                            onChanged: (val) {
                              setState(() {
                                _minBatteryPct = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Parámetro 3: Require GPS Fix (Switch bool)
                    Row(
                      children: [
                        Text(
                          l10n.collarConfigRequireGpsFixLabel,
                          style: textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.35,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedSatellite01,
                            size: 20,
                            color: _requireGpsFix
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.collarConfigRequireGpsFixTitle,
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.collarConfigRequireGpsFixSubtitle,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ExpressiveSwitch(
                            value: _requireGpsFix,
                            onChanged: (val) {
                              setState(() {
                                _requireGpsFix = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botón Guardar
                    ExpressiveButton.filled(
                      onPressed: () {
                        final updatedConfig = CollarConfig(
                          maxDistanceM: _maxDistance.round(),
                          minBatteryPct: _minBatteryPct.round(),
                          requireGpsFix: _requireGpsFix,
                        );

                        getIt<DatabaseService>().updateCollarConfig(
                          collarId: widget.collar.deviceId,
                          config: updatedConfig,
                        );

                        Navigator.of(context).pop();

                        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.collarConfigSavedSuccess(widget.collar.name),
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      label: l10n.collarConfigSave,
                      size: ExpressiveButtonSize.large,
                      isExpanded: true,
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedTick01,
                        size: 20,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Botón Cancelar
                    ExpressiveButton.text(
                      onPressed: () => Navigator.of(context).pop(),
                      label: l10n.collarConfigCancel,
                      size: ExpressiveButtonSize.large,
                      isExpanded: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
