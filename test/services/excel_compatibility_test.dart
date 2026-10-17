import 'dart:convert';
import 'dart:io';

import 'package:arber/services/arb_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const workbook = 'test/fixtures/legacy_translations.xlsx';

  test('generates identical ARB from an XLSX created by the old library', () {
    final expected = jsonDecode(
      File('test/fixtures/legacy_translations.expected.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;

    final arbs = ArbService().getArbs(workbook);

    expect({for (final arb in arbs) arb.locale: arb.toJson()}, expected);
  });

  test('finds missing translations in a legacy XLSX with a blank column', () {
    final result = ArbService().getArbExcelDifference([workbook, '']);

    expect(result.missingKeys, isEmpty);
    expect(result.missingTranslations, hasLength(1));
    expect(result.missingTranslations.single.key, 'missing');
    expect(result.missingTranslations.single.missingTranslations, ['ru']);
  });
}
