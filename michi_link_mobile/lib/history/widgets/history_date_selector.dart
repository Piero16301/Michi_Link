import 'package:expressive_kit/expressive_kit.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/l10n/l10n.dart';

class HistoryDateSelector extends StatelessWidget {
  const HistoryDateSelector({
    required this.selectedDate,
    required this.onPrevious,
    required this.onNext,
    required this.onDateSelected,
    this.isNextEnabled = false,
    super.key,
  });

  final DateTime selectedDate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onDateSelected;
  final bool isNextEnabled;

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
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    final String label;
    if (itemDate == today) {
      label = l10n.notificationsToday;
    } else if (itemDate == yesterday) {
      label = l10n.notificationsYesterday;
    } else {
      final locale = Localizations.localeOf(context).toString();
      label = DateFormat.yMMMMEEEEd(locale).format(selectedDate);
    }

    final formattedLabel = label.isNotEmpty
        ? '${label[0].toUpperCase()}${label.substring(1)}'
        : label;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ExpressiveIconButton.circle(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              color: colorScheme.onSurface,
              size: 20,
            ),
            variant: ExpressiveIconButtonVariant.tonal,
            onPressed: onPrevious,
          ),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    onDateSelected(picked);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
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
              color: isNextEnabled
                  ? colorScheme.onSurface
                  : colorScheme.onSurface.withValues(alpha: 0.3),
              size: 20,
            ),
            variant: ExpressiveIconButtonVariant.tonal,
            onPressed: isNextEnabled ? onNext : () {},
          ),
        ],
      ),
    );
  }
}
