import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/notifications/notifications.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({required this.deviceId, super.key});

  final String deviceId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NotificationsCubit(deviceId: deviceId),
      child: const NotificationsView(),
    );
  }
}
