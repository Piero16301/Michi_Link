import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/l10n/l10n.dart';

class HistoryTimeRangeSlider extends StatefulWidget {
  const HistoryTimeRangeSlider({
    required this.startHour,
    required this.endHour,
    required this.onRangeChanged,
    super.key,
  });

  final double startHour;
  final double endHour;
  final void Function(double start, double end) onRangeChanged;

  @override
  State<HistoryTimeRangeSlider> createState() => _HistoryTimeRangeSliderState();
}

class _HistoryTimeRangeSliderState extends State<HistoryTimeRangeSlider> {
  late RangeValues _values;

  @override
  void initState() {
    super.initState();
    _values = RangeValues(
      widget.startHour.clamp(0, 24),
      widget.endHour.clamp(0, 24),
    );
  }

  @override
  void didUpdateWidget(HistoryTimeRangeSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startHour != widget.startHour ||
        oldWidget.endHour != widget.endHour) {
      _values = RangeValues(
        widget.startHour.clamp(0, 24),
        widget.endHour.clamp(0, 24),
      );
    }
  }

  String _formatTime(double hourVal) {
    final hour = hourVal.floor();
    final minute = ((hourVal - hour) * 60).round();
    final hStr = hour.toString().padLeft(2, '0');
    final mStr = minute.toString().padLeft(2, '0');
    return '$hStr:$mStr';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context);

    final isAllDay = _values.start == 0 && _values.end == 24;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedClock01,
                    size: 16,
                    color: colorScheme.primary,
                    strokeWidth: 2,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.historyTimeRange,
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
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
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      '${_formatTime(_values.start)} - '
                      '${_formatTime(_values.end)}',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (!isAllDay) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        setState(() {
                          _values = const RangeValues(0, 24);
                        });
                        widget.onRangeChanged(0, 24);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        child: Text(
                          l10n.historyAllDay,
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.secondary,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: colorScheme.primary,
              inactiveTrackColor: colorScheme.surfaceContainerHighest,
              thumbColor: colorScheme.primary,
              overlayColor: colorScheme.primary.withValues(alpha: 0.12),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: RangeSlider(
              values: _values,
              max: 24,
              divisions: 24,
              labels: RangeLabels(
                _formatTime(_values.start),
                _formatTime(_values.end),
              ),
              onChanged: (newValues) {
                setState(() {
                  _values = newValues;
                });
              },
              onChangeEnd: (finalValues) {
                widget.onRangeChanged(finalValues.start, finalValues.end);
              },
            ),
          ),
        ],
      ),
    );
  }
}
