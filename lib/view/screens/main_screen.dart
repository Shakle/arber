import 'package:arber/logic/blocs/arb/arb_cubit.dart';
import 'package:arber/theme/borders.dart';
import 'package:arber/theme/colors.dart';
import 'package:arber/view/widgets/animations/dash.dart';
import 'package:arber/view/widgets/animations/success_animation.dart';
import 'package:arber/view/widgets/background_field.dart';
import 'package:arber/view/widgets/basf_logo.dart';
import 'package:arber/view/widgets/buttons/generate_button.dart';
import 'package:arber/view/widgets/description.dart';
import 'package:arber/view/widgets/inputs/arb_input.dart';
import 'package:arber/view/widgets/inputs/main_inputs.dart';
import 'package:arber/view/widgets/missing_translation.dart';
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
    return Row(
      children: [
        Expanded(child: leftColumn(context)),
        SizedBox(width: MediaQuery.of(context).size.width * 0.05),
        rightColumn(),
      ],
    );
  }

  Widget rightColumn() {
    return Builder(
      builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.08),
            BackgroundField(
              borderRadius: leftRoundBorderRadius,
              child: inputsAndGenerateButton(),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.08),
            BackgroundField(
              borderRadius: leftRoundBorderRadius,
              child: const ArbInput(),
            ),
            const Spacer(),
            Stack(
              children: [
                bird(),
                const Description(),
              ],
            ),
          ],
        );
      }
    );
  }

  Widget leftColumn(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.18),
        const Align(
            alignment: Alignment(-1, 0.6),
            child: BasfLogo()
        ),
        Expanded(
          child: Align(
            child: Padding(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.03),
              child: const MissingTranslationWindow()
            ),
          ),
        ),
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
              AnimatedOpacity(
                opacity: state is ArbDone || state is ArbFailed ? 1 : 0,
                duration: const Duration(milliseconds: 250),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: state is ArbDone ? const SuccessAnimationIcon()
                      : state is ArbFailed ? failIcon(state)
                      : const SizedBox(),
                ),
              ),
              const SizedBox(width: 10),
              const GenerateButton(),
            ],
          );
        }
    );
  }

  Widget failIcon(ArbFailed arbFailed) {
    return Tooltip(
      message: arbFailed.exception.toString(),
      child: Icon(
        Icons.close,
        size: 30,
        color: Colors.red.shade700,
      ),
    );
  }
}
