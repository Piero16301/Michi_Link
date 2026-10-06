import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/l10n/l10n.dart';

class HomeNoCollarView extends StatelessWidget {
  const HomeNoCollarView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: ExpressiveTopAppBar(
        title: null,
        showBackButton: false,
        backgroundColor: Colors.transparent,
        toolbarHeight: 70,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ExpressiveIconButton.circle(
              variant: ExpressiveIconButtonVariant.tonal,
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedSettings02,
                color: colorScheme.onSurfaceVariant,
                strokeWidth: 2,
              ),
              tooltip: l10n.settingsAppBarTitle,
              onPressed: () => unawaited(context.push(AppRoute.settings.path)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.14),
                        blurRadius: 36,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(22),
                  child: CatBreed.defaultBreed.svgPicture(
                    colorFilter: ColorFilter.mode(
                      colorScheme.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  l10n.homeNoCollarTitle,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Text(
                    l10n.homeNoCollarDescription,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ExpressiveButton.filled(
                  label: l10n.homeGoToPets,
                  size: ExpressiveButtonSize.large,
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedPawPrint,
                    size: 20,
                  ),
                  onPressed: () =>
                      unawaited(context.push(AppRoute.collars.path)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
