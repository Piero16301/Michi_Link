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
          return const SizedBox.shrink();
        }

        if (!snapshot.hasData) {
          return LoadingCollarCard(collarId: collarId);
        }

        if (snapshot.data == null) {
          return const SizedBox.shrink();
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
    final sheetHeight =
        MediaQuery.of(context).size.height *
        AppVariables.modalBottomSheetHeightPct;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (modalContext) => SizedBox(
        height: sheetHeight,
        child: EditCollarBottomSheet(parentContext: context, collar: collar),
      ),
    );
  }
}
