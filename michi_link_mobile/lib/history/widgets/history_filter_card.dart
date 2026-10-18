import 'package:expressive_kit/expressive_kit.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/l10n/l10n.dart';

class HistoryFilterCard extends StatefulWidget {
  const HistoryFilterCard({
    required this.selectedDate,
    required this.onPreviousDate,
    required this.onNextDate,
    required this.onDateSelected,
    required this.startHour,
    required this.endHour,
    required this.onTimeRangeChanged,
    this.isNextEnabled = false,
    super.key,
  });

  final DateTime selectedDate;
  final VoidCallback onPreviousDate;
  final VoidCallback onNextDate;
  final ValueChanged<DateTime> onDateSelected;
  final bool isNextEnabled;
  final double startHour;
  final double endHour;
  final void Function(double start, double end) onTimeRangeChanged;

  @override
  State<HistoryFilterCard> createState() => _HistoryFilterCardState();
}

class _HistoryFilterCardState extends State<HistoryFilterCard> {
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
  void didUpdateWidget(HistoryFilterCard oldWidget) {
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

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
    );

    final String label;
    if (itemDate == today) {
      label = l10n.notificationsToday;
    } else if (itemDate == yesterday) {
      label = l10n.notificationsYesterday;
    } else {
      final locale = Localizations.localeOf(context).toString();
      label = DateFormat.yMMMMEEEEd(locale).format(widget.selectedDate);
    }

    final formattedLabel = label.isNotEmpty
        ? '${label[0].toUpperCase()}${label.substring(1)}'
        : label;

    final isAllDay = _values.start == 0 && _values.end == 24;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.all(Radius.circular(32)),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Date Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ExpressiveIconButton.circle(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowLeft01,
                  color: colorScheme.onSurface,
                  size: 18,
                ),
                variant: ExpressiveIconButtonVariant.tonal,
                onPressed: widget.onPreviousDate,
              ),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: widget.selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        widget.onDateSelected(picked);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedCalendar03,
                            color: colorScheme.primary,
                            size: 18,
                            strokeWidth: 2,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              formattedLabel,
                              style: textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              ExpressiveIconButton.circle(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  color: widget.isNextEnabled
                      ? colorScheme.onSurface
                      : colorScheme.onSurface.withValues(alpha: 0.3),
                  size: 18,
                ),
                variant: ExpressiveIconButtonVariant.tonal,
                onPressed: widget.isNextEnabled ? widget.onNextDate : () {},
              ),
            ],
          ),

          Divider(
            height: 16,
            thickness: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.25),
          ),

          // Row 2: Time Range Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedClock01,
                    size: 15,
                    color: colorScheme.primary,
                    strokeWidth: 2,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.historyTimeRange,
                    style: textTheme.labelMedium?.copyWith(
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
                      vertical: 2,
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
                        fontSize: 11,
                      ),
                    ),
                  ),
                  if (!isAllDay) ...[
                    const SizedBox(width: 6),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        setState(() {
                          _values = const RangeValues(0, 24);
                        });
                        widget.onTimeRangeChanged(0, 24);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Text(
                          l10n.historyAllDay,
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.secondary,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          // Row 3: Range Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: colorScheme.primary,
              inactiveTrackColor: colorScheme.surfaceContainerHighest,
              thumbColor: colorScheme.primary,
              overlayColor: colorScheme.primary.withValues(alpha: 0.12),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
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
                widget.onTimeRangeChanged(finalValues.start, finalValues.end);
              },
            ),
          ),
        ],
      ),
    );
  }
}
