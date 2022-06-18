import 'package:arber/logic/blocs/path/path_cubit.dart';
import 'package:arber/view/widgets/buttons/arb_button.dart';
import 'package:arber/view/widgets/buttons/file_picker_button.dart';
import 'package:arber/view/widgets/path_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
          padding: EdgeInsets.all(MediaQuery.of(context).size.height * 0.05),
          child: body()),
    );
  }

  Widget body() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: title()),
          Expanded(child: inputs()),
          Expanded(child: arbButton()),
        ],
      ),
    );
  }

  Widget title() {
    return Builder(
      builder: (context) {
        return Center(
          child: Text(
            'Let\'s connect',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        );
      }
    );
  }

  Widget inputs() {
    return Builder(
      builder: (context) {
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
            const SizedBox(height: 10),
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
    );
  }

  Widget inputRow({
    required PathInput input,
    required FilePickerButton fileButton,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        input,
        const SizedBox(width: 20),
        fileButton,
      ],
    );
  }

  Widget arbButton() {
    return const Center(
        child: ArbButton(),
    );
  }
}
