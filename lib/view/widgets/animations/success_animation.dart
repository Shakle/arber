import 'package:arber/theme/colors.dart';
import 'package:flutter/material.dart';

class SuccessAnimationIcon extends StatelessWidget {
  const SuccessAnimationIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return const Tooltip(
      message: 'Arb files are already in l10 directory',
      child: Icon(
        Icons.check_circle,
        color: smoothBlue,
        size: 28,
      ),
    );
  }

}
