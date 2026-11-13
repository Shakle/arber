import 'package:arber/view/widgets/animations/update_badge.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Widget app({bool disableAnimations = false}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: const Scaffold(body: Center(child: UpdateBadge())),
    ),
  );

  BoxShadow glow(WidgetTester tester) {
    final box = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(UpdateBadge),
        matching: find.byType(DecoratedBox),
      ),
    );
    return (box.decoration as BoxDecoration).boxShadow!.last;
  }

  testWidgets('pulses the glow while shown', (tester) async {
    await tester.pumpWidget(app());
    expect(find.text('Update available 🦾'), findsOneWidget);
    final start = glow(tester).blurRadius;

    await tester.pump(const Duration(milliseconds: 700));
    expect(glow(tester).blurRadius, greaterThan(start));
    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('stays still when animations are disabled', (tester) async {
    await tester.pumpWidget(app(disableAnimations: true));
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
    expect(glow(tester).blurRadius, greaterThan(6));
  });
}
