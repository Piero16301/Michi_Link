import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/home/home.dart';
import 'package:michi_link_mobile/l10n/l10n.dart';

class HomeContentView extends StatelessWidget {
  const HomeContentView({required this.collarId, super.key});

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
          return LoadingMapView(collarId: collarId);
        }

        if (snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final collar = snapshot.data!;

        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final textTheme = theme.textTheme;
        final l10n = AppLocalizations.of(context);

        final isOnline = collar.isOnline;
        final statusColor = isOnline ? colorScheme.primary : colorScheme.error;

        return Scaffold(
          backgroundColor: colorScheme.surface,
          extendBodyBehindAppBar: true,
          appBar: ExpressiveTopAppBar(
            showBackButton: false,
            backgroundColor: Colors.transparent,
            toolbarHeight: 70,
            titleSpacing: 16,
            centerTitle: false,
            title: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    padding: const EdgeInsets.all(2),
                    child: collar.breed.svgPicture(),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        collar.name,
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isOnline
                                ? l10n.homeStatusOnline
                                : l10n.homeStatusOffline,
                            style: textTheme.labelSmall?.copyWith(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          _HomeTimeAgoText(lastSeen: collar.lastSeen),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                ],
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ExpressiveIconButton.circle(
                  variant: ExpressiveIconButtonVariant.tonal,
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedPawPrint,
                    color: colorScheme.primary,
                    strokeWidth: 2,
                  ),
                  tooltip: l10n.homePetsTooltip,
                  onPressed: () =>
                      unawaited(context.push(AppRoute.collars.path)),
                ),
              ),
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
                  onPressed: () =>
                      unawaited(context.push(AppRoute.settings.path)),
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              Positioned.fill(child: HomeMapView(collar: collar)),
              Positioned(
                left: 16,
                right: 16,
                bottom: 28,
                child: HomeTelemetryPanel(collar: collar),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HomeTimeAgoText extends StatefulWidget {
  const _HomeTimeAgoText({required this.lastSeen});

  final DateTime lastSeen;

  @override
  State<_HomeTimeAgoText> createState() => _HomeTimeAgoTextState();
}

class _HomeTimeAgoTextState extends State<_HomeTimeAgoText> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final diff = DateTime.now().difference(widget.lastSeen).inSeconds;
    final seconds = diff < 0 ? 0 : diff;

    return Text(
      '  •  ${l10n.homeTimeAgo(seconds)}',
      style: textTheme.labelSmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontSize: 11,
      ),
    );
  }
}
