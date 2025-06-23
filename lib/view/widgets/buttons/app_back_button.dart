import 'package:arber/theme/colors.dart';
import 'package:flutter/material.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      style: FilledButton.styleFrom(
        shape: const CircleBorder(),
        backgroundColor: smoothBlue.withValues(alpha: 0.25),
      ),
        onPressed: () => Navigator.pop(context),
        iconSize: 25,
        icon: const Padding(
          padding: EdgeInsets.only(left: 9),
          child: Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ),
        ),
    );
  }
}
