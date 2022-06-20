import 'package:arber/logic/blocs/arb/arb_cubit.dart';
import 'package:arber/logic/blocs/path/path_cubit.dart';
import 'package:arber/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ArbButton extends StatelessWidget {
  const ArbButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return generateArbButton(context);
  }

  Widget generateArbButton(BuildContext context) {
    return Builder(
      builder: (context) {
        PathState pathState = context.watch<PathCubit>().state;
        ArbState arbState = context.watch<ArbCubit>().state;

        bool isActive = pathState is PathConnected
            && arbState is! ArbGenerating;

        return AbsorbPointer(
          absorbing: !isActive,
          child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: isActive ? smoothBlue : Colors.grey.shade200,
                primary: isActive ? Colors.white : Colors.grey,
                padding: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                if (isActive) {
                  context.read<ArbCubit>().generateARBs(
                    pathState.pathArtifact.excelFile.path,
                    pathState.pathArtifact.l10nDirectory,
                  );
                }
              },
              child: const Text('Create translations'),
          ),
        );
      }
    );
  }
}
