import 'package:arber/logic/blocs/arb/arb_cubit.dart';
import 'package:arber/logic/blocs/path/path_cubit.dart';
import 'package:arber/theme/theme.dart';
import 'package:arber/view/widgets/inputs/path_input.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_path_cubit.dart';

void main() {
  const longPath =
      '/Users/example/Development/projects/warehouse/translations/'
      'release/october/a_very_long_translation_filename.xlsx';
  late FakePathCubit paths;
  late ArbCubit arb;
  late TextEditingController controller;

  setUp(() {
    paths = FakePathCubit()..connect();
    arb = ArbCubit();
    controller = TextEditingController(text: longPath);
  });

  tearDown(() async {
    controller.dispose();
    await arb.close();
    await paths.close();
  });

  Future<void> showInput(
    WidgetTester tester,
    PathInput input, {
    double width = 450,
  }) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<PathCubit>.value(value: paths),
          BlocProvider<ArbCubit>.value(value: arb),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(width: width, child: input),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  ScrollController scrollController(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).scrollController!;

  for (final label in ['Excel', 'Output', 'ARB']) {
    testWidgets('$label label stays visible with a complete path', (
      tester,
    ) async {
      final input = switch (label) {
        'Excel' => PathInput.excelPath(controller: controller),
        'Output' => PathInput.l10nPath(controller: controller),
        _ => PathInput.mainArbPath(controller: controller),
      };
      await showInput(tester, input);

      expect(find.text(label), findsOneWidget);
      expect(find.byTooltip(longPath), findsOneWidget);
      expect(controller.text, longPath);
      final scroll = scrollController(tester);
      expect(scroll.position.maxScrollExtent, greaterThan(0));
      expect(scroll.offset, closeTo(scroll.position.maxScrollExtent, 0.1));
      final tail = tester.widget<Text>(find.byKey(const ValueKey('path-tail')));
      expect(tail.data, startsWith('… '));
      expect(longPath.endsWith(tail.data!.substring(2)), isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('programmatic changes reveal the new filename', (tester) async {
    await showInput(tester, PathInput.excelPath(controller: controller));

    const newPath = '$longPath/more/folders/new_translation_file.xlsx';
    controller.text = newPath;
    await tester.pumpAndSettle();

    final scroll = scrollController(tester);
    expect(scroll.offset, closeTo(scroll.position.maxScrollExtent, 0.1));
    expect(find.byTooltip(newPath), findsOneWidget);
    expect(controller.text, newPath);
  });

  testWidgets('allows editing the beginning and restores the tail on blur', (
    tester,
  ) async {
    await showInput(tester, PathInput.excelPath(controller: controller));
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '/edited$longPath');
    for (var index = 0; index < controller.text.length; index++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    }
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
      isTrue,
    );
    expect(controller.selection.baseOffset, 0);
    expect(scrollController(tester).offset, closeTo(0, 1));
    expect(controller.text, '/edited$longPath');

    FocusManager.instance.primaryFocus!.unfocus();
    await tester.pumpAndSettle();

    final scroll = scrollController(tester);
    expect(scroll.offset, closeTo(scroll.position.maxScrollExtent, 0.1));
    expect(controller.text, '/edited$longPath');
  });

  testWidgets(
    'keeps the cursor active after selecting and deleting the whole path',
    (tester) async {
      await showInput(tester, PathInput.excelPath(controller: controller));
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      final editor = tester.state<EditableTextState>(find.byType(EditableText));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      expect(
        controller.selection,
        const TextSelection(baseOffset: 0, extentOffset: longPath.length),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();

      expect(controller.text, isEmpty);
      expect(editor.widget.focusNode.hasFocus, isTrue);
      expect(
        tester.state<EditableTextState>(find.byType(EditableText)),
        same(editor),
      );
      expect(editor.cursorCurrentlyVisible, isTrue);

      final cursorVisibility = <bool>{};
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
        cursorVisibility.add(editor.cursorCurrentlyVisible);
      }
      expect(cursorVisibility, containsAll([true, false]));

      await tester.enterText(find.byType(TextField), '/new/path.xlsx');
      await tester.pump();
      expect(
        tester.state<EditableTextState>(find.byType(EditableText)),
        same(editor),
      );
      expect(editor.cursorCurrentlyVisible, isTrue);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets('short and empty paths retain the label without an ellipsis', (
    tester,
  ) async {
    controller.text = 'intl_ru.arb';
    await showInput(tester, PathInput.mainArbPath(controller: controller));
    expect(
      tester.widget<TextField>(find.byType(TextField)).decoration!.prefixText,
      isNull,
    );
    expect(find.text('ARB'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('path-tail'))).data,
      'intl_ru.arb',
    );

    controller.clear();
    await tester.pumpAndSettle();
    expect(find.text('ARB'), findsOneWidget);
    expect(find.text('Optional .arb reference'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the filename visible after resizing the field', (
    tester,
  ) async {
    await showInput(tester, PathInput.excelPath(controller: controller));
    await showInput(
      tester,
      PathInput.excelPath(controller: controller),
      width: 320,
    );

    final scroll = scrollController(tester);
    expect(scroll.offset, closeTo(scroll.position.maxScrollExtent, 0.1));
    expect(controller.text, longPath);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fits the tail using complete graphemes at different widths', (
    tester,
  ) async {
    controller.text =
        '/Users/${List.filled(30, 'e\u0301👨‍👩‍👧‍👦').join()}.arb';
    final characters = controller.text.characters;
    final suffixes = {
      for (var index = 0; index <= characters.length; index++)
        characters.skip(index).join(),
    };
    for (final width in [240.0, 287.0, 320.0, 450.0]) {
      await showInput(
        tester,
        PathInput.mainArbPath(controller: controller),
        width: width,
      );
      final finder = find.byKey(const ValueKey('path-tail'));
      final tail = tester.widget<Text>(finder);
      expect(tail.data, startsWith('… '));
      expect(suffixes, contains(tail.data!.substring(2)));
      final painter = TextPainter(
        text: TextSpan(text: tail.data, style: tail.style),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      expect(
        painter.width,
        lessThanOrEqualTo(tester.getSize(finder).width + 0.01),
      );
      painter.dispose();
      expect(tester.takeException(), isNull);
    }
  });
}
