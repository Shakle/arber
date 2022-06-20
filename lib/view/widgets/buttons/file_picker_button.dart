import 'package:arber/data/enums.dart';
import 'package:arber/logic/blocs/path/path_cubit.dart';
import 'package:arber/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FilePickerButton extends StatefulWidget {

  FilePickerButton.file({
    super.key,
    required this.controller,
  }) {
    pickType = PickType.file;
  }

  FilePickerButton.directory({
    super.key,
    required this.controller,
  }) {
    pickType = PickType.directory;
  }

  late final PickType pickType;
  final TextEditingController controller;

  @override
  State<FilePickerButton> createState() => _FilePickerButtonState();
}

class _FilePickerButtonState extends State<FilePickerButton> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return iconButton(context);
  }

  Widget iconButton(BuildContext context) {
    return IconButton(
        onPressed: isLoading
            ? null
            : () => onPressed(context.read<PathCubit>()),
        icon: isLoading ? loader() : fileIcon(),
    );
  }

  Widget fileIcon() {
    return const Icon(
        Icons.folder_outlined,
        color: Colors.black54,
    );
  }

  Widget loader() {
    return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(color: smoothBlue),
    );
  }

  Future<void> onPressed(PathCubit pathCubit) async {
    setState(() => isLoading = true);

    switch (widget.pickType) {
      case PickType.file:
        await pathCubit.pickExcelFile();
        break;
      case PickType.directory:
        await pathCubit.pickL10nDirectory();
        break;
    }

    setState(() => isLoading = false);
  }
}
