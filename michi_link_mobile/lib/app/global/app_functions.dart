import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';

class AppFunctions {
  static void showSnackBar(
    BuildContext context, {
    String? message,
    SnackBarType type = SnackBarType.info,
  }) {
    final icon = switch (type) {
      SnackBarType.success => HugeIcons.strokeRoundedCheckmarkCircle02,
      SnackBarType.error => HugeIcons.strokeRoundedAlertCircle,
      SnackBarType.warning => HugeIcons.strokeRoundedAlert02,
      SnackBarType.info => HugeIcons.strokeRoundedInformationCircle,
    };

    final backgroundColor = switch (type) {
      SnackBarType.success => Colors.green,
      SnackBarType.error => Colors.red,
      SnackBarType.warning => Colors.orange,
      SnackBarType.info => Colors.blue,
    };

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          spacing: 12,
          children: [
            HugeIcon(icon: icon, strokeWidth: 2, color: Colors.white),
            Expanded(
              child: Text(
                message ?? '',
                style: TextStyle(
                  fontVariations: <FontVariation>[
                    ...(Theme.of(
                              context,
                            ).textTheme.bodyMedium?.fontVariations ??
                            const <FontVariation>[])
                        .where((v) => v.axis != 'wght'),
                    const FontVariation('wght', 700),
                  ],
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        closeIconColor: Colors.white,
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: AppVariables.snackBarDuration,
      ),
    );
  }
}
