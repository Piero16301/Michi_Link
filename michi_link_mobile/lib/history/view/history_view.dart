import 'package:expressive_kit/expressive_kit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/history/history.dart';
import 'package:michi_link_mobile/l10n/l10n.dart';
import 'package:shimmer/shimmer.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({this.collarId, super.key});

  final String? collarId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context);

    final effectiveCollarId =
        collarId ??
        context.select<HistoryCubit, String>((cubit) => cubit.state.collarId);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      extendBodyBehindAppBar: true,
      appBar: ExpressiveTopAppBar(
        backgroundColor: Colors.transparent,
        toolbarHeight: 70,
        titleSpacing: 16,
        centerTitle: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: ExpressiveIconButton.circle(
            variant: ExpressiveIconButtonVariant.tonal,
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              color: colorScheme.onSurface,
              strokeWidth: 2,
            ),
            onPressed: () => context.pop(),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedClock01,
                color: colorScheme.primary,
                size: 18,
                strokeWidth: 2,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.historyTitle,
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
      body: BlocBuilder<HistoryCubit, HistoryState>(
        builder: (context, state) {
          final cubit = context.read<HistoryCubit>();
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final isNextEnabled = state.effectiveDate.isBefore(today);

          return StreamBuilder<List<HistoryRecord>>(
            stream: getIt<DatabaseService>().getHistoryRecordsStream(
              collarId: effectiveCollarId,
              start: state.startDateTime,
              end: state.endDateTime,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const SizedBox.shrink();
              }

              final isLoading = !snapshot.hasData;
              final records = snapshot.data ?? [];
              final validRecords = records
                  .where((r) => r.coords.lat != 0 || r.coords.lon != 0)
                  .toList();
              final chronologicalRecords = validRecords.reversed.toList();

              return Stack(
                children: [
                  // Fullscreen map or loading shimmer
                  Positioned.fill(
                    child: isLoading
                        ? _buildLoadingState(context)
                        : HistoryMapView(
                            records: records,
                            selectedRecord: state.selectedRecord,
                            onRecordSelected: cubit.selectRecord,
                          ),
                  ),

                  // Floating bottom panel with date selector and time range
                  // slider
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 28,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (state.selectedRecord != null) ...[
                          HistoryRecordCarousel(
                            records: validRecords,
                            selectedRecord: state.selectedRecord,
                            onRecordSelected: cubit.selectRecord,
                            onClose: () => cubit.selectRecord(null),
                          ),
                          const SizedBox(height: 8),
                        ] else if (validRecords.isNotEmpty) ...[
                          RouteSummaryFloatingBadge(
                            count: validRecords.length,
                            startTime: chronologicalRecords.first.timestamp,
                            endTime: chronologicalRecords.last.timestamp,
                            onTap: () => cubit.selectRecord(validRecords.first),
                          ),
                          const SizedBox(height: 8),
                        ],
                        HistoryFilterCard(
                          selectedDate: state.effectiveDate,
                          isNextEnabled: isNextEnabled,
                          onPreviousDate: cubit.previousDay,
                          onNextDate: cubit.nextDay,
                          onDateSelected: cubit.selectDate,
                          startHour: state.startHour,
                          endHour: state.endHour,
                          onTimeRangeChanged: cubit.changeTimeRange,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Shimmer.fromColors(
      baseColor: isDark
          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      highlightColor: isDark
          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.8)
          : colorScheme.surfaceContainerLowest,
      child: ColoredBox(
        color: colorScheme.surfaceContainer,
        child: Center(
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedMapsLocation01,
            size: 48,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}
