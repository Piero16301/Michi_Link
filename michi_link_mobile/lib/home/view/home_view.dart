import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:michi_link_mobile/home/home.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      buildWhen: (previous, current) =>
          previous.selectedCollarId != current.selectedCollarId,
      builder: (context, state) {
        if (state.selectedCollarId == null) {
          return const HomeNoCollarView();
        }

        return HomeContentView(collarId: state.selectedCollarId!);
      },
    );
  }
}
