import 'dart:async';
import 'dart:collection';

import 'package:arber/data/models/arb_data.dart';
import 'package:arber/data/models/missing_translation.dart';
import 'package:arber/logic/blocs/arb/arb_cubit.dart';
import 'package:arber/logic/blocs/path/path_cubit.dart';
import 'package:arber/logic/blocs/translation/translation_cubit.dart';
import 'package:arber/view/widgets/missing_translation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_path_cubit.dart';

class _CountingList<T> extends ListBase<T> {
  _CountingList(this.values);

  final List<T> values;
  int reads = 0;

  @override
  int get length => values.length;
  @override
  set length(int value) => throw UnsupportedError('Read-only test data');
  @override
  T operator [](int index) {
    reads++;
    return values[index];
  }

  @override
  void operator []=(int index, T value) =>
      throw UnsupportedError('Read-only test data');
}

void main() {
  Future<void> showReport(
    WidgetTester tester,
    ArbData data, {
    bool runCheck = true,
    Future<ArbData> Function(String, String)? checkDifference,
  }) async {
    final paths = FakePathCubit()..connect();
    final arb = ArbCubit();
    final cubit = TranslationCubit(
      pathCubit: paths,
      arbCubit: arb,
      checkDifference: checkDifference ?? (_, _) async => data,
    );
    addTearDown(() async {
      await cubit.close();
      await arb.close();
      await paths.close();
    });
    if (runCheck) await cubit.checkArbExcelDifference();
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<PathCubit>.value(value: paths),
          BlocProvider<TranslationCubit>.value(value: cubit),
        ],
        child: const MaterialApp(
          home: Scaffold(body: Center(child: MissingTranslationWindow())),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('starts the check from the header with an empty report', (
    tester,
  ) async {
    await showReport(
      tester,
      ArbData(
        missingKeys: [],
        missingTranslations: [
          MissingTranslation(key: 'missing-key', missingTranslations: ['en']),
        ],
      ),
      runCheck: false,
    );

    expect(find.text('Translation check'), findsOneWidget);
    expect(find.text('Not checked yet'), findsOneWidget);
    expect(find.text('Refresh to find missing translations'), findsOneWidget);
    await tester.tap(find.byTooltip('Check missing translations'));
    await tester.pumpAndSettle();

    expect(find.text('Not checked yet'), findsNothing);
    expect(find.text('missing-key'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows checking status only in the header', (tester) async {
    final pending = Completer<ArbData>();
    final data = ArbData(missingKeys: [], missingTranslations: []);
    await showReport(
      tester,
      data,
      runCheck: false,
      checkDifference: (_, _) => pending.future,
    );
    await tester.tap(find.byTooltip('Check missing translations'));
    await tester.pump();

    expect(find.text('Checking translations…'), findsOneWidget);
    expect(find.text('Checking translations..'), findsNothing);
    expect(find.text('Not checked yet'), findsNothing);

    pending.complete(data);
    await tester.pumpAndSettle();
    expect(find.text('Checking translations…'), findsNothing);
    expect(find.text('Everything is translated, all fine'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final field in ['Excel', 'Output']) {
    testWidgets(
      'keeps the report until fade-out finishes when clearing $field',
      (tester) async {
        await showReport(
          tester,
          ArbData(
            missingKeys: [],
            missingTranslations: [
              MissingTranslation(
                key: 'missing-key',
                missingTranslations: ['en'],
              ),
            ],
          ),
        );
        final context = tester.element(find.byType(MissingTranslationWindow));
        final paths = context.read<PathCubit>() as FakePathCubit;
        final translations = context.read<TranslationCubit>();
        final controller =
            (field == 'Excel'
                  ? paths.excelFilePathController
                  : paths.l10nDirPathController)
              ..clear();

        await tester.pump();
        expect(translations.state, isA<TranslationInitial>());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        // Path validation can finish after the text listener invalidates the report.
        paths.updateState(
          PathConnectionFailed(
            failedArtifacts: const [],
            successArtifacts: const [],
          ),
        );
        await tester.pump();

        expect(find.text('missing-key'), findsOneWidget);
        expect(find.text('Not checked yet'), findsNothing);
        final fade = tester.widget<FadeTransition>(
          find
              .descendant(
                of: find.byType(AnimatedOpacity),
                matching: find.byType(FadeTransition),
              )
              .first,
        );
        expect(fade.opacity.value, greaterThan(0));
        expect(fade.opacity.value, lessThan(1));

        await tester.pumpAndSettle();
        expect(find.text('missing-key'), findsNothing);
        expect(find.text('Not checked yet'), findsOneWidget);
        expect(
          tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
          0,
        );

        controller.text = field == 'Excel' ? 'another.xlsx' : 'another-l10n';
        paths.connect();
        await tester.pumpAndSettle();
        expect(find.text('Not checked yet'), findsOneWidget);
        expect(
          tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
          1,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('builds only nearby report rows and loads more while scrolling', (
    tester,
  ) async {
    final keys = _CountingList(
      List.generate(10000, (index) => 'missing-key-$index'),
    );
    final translations = _CountingList(
      List.generate(
        10000,
        (index) => MissingTranslation(
          key: 'translation-$index',
          missingTranslations: ['en'],
        ),
      ),
    );

    await showReport(
      tester,
      ArbData(
        missingKeys: keys,
        missingTranslations: translations,
        arbCompared: true,
      ),
    );

    expect(find.text('translation-0'), findsOneWidget);
    expect(find.text('missing-key-9999'), findsNothing);
    expect(keys.reads, 0);
    expect(translations.reads, lessThan(100));
    final initialReads = translations.reads;

    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();

    expect(translations.reads, greaterThan(initialReads));
    expect(translations.reads, lessThan(500));
    expect(keys.reads, 0);

    await tester.tap(find.byTooltip('Show ARB comparison'));
    await tester.pumpAndSettle();
    expect(find.text('missing-key-0'), findsOneWidget);
    expect(keys.reads, lessThan(100));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'keeps the report heading and refresh button fixed while scrolling',
    (tester) async {
      await showReport(
        tester,
        ArbData(
          missingKeys: [],
          missingTranslations: List.generate(
            100,
            (index) => MissingTranslation(
              key: 'translation-$index',
              missingTranslations: ['en'],
            ),
          ),
        ),
      );

      final heading = find.text('Missing translations in Excel');
      final refresh = find.byTooltip('Check missing translations');
      final headingPosition = tester.getTopLeft(heading);
      final refreshPosition = tester.getTopLeft(refresh);

      await tester.drag(find.byType(ListView), const Offset(0, -800));
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(heading), headingPosition);
      expect(tester.getTopLeft(refresh), refreshPosition);
      expect(find.text('translation-0'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('asks for a reference file when switching without Main ARB', (
    tester,
  ) async {
    await showReport(tester, ArbData(missingKeys: [], missingTranslations: []));
    final context = tester.element(find.byType(MissingTranslationWindow));
    context.read<PathCubit>().arbFilePathController.clear();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Show ARB comparison'));
    await tester.pumpAndSettle();

    expect(find.text('No reference ARB selected'), findsOneWidget);
    expect(find.text('Keys match'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final missingFromExcel in [false, true]) {
    testWidgets(
      'shows keys missing only from ${missingFromExcel ? 'Excel' : 'ARB'}',
      (tester) async {
        await showReport(
          tester,
          ArbData(
            missingKeys: missingFromExcel ? ['only-in-arb'] : [],
            missingArbKeys: missingFromExcel ? [] : ['only-in-excel'],
            missingTranslations: [],
            arbCompared: true,
          ),
        );
        await tester.tap(find.byTooltip('Show ARB comparison'));
        await tester.pumpAndSettle();

        expect(
          find.text(
            missingFromExcel ? 'Missing keys in Excel' : 'Missing keys in ARB',
          ),
          findsOneWidget,
        );
        expect(
          find.text(missingFromExcel ? 'only-in-arb' : 'only-in-excel'),
          findsOneWidget,
        );
        expect(find.text('Keys match'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final keysPresent in [false, true]) {
    for (final translationsPresent in [false, true]) {
      testWidgets(
        'shows correct report sections (keys=$keysPresent, translations=$translationsPresent)',
        (tester) async {
          await showReport(
            tester,
            ArbData(
              missingKeys: keysPresent ? ['missing-key'] : [],
              missingArbKeys: keysPresent ? ['missing-in-arb'] : [],
              arbCompared: true,
              missingTranslations: translationsPresent
                  ? [
                      MissingTranslation(
                        key: 'missing-translation',
                        missingTranslations: ['en', 'ru'],
                      ),
                    ]
                  : [],
            ),
          );

          expect(find.text('Missing keys in Excel'), findsNothing);
          expect(find.text('missing-key'), findsNothing);
          expect(
            find.text('Missing translations in Excel'),
            translationsPresent ? findsOneWidget : findsNothing,
          );
          expect(
            find.text('missing-translation'),
            translationsPresent ? findsOneWidget : findsNothing,
          );
          expect(
            find.text('Everything is translated, all fine'),
            !translationsPresent ? findsOneWidget : findsNothing,
          );

          await tester.tap(find.byTooltip('Show ARB comparison'));
          await tester.pump(const Duration(milliseconds: 80));
          expect(
            find.descendant(
              of: find.byType(AnimatedSwitcher),
              matching: find.byType(SlideTransition),
            ),
            findsNWidgets(2),
          );
          expect(tester.takeException(), isNull);
          await tester.pumpAndSettle();
          expect(
            find.text('Missing keys in Excel'),
            keysPresent ? findsOneWidget : findsNothing,
          );
          expect(
            find.text('Missing keys in ARB'),
            keysPresent ? findsNWidgets(2) : findsOneWidget,
          );
          expect(
            find.text('missing-key'),
            keysPresent ? findsOneWidget : findsNothing,
          );
          expect(
            find.text('missing-in-arb'),
            keysPresent ? findsOneWidget : findsNothing,
          );
          expect(
            find.text('Keys match'),
            keysPresent ? findsNothing : findsOneWidget,
          );
          expect(find.text('missing-translation'), findsNothing);
          await tester.tap(find.byTooltip('Show missing translations'));
          await tester.pumpAndSettle();
          expect(
            find.text('missing-translation'),
            translationsPresent ? findsOneWidget : findsNothing,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
