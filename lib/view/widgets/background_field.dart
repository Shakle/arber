import 'package:arber/theme/colors.dart';
import 'package:flutter/material.dart';

class BackgroundField extends StatelessWidget {
  const BackgroundField({
    super.key,
    required this.borderRadius,
    required this.child,
  });

  final Widget child;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return field();
  }

  Widget field() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: const [
          lightShadow,
        ],
        borderRadius: borderRadius,
      ),
      child: Material(
        borderRadius: borderRadius,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: child,
          ),
      ),
    );
  }
}
