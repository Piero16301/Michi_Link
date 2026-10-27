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
  const HistoryView({this.deviceId, super.key});

  final String? deviceId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context);

    final effectiveDeviceId =
        deviceId ??
        context.select<HistoryCubit, String>((cubit) => cubit.state.deviceId);

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

          return _HistoryStreamContent(
            deviceId: effectiveDeviceId,
            startDateTime: state.startDateTime,
            endDateTime: state.endDateTime,
            state: state,
            cubit: cubit,
            isNextEnabled: isNextEnabled,
          );
        },
      ),
    );
  }
}

class _HistoryStreamContent extends StatefulWidget {
  const _HistoryStreamContent({
    required this.deviceId,
    required this.startDateTime,
    required this.endDateTime,
    required this.state,
    required this.cubit,
    required this.isNextEnabled,
  });

  final String deviceId;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final HistoryState state;
  final HistoryCubit cubit;
  final bool isNextEnabled;

  @override
  State<_HistoryStreamContent> createState() => _HistoryStreamContentState();
}

class _HistoryStreamContentState extends State<_HistoryStreamContent> {
  late Stream<List<HistoryRecord>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = _createStream();
  }

  @override
  void didUpdateWidget(_HistoryStreamContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deviceId != widget.deviceId ||
        oldWidget.startDateTime != widget.startDateTime ||
        oldWidget.endDateTime != widget.endDateTime) {
      _stream = _createStream();
    }
  }

  Stream<List<HistoryRecord>> _createStream() {
    return getIt<DatabaseService>().getHistoryRecordsStream(
      deviceId: widget.deviceId,
      start: widget.startDateTime,
      end: widget.endDateTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context);

    return StreamBuilder<List<HistoryRecord>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedAlert02,
                  size: 48,
                  color: colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.collarsStatusDisconnected,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          );
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
              child: RepaintBoundary(
                child: isLoading
                    ? _buildLoadingState(context)
                    : HistoryMapView(
                        records: records,
                        selectedRecord: widget.state.selectedRecord,
                        onRecordSelected: widget.cubit.selectRecord,
                      ),
              ),
            ),

            // Floating bottom panel with date selector and time range
            // slider
            Positioned(
              left: 16,
              right: 16,
              bottom: 28,
              child: RepaintBoundary(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.state.selectedRecord != null) ...[
                      HistoryRecordCarousel(
                        records: validRecords,
                        selectedRecord: widget.state.selectedRecord,
                        onRecordSelected: widget.cubit.selectRecord,
                        onClose: () => widget.cubit.selectRecord(null),
                      ),
                      const SizedBox(height: 8),
                    ] else if (validRecords.isNotEmpty) ...[
                      RouteSummaryFloatingBadge(
                        count: validRecords.length,
                        startTime: chronologicalRecords.first.timestamp,
                        endTime: chronologicalRecords.last.timestamp,
                        onTap: () =>
                            widget.cubit.selectRecord(validRecords.first),
                      ),
                      const SizedBox(height: 8),
                    ],
                    HistoryFilterCard(
                      selectedDate: widget.state.effectiveDate,
                      isNextEnabled: widget.isNextEnabled,
                      onPreviousDate: widget.cubit.previousDay,
                      onNextDate: widget.cubit.nextDay,
                      onDateSelected: widget.cubit.selectDate,
                      startHour: widget.state.startHour,
                      endHour: widget.state.endHour,
                      onTimeRangeChanged: widget.cubit.changeTimeRange,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
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
