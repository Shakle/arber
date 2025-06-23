import 'package:arber/gen/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

enum DashAnimationState {
  idle('idle'),
  slowDance('dance'),
  lookUp('look up');

  const DashAnimationState(this.value);

  final String value;
}

final dashAnimationNotifier = ValueNotifier(DashAnimationState.idle);

class DashAnimation extends StatefulWidget {
  const DashAnimation({
    super.key,
    this.initialAnimation = DashAnimationState.idle,
  });

  final DashAnimationState initialAnimation;

  @override
  State<DashAnimation> createState() => _DashAnimationState();
}

class _DashAnimationState extends State<DashAnimation> {

  late SMIInput<bool> slowDanceInput;
  late SMIInput<bool> lookUpInput;

  @override
  void initState() {
    super.initState();
    dashAnimationNotifier.addListener(changeAnimation);
  }

  void changeAnimation() {
    switch(dashAnimationNotifier.value) {
      case DashAnimationState.idle:
        slowDanceInput.value = false;
        lookUpInput.value = false;
      case DashAnimationState.slowDance:
        lookUpInput.value = false;
        slowDanceInput.value = true;
      case DashAnimationState.lookUp:
        slowDanceInput.value = false;
        lookUpInput.value = true;
    }
  }

  void _onRiveInit(Artboard artBoard) {
    final stateMachineController = StateMachineController.fromArtboard(
      artBoard,
      'birb',
    );

    if (stateMachineController != null) {
      artBoard.addController(stateMachineController);
      slowDanceInput = stateMachineController.findInput<bool>(
        DashAnimationState.slowDance.value,
      )!;
      lookUpInput = stateMachineController.findInput<bool>(
        DashAnimationState.lookUp.value,
      )!;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        dashAnimationNotifier.value = widget.initialAnimation;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    dashAnimationNotifier
      ..removeListener(changeAnimation)
      ..value = DashAnimationState.idle;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.16,
      width: MediaQuery.of(context).size.height * 0.16,
      child: RiveAnimation.asset(
        Assets.animations.dash.path,
        onInit: _onRiveInit,
      ),
    );
  }
}
