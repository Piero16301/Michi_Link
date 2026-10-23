import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/l10n/l10n.dart';

class HistoryRecordCarousel extends StatefulWidget {
  const HistoryRecordCarousel({
    required this.records,
    required this.onClose,
    required this.onRecordSelected,
    this.selectedRecord,
    super.key,
  });

  final List<HistoryRecord> records;
  final HistoryRecord? selectedRecord;
  final ValueChanged<HistoryRecord> onRecordSelected;
  final VoidCallback onClose;

  @override
  State<HistoryRecordCarousel> createState() => _HistoryRecordCarouselState();
}

class _HistoryRecordCarouselState extends State<HistoryRecordCarousel> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.selectedRecord != null
        ? widget.records.indexOf(widget.selectedRecord!)
        : 0;
    _currentIndex = initialIndex >= 0 ? initialIndex : 0;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void didUpdateWidget(HistoryRecordCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedRecord != null &&
        widget.selectedRecord != oldWidget.selectedRecord) {
      final index = widget.records.indexOf(widget.selectedRecord!);
      if (index >= 0 && index != _currentIndex) {
        _currentIndex = index;
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.records.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 112,
      child: PageView.builder(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        itemCount: widget.records.length,
        onPageChanged: (index) {
          if (_currentIndex != index) {
            _currentIndex = index;
            widget.onRecordSelected(widget.records[index]);
          }
        },
        itemBuilder: (context, index) {
          final record = widget.records[index];
          return _RecordCarouselCardItem(
            record: record,
            index: index,
            totalCount: widget.records.length,
            onClose: widget.onClose,
            onPrevious: index > 0
                ? () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                  )
                : null,
            onNext: index < widget.records.length - 1
                ? () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                  )
                : null,
          );
        },
      ),
    );
  }
}

class _RecordCarouselCardItem extends StatelessWidget {
  const _RecordCarouselCardItem({
    required this.record,
    required this.index,
    required this.totalCount,
    required this.onClose,
    this.onPrevious,
    this.onNext,
  });

  final HistoryRecord record;
  final int index;
  final int totalCount;
  final VoidCallback onClose;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context);

    final isGpsFixed = record.status.gpsFix;
    final gpsBadgeColor = isGpsFixed ? colorScheme.primary : colorScheme.error;
    final timeStr = DateFormat('HH:mm:ss').format(record.timestamp);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header: Seq, Time, Index Indicator, GPS status & Close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedRoute01,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${l10n.historyRecordSeq(record.seq)} • $timeStr',
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      l10n.historyCarouselIndex(index + 1, totalCount),
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (record.radio.packetsLostGap > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colorScheme.error.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedAlertCircle,
                            size: 11,
                            color: colorScheme.error,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            l10n.historyLostPackets(
                              record.radio.packetsLostGap,
                            ),
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.error,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: gpsBadgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: gpsBadgeColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      isGpsFixed
                          ? l10n.historyValueSatellites(record.status.sats)
                          : l10n.historyGpsNoFix,
                      style: textTheme.labelSmall?.copyWith(
                        color: gpsBadgeColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onClose,
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedCancel01,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Coords & Altitude
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedLocation01,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${record.coords.lat.toStringAsFixed(6)}, '
                  '${record.coords.lon.toStringAsFixed(6)}',
                  style: textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: colorScheme.onSurface,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              HugeIcon(
                icon: HugeIcons.strokeRoundedMountain,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                l10n.historyValueAltitude(
                  record.coords.altM.toStringAsFixed(1),
                ),
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Telemetry row: Battery, Distance, Signal covering full card width
          Row(
            children: [
              Expanded(
                child: _AttributePill(
                  icon: HugeIcons.strokeRoundedBatteryCharging01,
                  text: l10n.historyValueBatteryVoltage(
                    record.status.batteryPct,
                    record.status.batteryV.toStringAsFixed(1),
                  ),
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _AttributePill(
                  icon: HugeIcons.strokeRoundedHome03,
                  text: l10n.historyValueDistance(
                    record.radio.distanceHomeM.toStringAsFixed(1),
                  ),
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _AttributePill(
                  icon: HugeIcons.strokeRoundedSignalLow01,
                  text: l10n.historyValueSignal(record.radio.rssi),
                  colorScheme: colorScheme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttributePill extends StatelessWidget {
  const _AttributePill({
    required this.icon,
    required this.text,
    required this.colorScheme,
  });

  final List<List<dynamic>> icon;
  final String text;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = colorScheme.onSurface;
    final bg = colorScheme.surfaceContainerHighest.withValues(alpha: 0.65);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(icon: icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: theme.textTheme.labelMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
