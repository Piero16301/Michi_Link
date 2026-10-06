import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/l10n/l10n.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      buildWhen: (previous, current) =>
          previous.selectedCollarId != current.selectedCollarId,
      builder: (context, state) {
        if (state.selectedCollarId == null) {
          return const _HomeNoCollarView();
        }

        return const _HomeContentView();
      },
    );
  }
}

class _HomeContentView extends StatelessWidget {
  const _HomeContentView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context);

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
                child: CatBreed.europeanOrangeWhite.svgPicture(),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Michin',
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
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        l10n.homeStatusOnline,
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '  •  ${l10n.homeTimeAgo('20s')}',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
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
              onPressed: () => unawaited(context.push(AppRoute.collars.path)),
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
              onPressed: () => unawaited(context.push(AppRoute.settings.path)),
            ),
          ),
        ],
      ),
      body: const Stack(
        children: [
          // Mapa placeholder de fondo con marcadores y controles flotantes
          Positioned.fill(child: Placeholder()),

          // Panel inferior de telemetría y métricas
          Positioned(
            left: 16,
            right: 16,
            bottom: 28,
            child: _HomeTelemetryPanel(),
          ),
        ],
      ),
    );
  }
}

class _HomeNoCollarView extends StatelessWidget {
  const _HomeNoCollarView();

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

class _HomeTelemetryPanel extends StatelessWidget {
  const _HomeTelemetryPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.all(Radius.circular(32)),
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cuadrícula 2x2 de métricas con tamaño uniforme
          Row(
            children: [
              // Tarjeta 1: Distancia
              Expanded(
                child: _MetricCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.homeDistance,
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              l10n.homeSafeZone,
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '124',
                            style: textTheme.headlineMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.homeMetersFromHome,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Tarjeta 2: Batería collar
              Expanded(
                child: _MetricCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.homeCollarBattery,
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedBatteryCharging01,
                            color: colorScheme.primary,
                            size: 17,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '85%',
                                style: textTheme.headlineMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '3.95 V',
                                style: textTheme.titleSmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              height: 5,
                              color: colorScheme.surfaceContainerHighest,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: 0.85,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              // Tarjeta 3: Posicionamiento
              Expanded(
                child: _MetricCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.homePositioning,
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedSatellite01,
                            color: colorScheme.secondary,
                            size: 16,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: colorScheme.secondary.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                            child: Text(
                              '3D Fix',
                              style: textTheme.labelMedium?.copyWith(
                                color: colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.homeActiveSatellites(15),
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Tarjeta 4: Enlace LoRa
              Expanded(
                child: _MetricCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l10n.homeLoraLink,
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              Text(
                                '915M',
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.7),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          // Indicador de barras de señal
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _signalBar(context, 6, active: true),
                              const SizedBox(width: 2.5),
                              _signalBar(context, 9, active: true),
                              const SizedBox(width: 2.5),
                              _signalBar(context, 13, active: true),
                              const SizedBox(width: 2.5),
                              _signalBar(context, 17, active: false),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '-92',
                                style: textTheme.headlineMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'dBm',
                                style: textTheme.titleSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'SNR: +8.5 dB (${l10n.homeSignalOptimal})',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Botón de acción principal M3 Expressive
          ExpressiveButton.filled(
            onPressed: () {
              // Telemetría detallada
            },
            label: l10n.homeConfigCollar,
            size: ExpressiveButtonSize.large,
            isExpanded: true,
            trailingIcon: const HugeIcon(
              icon: HugeIcons.strokeRoundedSettings02,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _signalBar(
    BuildContext context,
    double height, {
    required bool active,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 3.5,
      height: height,
      decoration: BoxDecoration(
        color: active
            ? colorScheme.primary
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Tarjeta contenedora para cada métrica con estilo M3 Expressive
class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: child,
    );
  }
}
