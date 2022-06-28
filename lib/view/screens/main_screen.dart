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
                Tooltip(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: allRoundBorderRadius,
                    boxShadow: const [
                      lightShadow,
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  margin: EdgeInsets.only(right: MediaQuery.of(context).size.width * 0.08),
                  verticalOffset: 0,
                  textStyle: const TextStyle(color: Colors.black),
                  message: 'Hi 🐦, this is how to use it.'
                      '\n\n1. Share .xlsx file across your team'
                      '\n2. Edit it online in a browser'
                      '\n3. Download a copy of .xlsx'
                      '\n4. Choose the file in first input'
                      '\n5. Choose project l10n directory in the second one'
                      '\n6. Choose main arb file to match if something is missing in excel'
                      '\n7. Click refresh on the left to see any missing translations'
                      '\n8. Click create translations to put new .arb files to your project'
                      '\n9. Only en, de, es are currently supported'
                      '\n\n Thanks for using ❤️',
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.15,
                    width: MediaQuery.of(context).size.height * 0.16,
                  ),
                ),
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
            alignment: Alignment.center,
            child: Padding(
                padding: EdgeInsets.all(
                    MediaQuery.of(context).size.width * 0.03,
                ),
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
              Stack(
                children: [
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: state is ArbDone ? 1 : 0,
                    child: const SuccessAnimationIcon(),
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: state is ArbFailed ? 1 : 0,
                    child: failIcon(),
                  ),
                ],
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
