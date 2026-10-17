import 'package:arber/theme/colors.dart';
import 'package:material_ui/material_ui.dart';

class BackgroundField extends StatelessWidget {
  const BackgroundField({
    super.key,
    required this.borderRadius,
    required this.child,
    this.padding = const EdgeInsets.all(40),
    this.clipBehavior = Clip.none,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    return field();
  }

  Widget field() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: const [lightShadow],
        borderRadius: borderRadius,
      ),
      child: Material(
        borderRadius: borderRadius,
        clipBehavior: clipBehavior,
        color: Colors.white,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
