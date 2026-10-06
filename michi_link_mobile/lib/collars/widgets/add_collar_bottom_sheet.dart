import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/collars/collars.dart';
import 'package:michi_link_mobile/l10n/l10n.dart';

class AddCollarBottomSheet extends StatefulWidget {
  const AddCollarBottomSheet({required this.parentContext, super.key});

  final BuildContext parentContext;

  @override
  State<AddCollarBottomSheet> createState() => AddCollarBottomSheetState();
}

class AddCollarBottomSheetState extends State<AddCollarBottomSheet> {
  late final TextEditingController _idController;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController();
  }

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context);

    final rawId = _idController.text.trim();
    final isValid = rawId.length == 16;

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
                          child: ClipOval(
                            child: CatBreed.defaultBreed.svgPicture(),
                          ),
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
                              textCapitalization: TextCapitalization.characters,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp('[a-zA-Z0-9]'),
                                ),
                                const _UpperCaseTextFormatter(),
                                LengthLimitingTextInputFormatter(16),
                              ],
                              onChanged: (_) => setState(() {}),
                              style: textTheme.bodyMedium?.copyWith(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: const InputDecoration(
                                counterText: '',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
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
                              onPressed: _idController.text.isNotEmpty
                                  ? () {
                                      _idController.clear();
                                      setState(() {});
                                    }
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ExpressiveButton.filled(
                      onPressed: isValid
                          ? () {
                              final idText = _idController.text
                                  .trim()
                                  .toUpperCase();
                              if (idText.length != 16) return;

                              final name = l10n.collarsDefaultPetName;
                              final hwId = 'COLLAR_$idText';

                              widget.parentContext
                                  .read<CollarsCubit>()
                                  .addCollar(name: name, deviceId: hwId);

                              Navigator.pop(context);
                              ScaffoldMessenger.of(
                                widget.parentContext,
                              ).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.collarsLinkedSuccess(name),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          : null,
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

class _UpperCaseTextFormatter extends TextInputFormatter {
  const _UpperCaseTextFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
