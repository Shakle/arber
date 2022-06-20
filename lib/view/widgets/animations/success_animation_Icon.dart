import 'package:arber/logic/blocs/arb/arb_cubit.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class SuccessAnimationIcon extends StatelessWidget {
  const SuccessAnimationIcon({
    super.key,
    required this.state,
  });

  final ArbState state;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: state is ArbDone,
      child: const SizedBox(
        height: 35,
        width: 35,
        child: RiveAnimation.asset(
          'assets/animations/success_icon.riv',
        ),
      ),
    );
  }

}
