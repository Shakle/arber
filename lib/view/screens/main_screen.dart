import 'package:arber/logic/blocs/arb/arb_cubit.dart';
import 'package:arber/theme/borders.dart';
import 'package:arber/theme/colors.dart';
import 'package:arber/view/widgets/animations/dash.dart';
import 'package:arber/view/widgets/animations/success_animation.dart';
import 'package:arber/view/widgets/background_field.dart';
import 'package:arber/view/widgets/basf_logo.dart';
import 'package:arber/view/widgets/buttons/generate_button.dart';
import 'package:arber/view/widgets/inputs/arb_input.dart';
import 'package:arber/view/widgets/inputs/main_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: backgroundGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: body(context),
      ),
    );
  }

  Widget body(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.1),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(flex: 3, child: BasfLogo()),
            const Spacer(),
            BackgroundField(
              borderRadius: leftRoundBorderRadius,
              child: inputsAndGenerateButton(),
            ),
          ],
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              BackgroundField(
                borderRadius: rightRoundBorderRadius,
                child: const ArbInput(),
              ),
              const Spacer(),
            ],
          ),
        ),
        bird(),
      ],
    );
  }

  Widget bird() {
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      alignment: const Alignment(0.99, 1),
      child: const DashAnimation(),
    );
  }

  Widget inputsAndGenerateButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const FileInputs(),
        const SizedBox(height: 20),
        Padding(
            padding: const EdgeInsets.only(right: 60),
            child: generateButton(),
        ),
      ],
    );
  }

  Widget generateButton() {
    return BlocBuilder<ArbCubit, ArbState>(
      builder: (context, state) {
        return Row(
          children: [
            Visibility(
                visible: state is ArbDone,
                child: const Tooltip(
                    message: 'Arb files are already in l10 directory',
                    child: SuccessAnimationIcon(),
                ),
            ),
            Visibility(
              visible: state is ArbFailed,
              child: failIcon(),
            ),
            const SizedBox(width: 10),
            const GenerateButton(),
          ],
        );
      }
    );
  }

  Widget failIcon() {
    return Tooltip(
      message: 'Arb generation failed',
      child: Icon(
          Icons.close,
          size: 30,
          color: Colors.red.shade700,
      ),
    );
  }
}
