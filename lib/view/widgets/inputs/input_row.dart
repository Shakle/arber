import 'package:arber/view/widgets/buttons/file_picker_button.dart';
import 'package:arber/view/widgets/inputs/path_input.dart';
import 'package:flutter/material.dart';

class InputRow extends StatelessWidget {

  const InputRow({
    super.key,
    required this.input,
    required this.fileButton,
    this.isLeft = true,
  });

  final PathInput input;
  final FilePickerButton fileButton;
  final bool isLeft;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: isLeft ? leftLayout() : rightLayout(),
    );
  }

  List<Widget> leftLayout() {
    return [
      input,
      const SizedBox(width: 20),
      fileButton,
    ];
  }

  List<Widget> rightLayout() {
    return [
      fileButton,
      const SizedBox(width: 20),
      input,
    ];
  }
}