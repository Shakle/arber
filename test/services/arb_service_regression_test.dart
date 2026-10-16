import 'dart:convert';
import 'dart:io';

import 'package:arber/services/arb_service.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('arber_regression_');
  });

  tearDown(() {
    directory.deleteSync(recursive: true);
  });

  String workbook(List<List<String?>> rows) {
    final excel = Excel.createExcel();
    final sheet = excel[excel.getDefaultSheet()!];
    for (final row in rows) {
      sheet.appendRow([
        for (final value in row) value == null ? null : TextCellValue(value),
      ]);
    }
    return (File(
      '${directory.path}/input.xlsx',
    )..writeAsBytesSync(excel.encode()!)).path;
  }

  group('Excel to ARB', () {
    test(
      'round-trips cell content without pre-escaping newlines or slashes',
      () {
        const text = 'Say "hello"\nC:\\temp\\file\tNext\r\nEnd';
        const description = 'Description "quoted"\nPath: C:\\temp';
        final path = workbook([
          ['key', 'description', 'en'],
          ['hello', description, text],
          ['literalNewline', '', r'Use \n to insert a newline'],
        ]);

        final arb = ArbService().getArbs(path).single;
        final decoded = jsonDecode(arb.toJson()) as Map<String, dynamic>;

        expect(arb.translations.first.translation, text);
        expect(decoded['hello'], text);
        expect(decoded['@hello']['description'], description);
        expect(decoded['literalNewline'], r'Use \n to insert a newline');
      },
    );

    test('preserves duplicate Excel keys in the generated ARB', () {
      final path = workbook([
        ['key', 'description', 'en'],
        ['hello', '', 'First'],
        ['hello', '', 'Second'],
      ]);

      final json = ArbService().getArbs(path).single.toJson();

      expect(RegExp(r'"hello"\s*:').allMatches(json), hasLength(2));
      expect(json, contains('First'));
      expect(json, contains('Second'));
    });

    test('keeps column mapping across empty and whitespace locale headers', () {
      final path = workbook([
        ['key', 'description', ' en ', null, 'ru', '   ', 'uk'],
        ['hello', '', 'Hello', 'Ignore', 'Привет', 'Ignore too', 'Привіт'],
      ]);

      final arbs = ArbService().getArbs(path);

      expect(arbs.map((arb) => arb.locale), ['en', 'ru', 'uk']);
      expect(arbs.map((arb) => arb.translations.single.translation), [
        'Hello',
        'Привет',
        'Привіт',
      ]);
    });

    test('reports missing translations only for named locale columns', () {
      final path = workbook([
        ['key', 'description', ' en ', null, ' ru ', '   ', 'uk'],
        ['hello', '', 'Hello', null, null, null, 'Привіт'],
      ]);

      final result = ArbService().getArbExcelDifference([path, '']);

      expect(result.missingTranslations.single.key, 'hello');
      expect(result.missingTranslations.single.missingTranslations, ['ru']);
    });
  });

  group('ARB comparison', () {
    for (final indent in <String?>[null, '  ']) {
      test('reads top-level keys with JSON indentation $indent', () {
        final path = workbook([
          ['key', 'description', 'en'],
          ['present', '', 'Present'],
        ]);
        final source = File('${directory.path}/source.arb')
          ..writeAsStringSync(
            JsonEncoder.withIndent(indent).convert({
              '@@locale': 'en',
              '@@last_modified': '2026-10-17',
              'present': 'Present',
              'removedPlural':
                  '{count, plural, one{One item} other{{count} items}}',
              '@removedPlural': {
                'description': 'Count',
                'placeholders': {
                  'count': {'type': 'int'},
                },
              },
              'removedSimple': 'Text with "quotes" and {name}',
              'description': 'A real message key',
              'key': 'Same name as the Excel header',
            }),
          );

        final result = ArbService().getArbExcelDifference([path, source.path]);

        expect(result.missingKeys, [
          'removedPlural',
          'removedSimple',
          'description',
          'key',
        ]);
      });
    }

    test('rejects a JSON root that is not an object', () {
      final path = workbook([
        ['key', 'description', 'en'],
      ]);
      final source = File('${directory.path}/source.arb')
        ..writeAsStringSync('[]');

      expect(
        () => ArbService().getArbExcelDifference([path, source.path]),
        throwsFormatException,
      );
    });
  });

  group('ICU placeholders', () {
    const cases = <String, List<String>>{
      '{count, plural, one{item} other{items}}': ['count'],
      '{count, plural, =0{0} =1{1} other{{count} items}}': ['count'],
      '{gender, select, female{she} male{he} other{they}}': ['gender'],
      '{count, plural, offset:1 =0{none} =1{{name}} '
          'other{{name} and {count} others}}': [
        'count',
        'name',
      ],
      '{gender, select, other{{count, plural, one{item} '
          'other{{name}: {count} items}}}}': [
        'gender',
        'count',
        'name',
      ],
      '{ count , plural , one{item} other{{ name } has { count } items}}': [
        'count',
        'name',
      ],
      "'{literal}' {name}": ['name'],
      "'{literal with ''{hidden}''}' {actual}": ['actual'],
      "''{name}'' {count, plural, one{item} other{items}}": ['name', 'count'],
      "It's {name}'s order": ['name'],
      "{count, plural, other{'# {literal}' {actual}}}": ['count', 'actual'],
      "'# {name}": ['name'],
      "{day, date, yyyy '{ignored}'} {total, number}": ['day', 'total'],
      '{position, selectordinal, one{first} other{{position}th}}': ['position'],
      '{count, plural, other{{name}': ['count', 'name'],
    };

    for (final entry in cases.entries) {
      test(entry.key, () {
        final path = workbook([
          ['key', 'description', 'en'],
          ['message', '', entry.key],
        ]);

        final arb = ArbService().getArbs(path).single;

        expect(arb.translations.single.placeholders, entry.value);
        expect(
          (jsonDecode(arb.toJson()) as Map<String, dynamic>)['message'],
          entry.key,
        );
      });
    }
  });
}
