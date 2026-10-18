import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/history/history.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({required this.collarId, super.key});

  final String collarId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HistoryCubit(collarId: collarId),
      child: const HistoryView(),
    );
  }
}
