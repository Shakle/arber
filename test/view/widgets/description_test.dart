import 'package:arber/data/constants.dart';
import 'package:arber/theme/theme.dart';
import 'package:arber/view/widgets/description.dart';
import 'package:flutter_test/flutter_test.dart' hide Description;
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  setUpAll(() {
    packageInfo = PackageInfo(
      appName: 'Arber',
      packageName: 'arber',
      version: '1.3.0',
      buildNumber: '1',
    );
  });

  for (final size in [const Size(1050, 750), const Size(480, 350)]) {
    testWidgets('shows the guide within a $size window', (tester) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Align(alignment: Alignment.bottomRight, child: Description()),
          ),
        ),
      );
      tester.state<TooltipState>(find.byType(Tooltip)).ensureTooltipVisible();
      await tester.pumpAndSettle();

      expect(find.text('How to use Arber'), findsOneWidget);
      expect(find.text('Prepare the spreadsheet'), findsOneWidget);
      expect(find.text('Create translations'), findsOneWidget);
      expect(find.text('Arber 1.3.0'), findsOneWidget);
      final guide = tester.getRect(find.byType(SingleChildScrollView));
      expect(guide.left, greaterThanOrEqualTo(0));
      expect(guide.top, greaterThanOrEqualTo(0));
      expect(guide.right, lessThanOrEqualTo(size.width));
      expect(guide.bottom, lessThanOrEqualTo(size.height));
      expect(tester.takeException(), isNull);

      if (size.height < 400) {
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -500),
        );
        await tester.pumpAndSettle();
        expect(find.text('Arber 1.3.0').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  }
}
