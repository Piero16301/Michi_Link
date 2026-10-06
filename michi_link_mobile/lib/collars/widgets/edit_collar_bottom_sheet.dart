import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/collars/collars.dart';
import 'package:michi_link_mobile/l10n/l10n.dart';

class EditCollarBottomSheet extends StatefulWidget {
  const EditCollarBottomSheet({
    required this.parentContext,
    required this.collar,
    super.key,
  });

  final BuildContext parentContext;
  final CollarModel collar;

  @override
  State<EditCollarBottomSheet> createState() => EditCollarBottomSheetState();
}

class EditCollarBottomSheetState extends State<EditCollarBottomSheet> {
  late final TextEditingController _nameController;
  late CatBreed _selectedBreed;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.collar.name);
    _selectedBreed = widget.collar.breed;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context);
    final isNameValid = _nameController.text.trim().isNotEmpty;

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
                            child: _selectedBreed.svgPicture(
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
                                l10n.collarsEditCardTitle(widget.collar.name),
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                l10n.collarsSettingsSubtitle,
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
                    Row(
                      children: [
                        Text(
                          l10n.collarsHardwareIdImmutable,
                          style: textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedLockPassword,
                          size: 15,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.35,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.collar.deviceId,
                            style: textTheme.bodyMedium?.copyWith(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.collarsCryptographicallySigned,
                            style: textTheme.bodySmall?.copyWith(
                              fontSize: 10.5,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      l10n.collarsPublicAliasOnMap,
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.35,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              onChanged: (_) => setState(() {}),
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ExpressiveIconButton.circle(
                              size: ExpressiveIconButtonSize.small,
                              icon: const HugeIcon(
                                icon: HugeIcons.strokeRoundedCancel01,
                                size: 16,
                              ),
                              onPressed: _nameController.text.isNotEmpty
                                  ? () {
                                      _nameController.clear();
                                      setState(() {});
                                    }
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    CatBreedSelector(
                      selectedBreed: _selectedBreed,
                      onBreedSelected: (breed) {
                        setState(() {
                          _selectedBreed = breed;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    ExpressiveButton.filled(
                      onPressed: isNameValid
                          ? () {
                              final updatedName = _nameController.text.trim();
                              if (updatedName.isEmpty) return;

                              widget.parentContext
                                  .read<CollarsCubit>()
                                  .updateCollar(
                                    collarId: widget.collar.deviceId,
                                    name: updatedName,
                                    breed: _selectedBreed,
                                  );

                              Navigator.pop(context);
                              ScaffoldMessenger.of(
                                widget.parentContext,
                              ).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.collarsCardUpdated(updatedName),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          : null,
                      label: l10n.collarsUpdateData,
                      size: ExpressiveButtonSize.large,
                      isExpanded: true,
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedTick01,
                        size: 20,
                        color: isNameValid
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface.withValues(alpha: 0.38),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ExpressiveButton.text(
                      onPressed: () =>
                          _showUnlinkConfirmationDialog(theme, l10n),
                      label: l10n.collarsUnlinkAndClear,
                      foregroundColor: colorScheme.error,
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

  Future<void> _showUnlinkConfirmationDialog(
    ThemeData theme,
    AppLocalizations l10n,
  ) async {
    final parentContext = widget.parentContext;
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: colorScheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedAlert02,
                      size: 26,
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.collarsUnlinkDialogTitle,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.collarsUnlinkDialogMessage(widget.collar.name),
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ExpressiveButton.tonal(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        label: l10n.collarsUnlinkDialogCancel,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ExpressiveButton.filled(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        label: l10n.collarsUnlinkDialogConfirm,
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true) return;
    if (!mounted || !parentContext.mounted) return;

    parentContext.read<CollarsCubit>().removeCollar(widget.collar.deviceId);
    Navigator.pop(context);

    if (!parentContext.mounted) return;
    ScaffoldMessenger.of(parentContext).showSnackBar(
      SnackBar(
        content: Text(l10n.collarsUnlinkedSuccess(widget.collar.name)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
