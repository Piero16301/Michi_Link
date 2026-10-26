import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/history/history.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({required this.deviceId, super.key});

  final String deviceId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HistoryCubit(deviceId: deviceId),
      child: const HistoryView(),
    );
  }
}
