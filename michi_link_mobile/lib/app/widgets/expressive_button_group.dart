import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/widgets/expressive_motion.dart';

/// Elemento para un grupo de botones [ExpressiveButtonGroup].
class ExpressiveButtonGroupItem<T> {
  const ExpressiveButtonGroupItem({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final Widget? icon;
}

/// Grupo de botones conectados de Material 3 Expressive con animación elástica
/// e indicador de selección continuo en píldora.
class ExpressiveButtonGroup<T> extends StatelessWidget {
  const ExpressiveButtonGroup({
    required this.items,
    required this.selectedValue,
    required this.onSelected,
    this.height = 48,
    this.borderRadius,
    this.backgroundColor,
    this.selectedColor,
    this.isExpanded = true,
    super.key,
  });

  final List<ExpressiveButtonGroupItem<T>> items;
  final T selectedValue;
  final ValueChanged<T> onSelected;
  final double height;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? selectedColor;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final radius = borderRadius ?? BorderRadius.circular(height / 2);
    final bg = backgroundColor ?? colorScheme.surfaceContainer;
    final activeBg = selectedColor ?? colorScheme.secondaryContainer;

    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: bg, borderRadius: radius),
      child: Row(
        mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
        children: items.map((item) {
          final isSelected = item.value == selectedValue;

          final segment = AnimatedContainer(
            duration: ExpressiveMotion.durationShort,
            curve: ExpressiveMotion.springBouncy,
            height: height - 8,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isSelected ? activeBg : Colors.transparent,
              borderRadius: BorderRadius.circular((height - 8) / 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.icon != null) ...[
                  IconTheme(
                    data: IconThemeData(
                      color: isSelected
                          ? colorScheme.onSecondaryContainer
                          : colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                    child: item.icon!,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  item.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? colorScheme.onSecondaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );

          final clickableSegment = ExpressivePressable(
            onTap: () => onSelected(item.value),
            child: segment,
          );

          return isExpanded
              ? Expanded(child: clickableSegment)
              : clickableSegment;
        }).toList(),
      ),
    );
  }
}
