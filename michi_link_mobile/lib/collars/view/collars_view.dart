import 'package:expressive_kit/expressive_kit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/collars/collars.dart';
import 'package:michi_link_mobile/l10n/l10n.dart';

class CollarsView extends StatelessWidget {
  const CollarsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context);

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
          if (state.collars.isEmpty) {
            return Column(
              children: [
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        l10n.collarsEmptyTitle,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  child: ExpressiveButton.filled(
                    onPressed: () => _showAddCollarModal(context),
                    label: l10n.collarsLinkNew,
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedAdd01,
                      size: 20,
                    ),
                    isExpanded: true,
                    size: ExpressiveButtonSize.large,
                  ),
                ),
              ],
            );
          }

          final collarsCount = state.collars.length;
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: collarsCount + 1,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              if (index < collarsCount) {
                final collarId = state.collars[index];
                return RepaintBoundary(child: CollarCard(collarId: collarId));
              }
              return ExpressiveButton.filled(
                onPressed: () => _showAddCollarModal(context),
                label: l10n.collarsLinkNew,
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedAdd01,
                  size: 20,
                ),
                isExpanded: true,
                size: ExpressiveButtonSize.large,
              );
            },
          );
        },
      ),
    );
  }

  static void _showAddCollarModal(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (modalContext) {
        final mediaQuery = MediaQuery.of(modalContext);
        final maxHeight = mediaQuery.viewInsets.bottom > 0
            ? mediaQuery.size.height *
                  AppVariables.modalBottomSheetKeyboardMaxHeightPct
            : mediaQuery.size.height *
                  AppVariables.modalBottomSheetMaxHeightPct;

        return AnimatedContainer(
          duration: AppVariables.modalBottomSheetAnimationDuration,
          curve: AppVariables.modalBottomSheetAnimationCurve,
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: AddCollarBottomSheet(parentContext: context),
        );
      },
    );
  }
}
