import 'package:expressive_kit/expressive_kit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/l10n/l10n.dart';
import 'package:michi_link_mobile/notifications/notifications.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({this.collarId, super.key});

  final String? collarId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context);

    final effectiveCollarId =
        collarId ??
        context.select<NotificationsCubit, String>(
          (cubit) => cubit.state.collarId,
        );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: ExpressiveTopAppBar(
        centerTitle: false,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: ExpressiveIconButton.circle(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              color: colorScheme.onSurface,
            ),
            onPressed: () => context.pop(),
          ),
        ),
        title: Text(
          l10n.collarsNotificationsTooltip,
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: StreamBuilder<List<AlertRecord>>(
        stream: getIt<DatabaseService>().getAlertRecordsStream(
          collarId: effectiveCollarId,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const SizedBox.shrink();
          }

          if (!snapshot.hasData) {
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: 5,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, _) => const LoadingNotificationCard(),
            );
          }

          final alerts = snapshot.data ?? [];

          if (alerts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedNotification01,
                          color: colorScheme.onSurfaceVariant,
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.notificationsEmptyTitle,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.notificationsEmptyDescription,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final items = _buildGroupedItems(alerts);

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: items.length,
            separatorBuilder: (context, index) {
              final nextItem = items[index + 1];
              if (nextItem is _DateHeaderItem) {
                return const SizedBox(height: 16);
              }
              return const SizedBox(height: 12);
            },
            itemBuilder: (context, index) {
              final item = items[index];
              return switch (item) {
                _DateHeaderItem(:final date) => _NotificationDateHeader(
                  date: date,
                ),
                _AlertCardItem(:final alert) => NotificationCard(alert: alert),
              };
            },
          );
        },
      ),
    );
  }

  static List<_NotificationListItem> _buildGroupedItems(
    List<AlertRecord> alerts,
  ) {
    final items = <_NotificationListItem>[];
    DateTime? currentDay;

    for (final alert in alerts) {
      final alertDay = DateTime(
        alert.timestamp.year,
        alert.timestamp.month,
        alert.timestamp.day,
      );

      if (currentDay == null || alertDay != currentDay) {
        items.add(_DateHeaderItem(alertDay));
        currentDay = alertDay;
      }

      items.add(_AlertCardItem(alert));
    }

    return items;
  }
}

sealed class _NotificationListItem {}

class _DateHeaderItem extends _NotificationListItem {
  _DateHeaderItem(this.date);
  final DateTime date;
}

class _AlertCardItem extends _NotificationListItem {
  _AlertCardItem(this.alert);
  final AlertRecord alert;
}

class _NotificationDateHeader extends StatelessWidget {
  const _NotificationDateHeader({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(date.year, date.month, date.day);

    final String label;
    if (itemDate == today) {
      label = l10n.notificationsToday;
    } else if (itemDate == yesterday) {
      label = l10n.notificationsYesterday;
    } else {
      final locale = Localizations.localeOf(context).toString();
      label = DateFormat.yMMMMEEEEd(locale).format(date);
    }

    final formattedLabel = label.isNotEmpty
        ? '${label[0].toUpperCase()}${label.substring(1)}'
        : label;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedCalendar03,
                    size: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formattedLabel,
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }
}
