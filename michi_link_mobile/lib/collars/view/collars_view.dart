import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/collars/cubit/collars_cubit.dart';
import 'package:michi_link_mobile/collars/widgets/collar_card.dart';
import 'package:michi_link_mobile/l10n/l10n.dart';

class CollarsView extends StatelessWidget {
  const CollarsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, appState) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final textTheme = theme.textTheme;
        final l10n = context.l10n;

        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: ExpressiveTopAppBar(
            centerTitle: false,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: ExpressiveIconButton.circle(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowLeft01,
                  color: colorScheme.onSurface,
                ),
                onPressed: () => context.pop(),
              ),
            ),
            title: Text(
              l10n.collarsTitle,
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          body: BlocBuilder<CollarsCubit, CollarsState>(
            builder: (context, state) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  for (final collar in state.collars) ...[
                    CollarCard(
                      collar: collar,
                      onEditTap: () => _showEditCollarModal(context, collar),
                      onTap: () => _showEditCollarModal(context, collar),
                      onNotificationsTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${collar.name}: '
                              '${context.l10n.collarsNotificationsTooltip}',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      onLocationHistoryTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${collar.name}: '
                              '${context.l10n.collarsLocationHistoryTooltip}',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  ExpressiveButton.filled(
                    onPressed: () => _showAddCollarModal(context),
                    label: l10n.collarsLinkNew,
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedAdd01,
                      size: 20,
                    ),
                    isExpanded: true,
                    size: ExpressiveButtonSize.large,
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  static void _showAddCollarModal(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sheetHeight = MediaQuery.of(context).size.height * 0.52;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (modalContext) => SizedBox(
        height: sheetHeight,
        child: _AddCollarBottomSheet(parentContext: context),
      ),
    );
  }

  static void _showEditCollarModal(BuildContext context, CollarModel collar) {
    final colorScheme = Theme.of(context).colorScheme;
    final sheetHeight = MediaQuery.of(context).size.height * 0.52;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (modalContext) => SizedBox(
        height: sheetHeight,
        child: _EditCollarBottomSheet(parentContext: context, collar: collar),
      ),
    );
  }
}

class _CatBreedSelector extends StatelessWidget {
  const _CatBreedSelector({
    required this.selectedBreed,
    required this.onBreedSelected,
  });

  final CatBreed selectedBreed;
  final ValueChanged<CatBreed> onBreedSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.collarsChooseCatBreed,
              style: textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.collarsBreedsSvgCount(CatBreed.values.length),
                style: textTheme.labelSmall?.copyWith(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onTertiaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: CatBreed.values.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final breed = CatBreed.values[index];
              final isSelected = selectedBreed == breed;
              final highlightColor = colorScheme.primary;

              return SizedBox(
                width: 94,
                child: InkWell(
                  onTap: () => onBreedSelected(breed),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? highlightColor.withValues(alpha: 0.12)
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? highlightColor
                            : colorScheme.outlineVariant.withValues(alpha: 0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 4,
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  child: breed.svgPicture(),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                breed.displayName(context),
                                style: textTheme.labelSmall?.copyWith(
                                  fontSize: 10,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? highlightColor
                                      : colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: highlightColor,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: HugeIcon(
                                  icon: HugeIcons.strokeRoundedTick01,
                                  size: 10,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AddCollarBottomSheet extends StatefulWidget {
  const _AddCollarBottomSheet({required this.parentContext});

  final BuildContext parentContext;

  @override
  State<_AddCollarBottomSheet> createState() => _AddCollarBottomSheetState();
}

class _AddCollarBottomSheetState extends State<_AddCollarBottomSheet> {
  late final TextEditingController _idController;
  late final TextEditingController _nameController;
  CatBreed _selectedBreed = CatBreed.europeanOrangeWhite;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: '9E284A1F8C592E5A');
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = context.l10n;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
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
            Expanded(
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
                            color: colorScheme.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(child: _selectedBreed.svgPicture()),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.collarsAddDeviceTitle,
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                l10n.collarsAddDeviceSubtitle,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ExpressiveIconButton.circle(
                          icon: const HugeIcon(
                            icon: HugeIcons.strokeRoundedCancel01,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.collarsAddDeviceDescription,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.collarsHardwareId,
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
                            alpha: 0.4,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'COLLAR_',
                              style: textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _idController,
                              style: textTheme.bodyMedium?.copyWith(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedCpu,
                              size: 18,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.collarsPetName,
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
                            alpha: 0.4,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: InputDecoration(
                                hintText: l10n.collarsPetNameHint,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedPawPrint,
                              size: 20,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _CatBreedSelector(
                      selectedBreed: _selectedBreed,
                      onBreedSelected: (breed) {
                        setState(() {
                          _selectedBreed = breed;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    ExpressiveButton.filled(
                      onPressed: () {
                        final petName = _nameController.text.trim();
                        final name = petName.isNotEmpty
                            ? petName
                            : l10n.collarsDefaultPetName;
                        final hwId = 'COLLAR_${_idController.text.trim()}';

                        widget.parentContext.read<CollarsCubit>().addCollar(
                          name: name,
                          deviceId: hwId,
                          breed: _selectedBreed,
                        );

                        Navigator.pop(context);
                        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
                          SnackBar(
                            content: Text(l10n.collarsLinkedSuccess(name)),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      label: l10n.collarsSaveAndLink,
                      size: ExpressiveButtonSize.large,
                      isExpanded: true,
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                        size: 20,
                        color: colorScheme.onPrimary,
                      ),
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

class _EditCollarBottomSheet extends StatefulWidget {
  const _EditCollarBottomSheet({
    required this.parentContext,
    required this.collar,
  });

  final BuildContext parentContext;
  final CollarModel collar;

  @override
  State<_EditCollarBottomSheet> createState() => _EditCollarBottomSheetState();
}

class _EditCollarBottomSheetState extends State<_EditCollarBottomSheet> {
  late final TextEditingController _nameController;
  late bool _lowBatteryAlert;
  late CatBreed _selectedBreed;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.collar.name);
    _lowBatteryAlert = widget.collar.config.minBatteryPct >= 20;
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
    final l10n = context.l10n;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
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
            Expanded(
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
                      child: TextField(
                        controller: _nameController,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.all(12),
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedEdit02,
                              size: 18,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _CatBreedSelector(
                      selectedBreed: _selectedBreed,
                      onBreedSelected: (breed) {
                        setState(() {
                          _selectedBreed = breed;
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(16),
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.collarsLowBatteryAlert,
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.collarsPriorityNotificationMobile,
                                  style: textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ExpressiveSwitch(
                            value: _lowBatteryAlert,
                            onChanged: (val) {
                              setState(() {
                                _lowBatteryAlert = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ExpressiveButton.filled(
                      onPressed: () {
                        final newName = _nameController.text.trim();
                        final updatedName = newName.isNotEmpty
                            ? newName
                            : widget.collar.name;

                        widget.parentContext.read<CollarsCubit>().updateCollar(
                          deviceId: widget.collar.deviceId,
                          name: updatedName,
                          breed: _selectedBreed,
                          minBatteryPct: _lowBatteryAlert ? 20 : 0,
                        );

                        Navigator.pop(context);
                        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
                          SnackBar(
                            content: Text(l10n.collarsCardUpdated(updatedName)),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      label: l10n.collarsUpdateData,
                      size: ExpressiveButtonSize.large,
                      isExpanded: true,
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedTick01,
                        size: 20,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () {
                        widget.parentContext.read<CollarsCubit>().removeCollar(
                          widget.collar.deviceId,
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.collarsUnlinkedSuccess(widget.collar.name),
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: colorScheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colorScheme.error.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedDelete02,
                              size: 18,
                              color: colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.collarsUnlinkAndClear,
                              style: textTheme.labelLarge?.copyWith(
                                color: colorScheme.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
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
