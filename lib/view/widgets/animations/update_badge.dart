import 'package:arber/theme/colors.dart';
import 'package:material_ui/material_ui.dart';

/// "Update available" pill that softly glows and nudges toward Settings.
class UpdateBadge extends StatefulWidget {
  const UpdateBadge({super.key});

  @override
  State<UpdateBadge> createState() => _UpdateBadgeState();
}

class _UpdateBadgeState extends State<UpdateBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  late final Animation<double> _pulse = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 0.5;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = _pulse.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: Offset(-4 * t, 0),
              child: const Icon(Icons.arrow_left, color: smoothBlue),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: smoothBlue.withValues(alpha: 0.2 + 0.5 * t),
                  width: 1.5,
                ),
                boxShadow: [
                  lightShadow,
                  BoxShadow(
                    color: smoothBlue.withValues(alpha: 0.15 + 0.45 * t),
                    blurRadius: 6 + 20 * t,
                    spreadRadius: 1 + 3 * t,
                  ),
                ],
              ),
              child: child,
            ),
          ],
        );
      },
      child: const Padding(
        padding: EdgeInsets.all(9),
        child: Text('Update available 🦾'),
      ),
    );
  }
}
