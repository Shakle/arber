import 'dart:async';
import 'dart:io';

import 'package:arber/data/models/arb_data.dart';
import 'package:arber/logic/blocs/arb/arb_cubit.dart';
import 'package:arber/logic/blocs/path/path_cubit.dart';
import 'package:arber/logic/blocs/translation/translation_cubit.dart';
import 'package:arber/view/widgets/animations/dash.dart';
import 'package:excel_community/excel_community.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_path_cubit.dart';

class _ArbCubit extends ArbCubit {
  void setTestState(ArbState state) => emit(state);
}

ArbData _result(String key) =>
    ArbData(missingKeys: [key], missingTranslations: []);

void main() {
  group('TranslationCubit', () {
    late FakePathCubit paths;
    late _ArbCubit arb;
    late TranslationCubit cubit;
    late Future<ArbData> Function(String, String) checker;

    setUp(() {
      paths = FakePathCubit();
      arb = _ArbCubit();
      checker = (_, _) async => _result('missing');
      cubit = TranslationCubit(
        pathCubit: paths,
        arbCubit: arb,
        checkDifference: (excel, source) => checker(excel, source),
      );
    });

    tearDown(() async {
      await cubit.close();
      await arb.close();
      await paths.close();
    });

    test('keeps active generation when a comparison completes', () async {
      arb.setTestState(ArbGenerating());

      await cubit.checkArbExcelDifference();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, isA<TranslationDone>());
      expect(arb.state, isA<ArbGenerating>());
    });

    test('clears completed generation status when checking again', () async {
      arb.setTestState(ArbDone());

      await cubit.checkArbExcelDifference();
      await Future<void>.delayed(Duration.zero);

      expect(arb.state, isA<ArbInitial>());
    });

    for (final field in ['excel', 'arb', 'output']) {
      test('discards an in-flight result after changing $field', () async {
        final completion = Completer<ArbData>();
        checker = (_, _) => completion.future;
        final operation = cubit.checkArbExcelDifference();

        switch (field) {
          case 'excel':
            paths.excelFilePathController.text = 'new.xlsx';
          case 'arb':
            paths.arbFilePathController.text = 'new.arb';
          case 'output':
            paths.l10nDirPathController.text = 'new-l10n';
        }
        expect(cubit.state, isA<TranslationInitial>());

        completion.complete(_result('old'));
        await operation;

        expect(cubit.state, isA<TranslationInitial>());
        expect(dashAnimationNotifier.value, DashAnimationState.idle);
      });
    }

    test(
      'changing a path back still invalidates the original request',
      () async {
        final completion = Completer<ArbData>();
        checker = (_, _) => completion.future;
        final operation = cubit.checkArbExcelDifference();

        paths.excelFilePathController.text = 'other.xlsx';
        paths.excelFilePathController.text = 'initial.xlsx';
        completion.complete(_result('old'));
        await operation;

        expect(cubit.state, isA<TranslationInitial>());
      },
    );

    test('cursor movement does not invalidate the current request', () async {
      final completion = Completer<ArbData>();
      checker = (_, _) => completion.future;
      final operation = cubit.checkArbExcelDifference();

      paths.excelFilePathController.selection = const TextSelection.collapsed(
        offset: 0,
      );
      expect(cubit.state, isA<TranslationGenerating>());
      completion.complete(_result('current'));
      await operation;

      expect((cubit.state as TranslationDone).arbData.missingKeys, ['current']);
    });

    for (final failOld in [false, true]) {
      test(
        'keeps the newest result when old request finishes (error=$failOld)',
        () async {
          final old = Completer<ArbData>();
          final current = Completer<ArbData>();
          checker = (_, _) => old.future;
          final oldOperation = cubit.checkArbExcelDifference();
          checker = (_, _) => current.future;
          final currentOperation = cubit.checkArbExcelDifference();

          current.complete(_result('new'));
          await currentOperation;
          if (failOld) {
            old.completeError(StateError('Old error'));
          } else {
            old.complete(_result('old'));
          }
          await oldOperation;

          expect((cubit.state as TranslationDone).arbData.missingKeys, ['new']);
        },
      );
    }

    test('old completion does not stop a newer loading indicator', () async {
      final old = Completer<ArbData>();
      final current = Completer<ArbData>();
      checker = (_, _) => old.future;
      final oldOperation = cubit.checkArbExcelDifference();
      checker = (_, _) => current.future;
      final currentOperation = cubit.checkArbExcelDifference();

      old.complete(_result('old'));
      await oldOperation;
      expect(cubit.state, isA<TranslationGenerating>());
      expect(dashAnimationNotifier.value, DashAnimationState.slowDance);

      current.complete(_result('current'));
      await currentOperation;
      expect(dashAnimationNotifier.value, DashAnimationState.idle);
    });

    for (final fail in [false, true]) {
      test('ignores completion after close (error=$fail)', () async {
        final completion = Completer<ArbData>();
        checker = (_, _) => completion.future;
        final operation = cubit.checkArbExcelDifference();

        await cubit.close();
        if (fail) {
          completion.completeError(StateError('Late error'));
        } else {
          completion.complete(_result('late'));
        }
        await expectLater(operation, completes);

        expect(cubit.isClosed, isTrue);
        expect(dashAnimationNotifier.value, DashAnimationState.idle);
      });
    }

    test('invalid path state cannot later reset a newer result', () async {
      paths.updateState(
        PathConnectionFailed(
          failedArtifacts: const [],
          successArtifacts: const [],
        ),
      );
      await Future<void>.delayed(Duration.zero);
      paths.connect();
      await cubit.checkArbExcelDifference();
      await Future<void>.delayed(const Duration(milliseconds: 350));

      expect(cubit.state, isA<TranslationDone>());
    });

    test('closing removes pending path callbacks', () async {
      paths.updateState(
        PathConnectionFailed(
          failedArtifacts: const [],
          successArtifacts: const [],
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await cubit.close();
      paths.excelFilePathController.text = 'after-close.xlsx';
      await Future<void>.delayed(const Duration(milliseconds: 350));

      expect(cubit.isClosed, isTrue);
    });

    test('leaves animation running for another active operation', () async {
      final otherActivity = beginDashActivity();
      try {
        await cubit.checkArbExcelDifference();
        expect(dashAnimationNotifier.value, DashAnimationState.slowDance);
      } finally {
        endDashActivity(otherActivity);
      }
      expect(dashAnimationNotifier.value, DashAnimationState.idle);
    });

    test('default comparison reads files in a worker isolate', () async {
      final directory = Directory.systemTemp.createTempSync('arber_check_');
      addTearDown(() => directory.deleteSync(recursive: true));
      final excel = Excel.createExcel();
      excel[excel.getDefaultSheet()!]
        ..appendRow([
          TextCellValue('key'),
          TextCellValue('description'),
          TextCellValue('en'),
        ])
        ..appendRow([
          TextCellValue('present'),
          TextCellValue(''),
          TextCellValue('Present'),
        ]);
      final file = File('${directory.path}/input.xlsx')
        ..writeAsBytesSync(excel.encode()!);
      final source = File('${directory.path}/input.arb')
        ..writeAsStringSync('{"removed": "Missing"}');
      await cubit.close();
      paths.excelFilePathController.text = file.path;
      paths.arbFilePathController.text = source.path;
      cubit = TranslationCubit(pathCubit: paths, arbCubit: arb);

      await IOOverrides.runZoned(
        cubit.checkArbExcelDifference,
        createFile: (_) => throw StateError('File I/O on UI isolate'),
        createDirectory: (_) => throw StateError('Directory I/O on UI isolate'),
      );

      expect((cubit.state as TranslationDone).arbData.missingKeys, ['removed']);
    });
  });
}
