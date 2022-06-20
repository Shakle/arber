import 'package:arber/theme/colors.dart';
import 'package:flutter/material.dart';

class BackgroundField extends StatelessWidget {
  const BackgroundField({
    super.key,
    required this.child,
  });

  final Widget child;

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
            padding: const EdgeInsets.only(
              top: 40,
              bottom: 40,
              left: 40,
              right: 80,
            ),
            child: child,
          ),
      ),
    );
  }

  BorderRadius get borderRadius {
    return const BorderRadius.only(
      topLeft: Radius.circular(15),
      bottomLeft: Radius.circular(15),
    );
  }
}
