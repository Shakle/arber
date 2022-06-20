import 'package:arber/logic/blocs/path/path_cubit.dart';
import 'package:arber/view/widgets/buttons/file_picker_button.dart';
import 'package:arber/view/widgets/inputs/path_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FileInputs extends StatelessWidget {
  const FileInputs({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return inputs(context);
  }

  Widget inputs(BuildContext context) {
    PathCubit pathCubit = context.read<PathCubit>();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        inputRow(
          input: PathInput.excelPath(
            controller: pathCubit.excelFilePathController,
          ),
          fileButton: FilePickerButton.file(
            controller: pathCubit.excelFilePathController,
          ),
        ),
        const SizedBox(height: 20),
        inputRow(
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

  Widget inputRow({
    required PathInput input,
    required FilePickerButton fileButton,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        input,
        const SizedBox(width: 20),
        fileButton,
      ],
    );
  }
}
