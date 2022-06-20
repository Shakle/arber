import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class DashAnimation extends StatelessWidget {
  const DashAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.16,
      width: MediaQuery.of(context).size.height * 0.16,
      child: const RiveAnimation.asset(
        'assets/animations/dash.riv',
      ),
    );
  }
}
