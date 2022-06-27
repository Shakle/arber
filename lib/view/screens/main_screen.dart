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
            const Expanded(
                flex: 3,
                child: BasfLogo(),
            ),
            const Spacer(),
            BackgroundField(
              borderRadius: leftRoundBorderRadius,
              child: inputsAndGenerateButton(),
            ),
          ],
        ),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BackgroundField(
                borderRadius: rightRoundBorderRadius,
                child: const ArbInput(),
              ),
              const Spacer(),
              Expanded(
                flex: 7,
                child: BackgroundField(
                  borderRadius: allRoundBorderRadius,
                  child: ListView(
                    children: const [
                      Center(child: Text('test')),
                      Center(child: Text('test')),
                      Center(child: Text('test')),
                      Center(child: Text('test')),
                      Center(child: Text('test')),
                      Center(child: Text('test')),
                      Center(child: Text('test')),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 3,),
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
