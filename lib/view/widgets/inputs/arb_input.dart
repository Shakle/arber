import 'package:arber/data/enums.dart';
import 'package:arber/logic/blocs/path/path_cubit.dart';
import 'package:arber/view/widgets/buttons/file_picker_button.dart';
import 'package:arber/view/widgets/inputs/input_row.dart';
import 'package:arber/view/widgets/inputs/path_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ArbInput extends StatelessWidget {
  const ArbInput({super.key});

  @override
  Widget build(BuildContext context) {
    PathCubit pathCubit = context.read<PathCubit>();

    return InputRow(
      input: PathInput.mainArbPath(
        controller: pathCubit.arbFilePathController,
      ),
      fileButton: FilePickerButton.file(
        controller: pathCubit.arbFilePathController,
        tooltipMessage: 'Main Arb file',
        artifactType: ArtifactType.mainArb,
      ),
    );
  }
}
