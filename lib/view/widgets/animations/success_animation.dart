import 'package:arber/theme/colors.dart';
import 'package:flutter/material.dart';

class SuccessAnimationIcon extends StatelessWidget {
  const SuccessAnimationIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.check_circle,
      color: smoothBlue,
      size: 28,
    );
  }

}
