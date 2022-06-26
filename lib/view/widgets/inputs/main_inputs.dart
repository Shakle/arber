import 'package:arber/data/enums.dart';
import 'package:arber/logic/blocs/path/path_cubit.dart';
import 'package:arber/view/widgets/buttons/file_picker_button.dart';
import 'package:arber/view/widgets/inputs/input_row.dart';
import 'package:arber/view/widgets/inputs/path_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FileInputs extends StatelessWidget {
  const FileInputs({super.key});

  @override
  Widget build(BuildContext context) {
    return inputs(context);
  }

  Widget inputs(BuildContext context) {
    PathCubit pathCubit = context.read<PathCubit>();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InputRow(
          input: PathInput.excelPath(
            controller: pathCubit.excelFilePathController,
          ),
          fileButton: FilePickerButton.file(
            controller: pathCubit.excelFilePathController,
            artifactType: ArtifactType.excel,
          ),
        ),
        const SizedBox(height: 20),
        InputRow(
          input: PathInput.l10nPath(
            controller: pathCubit.l10nDirectoryPathController,
          ),
          fileButton: FilePickerButton.directory(
            controller: pathCubit.l10nDirectoryPathController,
          ),
        ),
      ],
    );
  }
}
