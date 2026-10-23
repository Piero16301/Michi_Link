import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/collars/collars.dart';

class CollarCard extends StatelessWidget {
  const CollarCard({required this.collarId, super.key});

  final String collarId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CollarModel>(
      stream: getIt<DatabaseService>().getCollarStream(collarId: collarId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final colorScheme = Theme.of(context).colorScheme;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: colorScheme.error.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedAlert02,
                  color: colorScheme.error,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    collarId,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      color: colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return LoadingCollarCard(collarId: collarId);
        }

        final collar = snapshot.data!;

        return SuccessCollarCard(
          collar: collar,
          onEdit: () => _showEditCollarModal(context, collar),
        );
      },
    );
  }

  static void _showEditCollarModal(BuildContext context, CollarModel collar) {
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
          child: EditCollarBottomSheet(parentContext: context, collar: collar),
        );
      },
    );
  }
}
