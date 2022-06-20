import 'package:arber/logic/blocs/arb/arb_cubit.dart';
import 'package:arber/theme/colors.dart';
import 'package:arber/view/widgets/animations/dash.dart';
import 'package:arber/view/widgets/animations/success_animation_Icon.dart';
import 'package:arber/view/widgets/background_field.dart';
import 'package:arber/view/widgets/basf_logo.dart';
import 'package:arber/view/widgets/buttons/arb_button.dart';
import 'package:arber/view/widgets/inputs/input_row.dart';
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
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(flex: 3, child: BasfLogo()),
            const Spacer(),
            BackgroundField(
              child: inputsAndGenerateButton(),
            ),
          ],
        ),
        const Spacer(),
        const Align(
            alignment: Alignment(0.95, 0),
            child: DashAnimation(),
        ),
        const SizedBox(height: 20),
      ],
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
            child: arbButton(),
        ),
      ],
    );
  }

  Widget arbButton() {
    return BlocBuilder<ArbCubit, ArbState>(
      builder: (context, state) {
        return Row(
          children: [
            SuccessAnimationIcon(state: state),
            const SizedBox(width: 10),
            const ArbButton(),
          ],
        );
      }
    );
  }
}
