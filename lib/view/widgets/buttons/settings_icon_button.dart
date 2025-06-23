import 'package:arber/theme/colors.dart';
import 'package:arber/view/screens/settings_screen.dart';
import 'package:arber/view/widgets/animations/dash.dart';
import 'package:flutter/material.dart';

class SettingsIconButton extends StatefulWidget {
  const SettingsIconButton({super.key});

  @override
  State<SettingsIconButton> createState() => _SettingsIconButtonState();
}

class _SettingsIconButtonState extends State<SettingsIconButton> {

  final double defaultIconSize = 25;
  double currentIconSize = 25;
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          dashAnimationNotifier.value = DashAnimationState.idle;
          dashAnimationNotifier.value = DashAnimationState.lookUp;
          isHovered = true;
          currentIconSize = defaultIconSize - 2;
        });
      },
      onExit: (_) {
        setState(() {
          isHovered = false;
          currentIconSize = defaultIconSize;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: smoothBlue.withValues(alpha: 0.25),
          shape: BoxShape.circle,
        ),
        child: AnimatedRotation(
          duration: const Duration(milliseconds: 150),
          turns: isHovered ? -0.25 : 0,
          child: IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
              ));
            },
            tooltip: 'Settings',
            iconSize: currentIconSize,
            icon: const Icon(Icons.settings, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
