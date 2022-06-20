import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class SuccessAnimationIcon extends StatelessWidget {
  const SuccessAnimationIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 35,
      width: 35,
      child: RiveAnimation.asset(
        'assets/animations/success_icon.riv',
      ),
    );
  }

}
