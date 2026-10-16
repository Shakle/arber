import 'dart:convert';
import 'dart:io';

import 'package:arber/data/models/arb.dart';
import 'package:arber/services/arb_service.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArbService.getArbs placeholders', () {
    late Directory directory;

    setUp(() {
      directory = Directory.systemTemp.createTempSync('arber_test_');
    });

    tearDown(() {
      directory.deleteSync(recursive: true);
    });

    List<Arb> generateArbs(Map<String, String> messages) {
      final excel = Excel.createExcel();
      excel[excel.getDefaultSheet()!]
        ..appendRow([
          TextCellValue('Key'),
          TextCellValue('Description'),
          ...messages.keys.map(TextCellValue.new),
        ])
        ..appendRow([
          TextCellValue('strmStorageUnitsCount'),
          TextCellValue('Storage units count'),
          ...messages.values.map(TextCellValue.new),
        ]);

      final file = File('${directory.path}/translations.xlsx')
        ..writeAsBytesSync(excel.encode()!);
      return ArbService().getArbs(file.path);
    }

    test('writes one count key for each locale in the storage units row', () {
      const messages = {
        'en': '{count, plural, =1{1 SU} other{{count} SUs}}',
        'ru':
            '{count, plural, one{{count} складская единица} '
            'few{{count} складские единицы} many{{count} складских единиц} '
            'other{{count} складской единицы}}',
        'uk':
            '{count, plural, one{{count} складська одиниця} '
            'few{{count} складські одиниці} many{{count} складських одиниць} '
            'other{{count} складської одиниці}}',
        'ar':
            '{count, plural, =0{0 وحدات تخزين} =1{وحدة تخزين واحدة} '
            '=2{وحدتا تخزين} few{{count} وحدات تخزين} '
            'many{{count} وحدة تخزين} other{{count} وحدة تخزين}}',
      };

      final arbs = generateArbs(messages);

      expect(arbs.map((arb) => arb.locale), messages.keys);
      for (final arb in arbs) {
        expect(arb.translations.single.placeholders, ['count']);
        final json = arb.toJson();
        // Decoding JSON alone would silently discard duplicate keys.
        expect(RegExp(r'"count"\s*:').allMatches(json), hasLength(1));
        final decoded = jsonDecode(json) as Map<String, dynamic>;
        expect(decoded['strmStorageUnitsCount'], messages[arb.locale]);
        expect(decoded['@strmStorageUnitsCount'], {
          'description': 'Storage units count',
          'placeholders': {'count': <String, dynamic>{}},
        });
      }
    });

    test('deduplicates simple placeholders in first occurrence order', () {
      final arb = generateArbs({
        'en': '{name}: {count}; {name} has {count} SUs',
      }).single;

      expect(arb.translations.single.placeholders, ['name', 'count']);
      final json = arb.toJson();
      expect(RegExp(r'"name"\s*:').allMatches(json), hasLength(1));
      expect(RegExp(r'"count"\s*:').allMatches(json), hasLength(1));
    });

    test(
      'includes a plural selector without interpolations in its branches',
      () {
        final arb = generateArbs({
          'en': '{count, plural, =1{One SU} other{Several SUs}}',
        }).single;

        expect(arb.translations.single.placeholders, ['count']);
      },
    );

    test('includes a select selector and deduplicates nested placeholders', () {
      final arb = generateArbs({
        'en':
            '{gender, select, female{{name} has SUs} '
            'other{{name} has storage units}}',
      }).single;

      expect(arb.translations.single.placeholders, ['gender', 'name']);
    });

    test('includes a selectordinal selector', () {
      final arb = generateArbs({
        'en':
            '{position, selectordinal, one{First place} other{Another place}}',
      }).single;

      expect(arb.translations.single.placeholders, ['position']);
    });

    test('keeps different selectors and shared placeholders in nested ICU', () {
      final arb = generateArbs({
        'en':
            '{gender, select, other{{count, plural, '
            'one{{name} has one SU} other{{name} has {count} SUs}}}}',
      }).single;

      expect(arb.translations.single.placeholders, ['gender', 'count', 'name']);
    });

    test('omits placeholder metadata for a message without placeholders', () {
      final arb = generateArbs({'en': 'Storage units'}).single;

      expect(arb.translations.single.placeholders, isEmpty);
      final decoded = jsonDecode(arb.toJson()) as Map<String, dynamic>;
      expect(decoded['@strmStorageUnitsCount'], {
        'description': 'Storage units count',
      });
    });
  });
}
