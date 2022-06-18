import 'package:arber/logic/blocs/arb/arb_cubit.dart';
import 'package:arber/logic/blocs/path/path_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ArbButton extends StatelessWidget {
  const ArbButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return generateArbButton(context);
  }

  Widget generateArbButton(BuildContext context) {
    return TextButton(
        style: TextButton.styleFrom(
          backgroundColor: Colors.blue,
          primary: Colors.white,
          padding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () {
          PathState state = context.read<PathCubit>().state;

          if (state is PathConnected) {
            context.read<ArbCubit>()
                .generateARBs(
                state.pathArtifact.excelFile.path,
                state.pathArtifact.l10nDirectory,
            );
          }
        },
        child: const Text('Create Arb files'),
    );
  }
}
