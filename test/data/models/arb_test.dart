import 'dart:convert';

import 'package:arber/data/models/arb.dart';
import 'package:arber/data/models/translation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Arb JSON serialization', () {
    test('round-trips quotes, backslashes, control characters and Unicode', () {
      const key = 'message"\\key';
      const text = 'Say "hello" at C:\\temp\\file\tПривет\r\nNext line';
      const description = 'Description "quoted"\\path\t\nEnd';
      const arb = Arb(
        locale: 'en',
        translations: [
          Translation(key: key, translation: text, description: description),
        ],
      );

      final decoded = jsonDecode(arb.toJson()) as Map<String, dynamic>;

      expect(decoded[key], text);
      expect(decoded['@$key']['description'], description);
    });

    test('escapes the locale and placeholder names', () {
      const arb = Arb(
        locale: 'en"\\test',
        translations: [
          Translation(
            key: 'hello',
            translation: 'Hello',
            placeholders: ['name"\\test'],
          ),
        ],
      );

      final decoded = jsonDecode(arb.toJson()) as Map<String, dynamic>;

      expect(decoded['@@locale'], arb.locale);
      expect(decoded['@hello']['placeholders'], {'name"\\test': {}});
    });

    test(
      'preserves duplicate message keys and both translations in output',
      () {
        const arb = Arb(
          locale: 'en',
          translations: [
            Translation(key: 'hello', translation: 'First "value"'),
            Translation(key: 'hello', translation: 'Second "value"'),
          ],
        );

        final json = arb.toJson();

        expect(RegExp(r'"hello"\s*:').allMatches(json), hasLength(2));
        expect(RegExp(r'"@hello"\s*:').allMatches(json), hasLength(2));
        expect(json, contains(jsonEncode('First "value"')));
        expect(json, contains(jsonEncode('Second "value"')));
      },
    );

    test('serializes an empty ARB with the default constant list', () {
      expect(jsonDecode(const Arb(locale: 'en').toJson()), {'@@locale': 'en'});
    });

    test('omits empty translations without mutating the source list', () {
      const translations = [
        Translation(key: 'empty', translation: ''),
        Translation(key: 'hello', translation: 'Hello'),
      ];
      const arb = Arb(locale: 'en', translations: translations);

      final decoded = jsonDecode(arb.toJson()) as Map<String, dynamic>;

      expect(decoded, isNot(contains('empty')));
      expect(decoded['hello'], 'Hello');
      expect(arb.translations, hasLength(2));
    });
  });
}
