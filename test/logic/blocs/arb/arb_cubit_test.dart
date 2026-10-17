import 'dart:convert';
import 'dart:io';

import 'package:arber/logic/blocs/arb/arb_cubit.dart';
import 'package:arber/view/widgets/animations/dash.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArbCubit generation', () {
    late Directory directory;
    late Directory output;
    late File excelFile;
    late ArbCubit cubit;

    setUp(() {
      directory = Directory.systemTemp.createTempSync('arber_generation_');
      output = Directory('${directory.path}/l10n')..createSync();
      final excel = Excel.createExcel();
      excel[excel.getDefaultSheet()!]
        ..appendRow([
          TextCellValue('key'),
          TextCellValue('description'),
          TextCellValue('en'),
          TextCellValue('ru'),
        ])
        ..appendRow([
          TextCellValue('items'),
          TextCellValue('Storage units count'),
          TextCellValue('{count, plural, one{item} other{{count} items}}'),
          TextCellValue('{count, plural, one{единица} other{{count} единиц}}'),
        ]);
      excelFile = File('${directory.path}/input.xlsx')
        ..writeAsBytesSync(excel.encode()!);
      cubit = ArbCubit();
      dashAnimationNotifier.value = DashAnimationState.idle;
    });

    tearDown(() async {
      await cubit.close();
      directory.deleteSync(recursive: true);
      dashAnimationNotifier.value = DashAnimationState.idle;
    });

    test('reads, serializes and writes outside the caller isolate', () async {
      final staleFile = File('${output.path}/intl_old.arb')
        ..writeAsStringSync('{}');
      final otherFile = File('${output.path}/notes.txt')
        ..writeAsStringSync('Keep this file');
      final states = cubit.stream.take(2).toList();

      // Child isolates have their own I/O zone. Any filesystem work left on
      // the caller (UI) isolate makes this fail without timing assumptions.
      final generation = IOOverrides.runZoned(
        () => cubit.generateARBs(excelFile.path, output.path),
        createFile: (_) => throw StateError('File I/O on the UI isolate'),
        createDirectory: (_) => throw StateError('Directory I/O on UI isolate'),
      );

      expect(cubit.state, isA<ArbGenerating>());
      expect(dashAnimationNotifier.value, DashAnimationState.slowDance);

      await generation;

      expect(await states, [isA<ArbGenerating>(), isA<ArbDone>()]);
      expect(dashAnimationNotifier.value, DashAnimationState.idle);
      expect(staleFile.existsSync(), isFalse);
      expect(otherFile.readAsStringSync(), 'Keep this file');
      for (final locale in ['en', 'ru']) {
        final file = File('${output.path}/intl_$locale.arb');
        final decoded = jsonDecode(file.readAsStringSync()) as Map;
        expect(decoded['@@locale'], locale);
        expect(decoded['@items']['placeholders'], {'count': {}});
      }
    });

    test('reports worker read errors and stops loading', () async {
      final states = cubit.stream.take(2).toList();

      await cubit.generateARBs('${directory.path}/missing.xlsx', output.path);

      expect(await states, [isA<ArbGenerating>(), isA<ArbFailed>()]);
      expect((cubit.state as ArbFailed).exception, isA<FileSystemException>());
      expect(dashAnimationNotifier.value, DashAnimationState.idle);
    });

    test('reports worker write errors and stops loading', () async {
      final states = cubit.stream.take(2).toList();

      await cubit.generateARBs(excelFile.path, '${directory.path}/missing');

      expect(await states, [isA<ArbGenerating>(), isA<ArbFailed>()]);
      expect((cubit.state as ArbFailed).exception, isA<FileSystemException>());
      expect(dashAnimationNotifier.value, DashAnimationState.idle);
    });

    test('ignores resets and duplicate starts while generating', () async {
      final states = <ArbState>[];
      final subscription = cubit.stream.listen(states.add);
      addTearDown(subscription.cancel);
      final generation = cubit.generateARBs(excelFile.path, output.path);

      cubit.reset();
      final duplicate = cubit.generateARBs(
        '${directory.path}/missing.xlsx',
        output.path,
      );
      expect(cubit.state, isA<ArbGenerating>());
      await Future.wait([generation, duplicate]);
      await Future<void>.delayed(Duration.zero);

      expect(states, [isA<ArbGenerating>(), isA<ArbDone>()]);
      expect(File('${output.path}/intl_en.arb').existsSync(), isTrue);
    });

    for (final fail in [false, true]) {
      test('ignores a worker completion after close (error=$fail)', () async {
        final generation = cubit.generateARBs(
          fail ? '${directory.path}/missing.xlsx' : excelFile.path,
          output.path,
        );
        await cubit.close();

        await expectLater(generation, completes);

        expect(cubit.isClosed, isTrue);
        expect(dashAnimationNotifier.value, DashAnimationState.idle);
      });
    }

    test('leaves animation running for another active operation', () async {
      final otherActivity = beginDashActivity();
      try {
        await cubit.generateARBs(excelFile.path, output.path);
        expect(cubit.state, isA<ArbDone>());
        expect(dashAnimationNotifier.value, DashAnimationState.slowDance);
      } finally {
        endDashActivity(otherActivity);
      }
      expect(dashAnimationNotifier.value, DashAnimationState.idle);
    });
  });
}
