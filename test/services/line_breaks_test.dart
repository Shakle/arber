import 'dart:convert';
import 'dart:io';

import 'package:arber/services/arb_service.dart';
import 'package:arber/services/line_breaks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeLineBreaks', () {
    const cases = {
      'ATTENTION!\r\nData has not yet been posted':
          'ATTENTION!\nData has not yet been posted',
      'First line\rSecond line': 'First line\nSecond line',
      'Unix\nWindows\r\nClassic Mac\rEnd': 'Unix\nWindows\nClassic Mac\nEnd',
      'Blank line\r\n\r\nafter': 'Blank line\n\nafter',
      'CR before CRLF\r\r\n': 'CR before CRLF\n\n',
      'Trailing\r\n': 'Trailing\n',
      'Already\nnormalized': 'Already\nnormalized',
      '': '',
    };

    for (final entry in cases.entries) {
      test(jsonEncode(entry.key), () {
        expect(normalizeLineBreaks(entry.key), entry.value);
      });
    }

    test('keeps typed escapes as they are', () {
      expect(normalizeLineBreaks(r'Typed\r\nescape'), r'Typed\r\nescape');
    });
  });

  group('decodeLineBreaks', () {
    const cases = {
      r'Typed\nescape': 'Typed\nescape',
      r'BASF SE\r\nCarl-Bosch-Strasse 38\r\n':
          'BASF SE\nCarl-Bosch-Strasse 38\n',
      'Typed\\r\\nescape\r\nand real CRLF': 'Typed\nescape\nand real CRLF',
      'Lone\rCR': 'Lone\nCR',
      r'Only a typed \r stays': r'Only a typed \r stays',
      r'Path: C:\temp\file': r'Path: C:\temp\file',
    };

    for (final entry in cases.entries) {
      test(jsonEncode(entry.key), () {
        expect(decodeLineBreaks(entry.key), entry.value);
      });
    }
  });

  group('XLSX saved by Excel for Mac', () {
    // Holds the line breaks of Alt+Enter as raw CRLF bytes in
    // xl/sharedStrings.xml, see test/fixtures/README.md.
    const workbook = 'test/fixtures/crlf_line_breaks.xlsx';

    test('fixture keeps raw carriage returns in its shared strings', () {
      // The parts are stored uncompressed, so the raw XML is in the file.
      final bytes = latin1.decode(File(workbook).readAsBytesSync());

      expect(bytes, contains('<t>ATTENTION!\r\nData has not yet been posted'));
      expect(bytes, contains('<t>First line\rSecond line'));
    });

    test('generates ARB files without carriage returns', () {
      final arbs = ArbService().getArbs(workbook);

      expect(arbs.map((arb) => arb.locale), ['en', 'de']);
      for (final arb in arbs) {
        final json = arb.toJson();
        expect(json, isNot(contains('\r')));
        expect(json, isNot(contains(r'\r')));
        for (final translation in arb.translations) {
          expect(translation.translation, isNot(contains('\r')));
          expect(translation.description, isNot(contains('\r')));
        }
      }

      final en = jsonDecode(arbs.first.toJson()) as Map<String, dynamic>;
      expect(en['unsavedData'], 'ATTENTION!\nData has not yet been posted');
      expect(en['@unsavedData'], {
        'description': 'Dialog title\nShown before leaving',
      });
      expect(en['classicMac'], 'First line\nSecond line');
      expect(en['mixed'], 'Typed\nescape\nand typed\nescape\nend');
      expect(en['trailing'], 'Address line\n');
      expect(
        en['plural'],
        '{count, plural, one{{count} pallet\nleft} '
        'other{{count} pallets\nleft}}',
      );
      expect(arbs.first.translations.last.placeholders, ['count']);
    });
  });
}
