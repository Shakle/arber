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
  Future<void> showReport(WidgetTester tester, ArbData data) async {
    final paths = FakePathCubit()..connect();
    final arb = ArbCubit();
    final cubit = TranslationCubit(
      pathCubit: paths,
      arbCubit: arb,
      checkDifference: (_, _) async => data,
    );
    addTearDown(() async {
      await cubit.close();
      await arb.close();
      await paths.close();
    });
    await cubit.checkArbExcelDifference();
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
      ArbData(missingKeys: keys, missingTranslations: translations),
    );

    expect(find.text('missing-key-0'), findsOneWidget);
    expect(find.text('missing-key-9999'), findsNothing);
    expect(keys.reads, lessThan(100));
    expect(translations.reads, 0);
    final initialReads = keys.reads;

    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();

    expect(keys.reads, greaterThan(initialReads));
    expect(keys.reads, lessThan(500));
    expect(translations.reads, 0);
    expect(tester.takeException(), isNull);
  });

  for (final keysPresent in [false, true]) {
    for (final translationsPresent in [false, true]) {
      testWidgets(
        'shows correct report sections (keys=$keysPresent, translations=$translationsPresent)',
        (tester) async {
          await showReport(
            tester,
            ArbData(
              missingKeys: keysPresent ? ['missing-key'] : [],
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

          expect(
            find.text('Missing keys in Excel:'),
            keysPresent ? findsOneWidget : findsNothing,
          );
          expect(
            find.text('missing-key'),
            keysPresent ? findsOneWidget : findsNothing,
          );
          expect(
            find.text('Missing translations in Excel:'),
            translationsPresent ? findsOneWidget : findsNothing,
          );
          expect(
            find.text('missing-translation - en, ru.', findRichText: true),
            translationsPresent ? findsOneWidget : findsNothing,
          );
          expect(
            find.text('Everything is translated, all fine'),
            !keysPresent && !translationsPresent
                ? findsOneWidget
                : findsNothing,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
