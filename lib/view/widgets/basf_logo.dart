import 'package:arber/gen/assets.gen.dart';
import 'package:arber/theme/colors.dart';
import 'package:flutter/material.dart';

class BasfLogo extends StatelessWidget {
  const BasfLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
        color: smoothBlue.withValues(alpha: 0.2),
        image: DecorationImage(
          alignment: const Alignment(0.9, 0),
          image: AssetImage(Assets.images.basfLogo.path),
        ),
      ),
    );
  }
}
