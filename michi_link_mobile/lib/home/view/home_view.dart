import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final darkTheme = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          darkTheme ? AppVariables.logoNoBgDark : AppVariables.logoNoBgLight,
          width: 40,
          height: 40,
        ),
        notificationPredicate: (_) => false,
        leading: IconButton(
          onPressed: () => unawaited(context.pushNamed(AppRoute.settings.name)),
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedSettings02,
            strokeWidth: 2,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () =>
                unawaited(context.pushNamed(AppRoute.settings.name)),
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedSettings02,
              strokeWidth: 2,
            ),
          ),
        ],
      ),
      body: const Padding(padding: EdgeInsets.all(16), child: SizedBox()),
    );
  }
}
