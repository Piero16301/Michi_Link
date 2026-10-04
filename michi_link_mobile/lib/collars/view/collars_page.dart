import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/collars/collars.dart';

class CollarsPage extends StatelessWidget {
  const CollarsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CollarsCubit(),
      child: const CollarsView(),
    );
  }
}
