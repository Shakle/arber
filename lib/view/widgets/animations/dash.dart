import 'package:arber/gen/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

// ignore_for_file: deprecated_member_use

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
  late final FileLoader _fileLoader = FileLoader.fromAsset(
    Assets.animations.dash,
    riveFactory: Factory.flutter,
  );

  BooleanInput? _slowDanceInput;
  TriggerInput? _lookUpInput;

  @override
  void initState() {
    super.initState();
    dashAnimationNotifier.addListener(changeAnimation);
  }

  void changeAnimation() {
    _applyAnimation(dashAnimationNotifier.value);
  }

  void _applyAnimation(DashAnimationState animationState) {
    final slowDanceInput = _slowDanceInput;
    final lookUpInput = _lookUpInput;

    if (slowDanceInput == null) {
      return;
    }

    switch (animationState) {
      case DashAnimationState.idle:
        slowDanceInput.value = false;
      case DashAnimationState.slowDance:
        slowDanceInput.value = true;
      case DashAnimationState.lookUp:
        slowDanceInput.value = false;
        lookUpInput?.fire();
    }
  }

  void _onRiveLoaded(RiveLoaded state) {
    final stateMachine = state.controller.stateMachine;

    _slowDanceInput = stateMachine.boolean(DashAnimationState.slowDance.value);
    _lookUpInput = stateMachine.trigger(DashAnimationState.lookUp.value);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final animationState =
          dashAnimationNotifier.value == DashAnimationState.idle
          ? widget.initialAnimation
          : dashAnimationNotifier.value;
      dashAnimationNotifier.value = animationState;
      _applyAnimation(animationState);
    });
  }

  @override
  void dispose() {
    dashAnimationNotifier
      ..removeListener(changeAnimation)
      ..value = DashAnimationState.idle;
    _fileLoader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.16,
      width: MediaQuery.of(context).size.height * 0.16,
      child: RiveWidgetBuilder(
        fileLoader: _fileLoader,
        stateMachineSelector: StateMachineSelector.byName('birb'),
        onLoaded: _onRiveLoaded,
        builder: (context, state) => switch (state) {
          RiveLoaded() => RiveWidget(controller: state.controller),
          RiveLoading() || RiveFailed() => const SizedBox.shrink(),
        },
      ),
    );
  }
}
