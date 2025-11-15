import 'package:arber/data/enums.dart';
import 'package:arber/logic/blocs/path/path_cubit.dart';
import 'package:arber/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FilePickerButton extends StatefulWidget {

  FilePickerButton.file({
    super.key,
    required this.controller,
    required this.tooltipMessage,
    required ArtifactType artifactType,
  }) {
    pickType = PickType.file;
    _artifactType = artifactType;
  }

  FilePickerButton.directory({
    super.key,
    required this.controller,
    required this.tooltipMessage,
  }) {
    pickType = PickType.directory;
  }

  late final PickType pickType;
  late final ArtifactType? _artifactType;
  final TextEditingController controller;
  final String tooltipMessage;

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
    return Tooltip(
      message: widget.tooltipMessage,
      child: IconButton(
          onPressed: isLoading
              ? null
              : () => onPressed(context.read<PathCubit>()),
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: isLoading ? loader() : fileIcon(),
          ),
      ),
    );
  }

  Widget fileIcon() {
    return const Icon(
      key: ValueKey('file_icon'),
      Icons.folder_outlined,
      color: Colors.black54,
    );
  }

  Widget loader() {
    return const SizedBox(
      key: ValueKey('file_loader'),
      height: 20,
      width: 20,
      child: CircularProgressIndicator(color: smoothBlue),
    );
  }

  Future<void> onPressed(PathCubit pathCubit) async {
    setState(() => isLoading = true);

    switch (widget.pickType) {
      case PickType.file: switch(widget._artifactType) {
        case ArtifactType.excel: await pathCubit.pickExcelFile();
        case ArtifactType.mainArb: await pathCubit.pickMainArbFile();
        default: break;
      }
      case PickType.directory: await pathCubit.pickL10nDirectory();
    }

    setState(() => isLoading = false);
  }
}
