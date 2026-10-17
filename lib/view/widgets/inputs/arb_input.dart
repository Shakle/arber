import 'package:arber/data/enums.dart';
import 'package:arber/logic/blocs/path/path_cubit.dart';
import 'package:arber/view/widgets/animations/dash.dart';
import 'package:arber/view/widgets/buttons/file_picker_button.dart';
import 'package:arber/view/widgets/inputs/input_row.dart';
import 'package:arber/view/widgets/inputs/path_input.dart';
import 'package:arber/view/widgets/info_note.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ArbInput extends StatelessWidget {
  const ArbInput({super.key});

  @override
  Widget build(BuildContext context) {
    PathCubit pathCubit = context.read<PathCubit>();

    return MouseRegion(
      onEnter: (_) {
        dashAnimationNotifier.value = DashAnimationState.idle;
        dashAnimationNotifier.value = DashAnimationState.lookUp;
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InputRow(
            input: PathInput.mainArbPath(
              controller: pathCubit.arbFilePathController,
            ),
            fileButton: FilePickerButton.file(
              controller: pathCubit.arbFilePathController,
              tooltipMessage: 'Reference ARB file',
              artifactType: ArtifactType.mainArb,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: SizedBox(
              width: 450,
              child: InfoNote(message: 'Compares keys in this ARB and Excel'),
            ),
          ),
        ],
      ),
    );
  }
}
